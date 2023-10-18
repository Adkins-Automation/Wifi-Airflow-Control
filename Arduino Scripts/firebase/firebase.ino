#include "Firebase_Arduino_WiFiNINA.h"
#include <Servo.h>

#define DATABASE_URL "iflow-fe711-default-rtdb.firebaseio.com"
#define DATABASE_SECRET "Y9Fjdu4CvnlpcBMtpTGx13hj4aQ5eFAwm4cQWhZn"
#define WIFI_SSID "Adkins"
#define WIFI_PASSWORD "chuck1229"

//Define Firebase data object
FirebaseData fbdo;

Servo myservo;
int position = 0; // Initial position
const String USER_ID = "ecnlzD6NLnbXqx47qcaeU2KgfDr2";
String macAddressInDecimal; // used as damper id
String positionPath; // firebase path to position value of this damper

void setup() {
  Serial.begin(115200);
  while (!Serial); // Wait until the serial connection is established
  delay(100);
  Serial.println();
  
  byte mac[6];
  WiFi.macAddress(mac);
  
  for (int i = 5; i >= 0; i--) {
    macAddressInDecimal += String(mac[i]);
  }

  Serial.println("Damper ID: " + macAddressInDecimal);

  positionPath = USER_ID + "/" + macAddressInDecimal + "/position";

  Serial.print("Connecting to Wi-Fi");
  int status = WL_IDLE_STATUS;
  while (status != WL_CONNECTED) {
    status = WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print(".");
    delay(100);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  //Provide the authentication data
  Firebase.begin(DATABASE_URL, DATABASE_SECRET, WIFI_SSID, WIFI_PASSWORD);
  Firebase.reconnectWiFi(true);

  myservo.attach(9);

  // Set initial servo position
  myservo.write(position);
  
  Firebase.setInt(fbdo, positionPath, position);
}

void loop() {
  // Check Firebase for servo position updates
  
  if (Firebase.getInt(fbdo, positionPath)) {
    int newPosition = fbdo.intData();
    if (newPosition != position) {
      myservo.write(newPosition);
      position = newPosition;
    }
  } else {
    // Handle error if needed
    Serial.println("Failed to retrieve position from Firebase: " + fbdo.errorReason());
  }

  delay(1000); // Delay to prevent rapid Firebase requests. Adjust as needed.
}
