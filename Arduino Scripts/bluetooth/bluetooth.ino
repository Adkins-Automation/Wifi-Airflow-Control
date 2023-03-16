#include <SoftwareSerial.h>
SoftwareSerial mySerial(2,3);
int ledpin=13;
void setup()
{
mySerial.begin(9600);
Serial.begin(9600);
pinMode(ledpin,OUTPUT);
}
void loop()
{
  int i;
  
  if (mySerial.available())
  {
    i=mySerial.read();
    Serial.println("DATA RECEIVED:");
    if(i=='1')
    {
      digitalWrite(ledpin,1);
      Serial.println("led on");
    }
    if(i=='0')
    {
      digitalWrite(ledpin,0);
      Serial.println("led off");
    }
  }
}