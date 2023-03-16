#include <Stepper.h>
#include <SoftwareSerial.h>

SoftwareSerial bt(0,1);
const int stepsPerRev = 2048;
const long rpm = 640;
const long baud = 9600;
Stepper motor(32, 8, 10, 9, 11);
int pos = 0;

void setup() {
  pinMode(13, OUTPUT);
  bt.begin(baud);
  Serial.begin(baud);
  motor.setSpeed(rpm);
  step(stepsPerRev);
  step(-stepsPerRev);
}

void loop() {
  if (bt.available()) {
    //int btR = bt.read();
    //Serial.println(String(btR));
    //motor.step(btR);

    String btS = bt.readString();
    Serial.print("Received:");
    Serial.println(btS);
    int percent = btS.toInt();
    if(percent >= 0 && percent <=100){
      int steps = map(percent-pos, 0, 100, 0, 512);
      pos = percent;
      step(steps);
    }
  }
}

void step(int steps){
  Serial.print("Stepping:");
  Serial.println(steps);
  digitalWrite(13, HIGH);
  motor.step(steps);
  digitalWrite(13, LOW);
}