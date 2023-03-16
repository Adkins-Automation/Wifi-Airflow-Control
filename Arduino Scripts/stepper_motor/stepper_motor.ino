
void setup()
{
  //set pins 8,9,10,11 as output pins
  for(int i=8;i<12;i++)
  {
    pinMode(i,OUTPUT);
  }

  //Turn Motor 360 degrees
  //Step Angle 5.625; Reduction Ratio 1:64
  //5.625X2X4/64=0.703125
  //360/0.7031=512
  int a = 512;
  while(a--)
  {
   for(int i=8;i<12;i++)
   {
    digitalWrite(i,1);
    delay(10);
    digitalWrite(i,0);
   }
  }
}

void loop()
{
  
}