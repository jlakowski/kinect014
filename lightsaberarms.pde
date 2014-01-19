import oscP5.*;
import netP5.*;

import SimpleOpenNI.*;
 
SimpleOpenNI  context;
 
OscP5 oscP5;
NetAddress myBroadcastLocation;

PVector rhandold, lhandold;
void setup()
{
  // instantiate a new context
  context = new SimpleOpenNI(this);
 
  // enable depthMap generation 
  context.enableDepth();
 
  // enable skeleton generation for all joints
  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  //Enable Mirroring
  context.setMirror(true);
  
  background(200,0,0);
  stroke(0,0,255);
  strokeWeight(3);
  smooth();
 
  // create a window the size of the depth information
  size(context.depthWidth(), context.depthHeight()); 
  
  oscP5 = new OscP5(this,12000);
  myBroadcastLocation = new NetAddress("127.0.0.1",32000);
  
  rhandold = new PVector(0,0);
  lhandold = new PVector(0,0);
}
 
void draw()
{
  // update the camera
  context.update();
 
  // draw depth image
  image(context.depthImage(),0,0); 
 
  // for all users from 1 to 10
  int i;
  for (i=1; i<=10; i++)
  {
    // check if the skeleton is being tracked
    if(context.isTrackingSkeleton(i))
    {
      drawSkeleton(i);  // draw the skeleton
    }
  }
}
 
// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{  
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
  
  //Draw a green circle on your head
  PVector realHead = new PVector();
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD,realHead);
  PVector projHead =new PVector();
  context.convertRealWorldToProjective(realHead,projHead);
  fill(0,255,0);
  ellipse(projHead.x,projHead.y,60,60);
  
  //Draw a Red Square in the corner
  fill(255,0,0);
  rect(0,0,70,70);
  //Find Where the left hand is
  PVector realLHand = new PVector();
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND,realLHand);
  PVector projLHand =new PVector();
  context.convertRealWorldToProjective(realLHand,projLHand);
  OscMessage message = new OscMessage("/lhand");
  
  if(projLHand.x < 70 && projLHand.y < 70){
     message.add(1);
  }
  message.add(0);
  oscP5.send(message, myBroadcastLocation);
  
  //Magenta Square
  fill(255,0,255);
  rect(context.depthWidth()-70,0,context.depthWidth(),70);
  //Find Where the right hand is
  PVector realRHand = new PVector();
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND,realRHand);
  PVector projRHand =new PVector();
  context.convertRealWorldToProjective(realRHand,projRHand);
  OscMessage mess = new OscMessage("/rhand");
  
  if(projRHand.x > (context.depthWidth()-70) && projRHand.y < 70){
     mess.add(1);
  }
  mess.add(0);
  oscP5.send(mess, myBroadcastLocation);
  
  // hand velocity Velocity
  // use vectors!
  //Lightsaber arms!
  PVector drh = new PVector();
  drh = drh.sub(realRHand, rhandold);
  PVector dlh = new PVector();
  dlh = dlh.sub(realLHand, lhandold);
  
  float speedr, speedl;
  speedr = drh.mag();
  speedl = dlh.mag();
  
  float speedtot = speedr + speedl;
  println(speedtot);
  
  OscMessage mess1 = new OscMessage("/handspeed");
  mess1.add(speedtot);
  oscP5.send(mess1, myBroadcastLocation);
  
  rhandold = realRHand;
  lhandold = realLHand;
  
} //DrawSKeleton Method
 
// Event-based Methods
 
// when a person ('user') enters the field of view
void onNewUser(int userId)
{
  println("New User Detected - userId: " + userId);
 
 // start pose detection
  context.startPoseDetection("Psi",userId);
}
 
// when a person ('user') leaves the field of view 
void onLostUser(int userId)
{
  println("User Lost - userId: " + userId);
}
 
// when a user begins a pose
void onStartPose(String pose,int userId)
{
  println("Start of Pose Detected  - userId: " + userId + ", pose: " + pose);
 
  // stop pose detection
  context.stopPoseDetection(userId); 
 
  // start attempting to calibrate the skeleton
  context.requestCalibrationSkeleton(userId, true); 
}
 
// when calibration begins
void onStartCalibration(int userId)
{
  println("Beginning Calibration - userId: " + userId);
}
 
// when calibaration ends - successfully or unsucessfully 
void onEndCalibration(int userId, boolean successfull)
{
  println("Calibration of userId: " + userId + ", successfull: " + successfull);
 
  if (successfull) 
  { 
    println("  User calibrated !!!");
 
    // begin skeleton tracking
    context.startTrackingSkeleton(userId); 
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
 
    // Start pose detection
    context.startPoseDetection("Psi",userId);
  }
}
