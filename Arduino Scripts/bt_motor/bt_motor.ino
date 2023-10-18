#include <Stepper.h>
#include <SoftwareSerial.h>

SoftwareSerial bt(0,1);
const int stepsPerRev = 2048;
const int stepsPer90 = 512;
const long rpm = 640;
const long btBaud = 9600;
Stepper motor(32, 8, 10, 9, 11);
int pos = 0;
bool debugMode = false;
const int LED = 13;

void setup() {
  pinMode(LED, OUTPUT);
  bt.begin(btBaud);
  Serial.begin(btBaud);
  motor.setSpeed(rpm);
  step(stepsPer90);
  step(-stepsPer90);
}

void loop() {
  if (debugMode){
    digitalWrite(LED, HIGH);
    delay(500);
    digitalWrite(LED, LOW);
    delay(500);
  }

  if (bt.available()) {
    String btS = bt.readString();
    //Serial.print("Received:");
    //Serial.println(btS);
    if(btS.equals("debug.on")) debugMode = true;
    else if(btS.equals("debug.off")) debugMode = false;
    else if(btS.equals("status")) Serial.println(pos);
    else if(isInt(btS)){
      if(debugMode){
        step(btS.toInt());
      }else{
        int percent = btS.toInt();
        if(percent >= 0 && percent <=100){
          int steps = map(percent-pos, 0, 100, 0, stepsPer90);
          pos = percent;
          step(steps);
          Serial.println("Success");
        }
      }
    }
  }
}

void step(int steps){
  //Serial1.print("Stepping:");
  //Serial1.println(steps);
  digitalWrite(13, HIGH);
  motor.step(steps);
  digitalWrite(13, LOW);
}

bool isInt(String in){
  if(!(in.charAt(0) == '-' || isDigit(in.charAt(0)))) return false;
  for(int i = 1; i < in.length(); i++){
    if(!isDigit(in.charAt(i))) return false;
  }
  return true;
}