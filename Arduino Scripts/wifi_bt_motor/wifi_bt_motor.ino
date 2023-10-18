#include <Stepper.h>
#include <SoftwareSerial.h>
#define TIMEOUT 5000 // mS
SoftwareSerial bt(2, 3);
const int stepsPerRev = 2048;
const int stepsPer90 = 512;
const long rpm = 640;
Stepper motor(32, 8, 10, 9, 11);
SoftwareSerial wifi(0, 1);
bool DEBUG = true;   //show more logs
int responseTime = 10; //communication timeout
int pos = 0;
bool debugMode = false;
const int LED = 13;
 

void setup() {
  bt.begin(9600);
  Serial.begin(9600);
  motor.setSpeed(rpm);

  pinMode(13,OUTPUT);  //set build in led as output
  // Open serial communications and wait for port to open esp8266:
  wifi.begin(9600);
  SendCommand("AT+RST", "Ready");
  delay(5000);
  SendCommand("AT+CWMODE=1","OK");
  SendCommand("AT+CIFSR", "OK");
  SendCommand("AT+CIPMUX=1","OK");
  SendCommand("AT+CIPSERVER=1,80","OK");
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
    if(btS.equals("debug:ON")) debugMode = true;
    else if(btS.equals("debug:OFF")) debugMode = false;
    else if(btS.equals("pos")) Serial.println(pos);
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

  if (wifi.available()) {
    String wifiS = wifi.readString();
    if(wifiS.equals("debug:ON")) debugMode = true;
    else if(wifiS.equals("debug:OFF")) debugMode = false;
    else if(wifiS.equals("pos")) Serial.println(pos);
    else if(isInt(wifiS)){
      if(debugMode){
        step(wifiS.toInt());
      }else{
        int percent = wifiS.toInt();
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

boolean SendCommand(String cmd, String ack){
  wifi.println(cmd); // Send "AT+" command to module
  if (!echoFind(ack)) // timed out waiting for ack string
    return true; // ack blank or ack found
}
 
boolean echoFind(String keyword){
 byte current_char = 0;
 byte keyword_length = keyword.length();
 long deadline = millis() + TIMEOUT;
 while(millis() < deadline){
  if (wifi.available()){
    char ch = wifi.read();
    Serial.write(ch);
    if (ch == keyword[current_char])
      if (++current_char == keyword_length){
       Serial.println();
       return true;
    }
   }
  }
 return false; // Timed out
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

/*
* Name: sendData
* Description: Function used to send string to tcp client using cipsend
* Params: 
* Returns: void
*/
void sendData(String str){
  String len="";
  len+=str.length();
  sendToWifi("AT+CIPSEND=0,"+len,responseTime,DEBUG);
  delay(100);
  sendToWifi(str,responseTime,DEBUG);
  delay(100);
  sendToWifi("AT+CIPCLOSE=5",responseTime,DEBUG);
}


/*
* Name: find
* Description: Function used to match two string
* Params: 
* Returns: true if match else false
*/
boolean find(String string, String value){
  if(string.indexOf(value)>=0)
    return true;
  return false;
}


/*
* Name: readSerialMessage
* Description: Function used to read data from Arduino Serial.
* Params: 
* Returns: The response from the Arduino (if there is a reponse)
*/
String  readSerialMessage(){
  char value[100]; 
  int index_count =0;
  while(Serial.available()>0){
    value[index_count]=Serial.read();
    index_count++;
    value[index_count] = '\0'; // Null terminate the string
  }
  String str(value);
  str.trim();
  return str;
}



/*
* Name: readWifiSerialMessage
* Description: Function used to read data from ESP8266 Serial.
* Params: 
* Returns: The response from the esp8266 (if there is a reponse)
*/
String  readWifiSerialMessage(){
  char value[100]; 
  int index_count =0;
  while(wifi.available()>0){
    value[index_count]=wifi.read();
    index_count++;
    value[index_count] = '\0'; // Null terminate the string
  }
  String str(value);
  str.trim();
  return str;
}



/*
* Name: sendToWifi
* Description: Function used to send data to ESP8266.
* Params: command - the data/command to send; timeout - the time to wait for a response; debug - print to Serial window?(true = yes, false = no)
* Returns: The response from the esp8266 (if there is a reponse)
*/
String sendToWifi(String command, const int timeout, boolean debug){
  String response = "";
  wifi.println(command); // send the read character to the esp8266
  long int time = millis();
  while( (time+timeout) > millis())
  {
    while(wifi.available())
    {
    // The esp has data so display its output to the serial window 
    char c = wifi.read(); // read the next character.
    response+=c;
    }  
  }
  if(debug)
  {
    Serial.println(response);
  }
  return response;
}

/*
* Name: sendToWifi
* Description: Function used to send data to ESP8266.
* Params: command - the data/command to send; timeout - the time to wait for a response; debug - print to Serial window?(true = yes, false = no)
* Returns: The response from the esp8266 (if there is a reponse)
*/
String sendToUno(String command, const int timeout, boolean debug){
  String response = "";
  Serial.println(command); // send the read character to the esp8266
  long int time = millis();
  while( (time+timeout) > millis())
  {
    while(Serial.available())
    {
      // The esp has data so display its output to the serial window 
      char c = Serial.read(); // read the next character.
      response+=c;
    }  
  }
  if(debug)
  {
    Serial.println(response);
  }
  return response;
}