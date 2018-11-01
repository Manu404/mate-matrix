// example sketch based on Dan Schiffman's Metaballs algorithm and @scanlime OPC Client library
// import ddf.minim.*;
// import ddf.minim.analysis.*;
import processing.sound.*;
import oscP5.*;
import netP5.*;
import processing.serial.*;

// Open Pixel Control
OPC opc;

// Audio objects
AudioIn input;
FFT     fft;
Amplitude amplitude;
int bands = 64;

// DMX device
Serial enttec;
DMXMode dmx;

// OSC 

OscP5 oscP5;
NetAddress broadcastLocation;

static final int CRATES = 30;

MateMatrix mm;
JSONObject config;

AnimationRunner animRunner;
boolean running = true;
float globalHue = 0;
float globalSaturation = 255;
float globalBrightness = 255;


// byte[] lastDMX = new byte[519];
// byte[] colors = new byte[CRATES];

void settings(){
  config = loadJSONObject("matrix_config.json");
  int cols = config.getInt("cols");
  int rows = config.getInt("rows");
  int crateW = config.getInt("crateW");
  int crateH = config.getInt("crateH");
  int spacing = config.getInt("spacing");
  int w = cols*crateW*spacing;
  int h  = rows *crateH*spacing;
  size(w,h,P3D);
}

void setup()
{
  // size(480, 500, P3D);
  opc = new OPC(this, "127.0.0.1", 7890);
  // opc.setPixelCount(6*6*20);
  // pixelDensity(2);
  println(Serial.list());
  colorMode(HSB);
    background(0);
  
  // Set up your LED mapping here
  mm = new MateMatrix(this, opc, config);
  //mm = new MateMatrix(this, opc, config);
  mm.init(false);
  //mm.initMultiblock(config);
  //mm.init();


  

  dmx = new DMXMode(this, opc);
  String dmxSerialPort = config.getString("dmxSerialPort");
  try {
    enttec = new Serial(this, dmxSerialPort, 115000);
    enttec.bufferUntil(0xE7);
  }
  catch(RuntimeException e) {
    println("no dmx interface, forcing auto mode");
    dmx.setMode(1);
  }

  // audio analysis configuration
 
  input = new AudioIn(this);
  input.amp(0.3);
  input.start();
  try{ 
    fft = new FFT(this, bands);
    fft.input(input);
  
    amplitude = new Amplitude(this);
    amplitude.input(input);
  
  }catch(RuntimeException e){
    println("a problem occured during the initialisation of audio device");
    println(e.getMessage());
  }

   oscP5 = new OscP5(this, 10000);
  

  // animation runner
  animRunner = new AnimationRunner(this, amplitude, fft);
  
}

void draw() {
  
  //background(0);
   //fill(140, 200, 255);
   //rect(mouseX, mouseY, 100,100);
  
  if(! dmx.isActive()){
    //colorMode(RGB);
    //dmx.show();
    
    //opc.pixelLocations = null;
    background(0);
    noStroke();
    
   }else{
      
    colorMode(HSB);
    if(opc.pixelLocations == null){
      mm.init();
    }
   try{
     
    animRunner.choseAnimFromDMX(dmx.getAnimationSelector());
    if(dmx.getRandomAnim()){
      animRunner.selectAnimation();
    }
   }catch(NullPointerException e){
    println("error 1");
    println(e.getMessage());
   }catch(RuntimeException e){
     println("error 2");
    println(e.getMessage());
   }
   
   colorMode(HSB);
   animRunner.run();
  }
    /*
   colorMode(HSB);
   noStroke();
   if(running){
     animRunner.run();
   }else{
     if(frameCount % 6 < 3){
       if(globalHue<10){
        background(0);
       }else{
         background(globalHue, globalSaturation, globalBrightness);
       }
       
     }else{
       background(0);
     }
   }
   */
  
}

/*
  GBE: XXX findout how to let the DMXMode class handle the event
 */
void serialEvent(Serial s) {

  try {
    dmx.manageMessage(enttec);
  }
  catch(RuntimeException e) {
    println("error manageMessage");
    println(e.getMessage() );
    println(e.getStackTrace());
  }
}


void exit() {
  print("exit");
  background(0);

  super.exit();
}

void keyPressed() {
  if (key == ' ') {
    animRunner.selectAnimation();
  }
  if (key>='0' && key <= '9') {
    animRunner.selectAnimation(key-48);
  }
  if (key == 'a' || key == 'A') {
    animRunner.toggleAutoMode();
  }

}

void oscEvent(OscMessage theOscMessage){
  if(theOscMessage.addrPattern().equals("/matrix/manual")){
    float val = theOscMessage.get(0).floatValue();
    animRunner.setAutoMode(val == 0.0);
  }

  if(theOscMessage.addrPattern().equals("/matrix/minVolume")){
    animRunner.setLowVolumeThreshold(theOscMessage.get(0).floatValue());
  }

  if(theOscMessage.addrPattern().equals("matrix/maxVolume")){
    animRunner.setHighVolumeThreshold(theOscMessage.get(0).floatValue());
  }

  if(theOscMessage.addrPattern().equals("/matrix/anim")){
    animRunner.selectAnimation(int(theOscMessage.get(0).floatValue()));
  }

  if(theOscMessage.addrPattern().equals("/matrix/run")){
    running = theOscMessage.get(0).floatValue() == 1.0;
    println("running : "+(running?"true":"false") );

  }
  if(theOscMessage.addrPattern().equals("/matrix/hue")){
    globalHue = theOscMessage.get(0).floatValue();

  }
  if(theOscMessage.addrPattern().equals("/matrix/saturation")){
    globalSaturation = theOscMessage.get(0).floatValue();
    
  }
  if(theOscMessage.addrPattern().equals("/matrix/brighntess")){
    globalBrightness = theOscMessage.get(0).floatValue();
    
  }

  if(theOscMessage.addrPattern().equals("/matrix/fftScaleFactor")){
    fft.setScaleFactor(theOscMessage.get(0).floatValue());
  }



}
