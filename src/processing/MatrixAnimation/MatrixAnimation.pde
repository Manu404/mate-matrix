// example sketch based on Dan Schiffman's Metaballs algorithm and @scanlime OPC Client library
// import ddf.minim.*;
// import ddf.minim.analysis.*;
import processing.sound.*;

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


static final int CRATES = 30;

boolean isInTestMode = false;

MateMatrix mm;
JSONObject config;

AnimationRunner animRunner;
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
  //opc = new OPC(this, "192.168.42.124", 7890);
  opc = new OPC(this, "192.168.42.220", 7890);
  // opc.setPixelCount(6*6*20);
  // pixelDensity(2);
  println(Serial.list());
  colorMode(HSB);


  // Set up your LED mapping here
  mm = new MateMatrix(this, opc, config);
  mm.init();


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
  // input.amp(1.0);
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


  // animation runner
  animRunner = new AnimationRunner(amplitude, fft);
}

void draw() {
  if (isInTestMode) {
    background(0);
    noStroke();
    fill(140, 200, 255);
    rect(mouseX - 50, mouseY - 50, 100,100);
    return;
  }

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


   animRunner.run();
   }

   //*/
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
  if (key == 't' || key == 'T') {
    isInTestMode = !isInTestMode;
  }
}
