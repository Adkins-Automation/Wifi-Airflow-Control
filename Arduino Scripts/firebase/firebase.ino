#include "Firebase_Arduino_WiFiNINA.h"
#include <Servo.h>
#include <ArduinoBLE.h>
#include <FlashStorage.h>
#include <utility/wifi_drv.h>

#define DATABASE_URL "iflow-fe711-default-rtdb.firebaseio.com"
#define DATABASE_SECRET "Y9Fjdu4CvnlpcBMtpTGx13hj4aQ5eFAwm4cQWhZn"

//Define Firebase data object
FirebaseData fbdo;

Servo myservo;
int position = 0; // Initial position
String mac; // used as damper id
String positionPath; // firebase path to position value of this damper

// Define the maximum lengths for the strings (including null terminators)
#define MAX_SSID_LENGTH 32
#define MAX_PASSWORD_LENGTH 64
#define MAX_USERID_LENGTH 64

// Define a struct to store SSID, password, and user ID
struct WifiCredentials {
  char ssid[MAX_SSID_LENGTH];
  char password[MAX_PASSWORD_LENGTH];
  char userId[MAX_USERID_LENGTH];
  bool initialized;  // Flag to check if data has been written before
};

WifiCredentials newCredentials;

// Create an instance of the struct for flash storage
FlashStorage(flashStorage, WifiCredentials);

// Global variables for BLE
BLEService wifiService("1800");  // Use a standard GATT service number
BLEStringCharacteristic xCharacteristic("2AC4", BLERead | BLEWrite, 126);

// Global variables for WiFi and Firebase
String ssid, password, userId;

void setup() {
  Serial.begin(9600);
  while (!Serial);  // Wait for serial connection
  Serial.println();
  Serial.println("setup started");

  // Attempt to retrieve SSID, password, and user ID from flash storage
  WifiCredentials storedCredentials = flashStorage.read();

  if (!storedCredentials.initialized) {
    Serial.println("damper not initialized");
    // Initialize BLE and wait for central device to provide values
    setupBLE();
    
    int ledState = LOW;
    Serial.println("polling BLE");
    while (!xCharacteristic.written()) {
      Serial.print(".");
      BLE.poll();
      delay(1000);
      // if the LED is off, turn it on, and vice-versa
      if (ledState == LOW) {
        ledState = HIGH;
      } else {
        ledState = LOW;
      }
      digitalWrite(LED_BUILTIN, ledState);
    }
    Serial.println();
    
    String* values = split(xCharacteristic.value(), ';');
    
    ssid = values[0];
    password = values[1];
    userId = values[2];

    Serial.println("ssid: " + ssid);
    Serial.println("password: " + password);
    Serial.println("userId: " + userId);
    
    ssid.toCharArray(newCredentials.ssid, MAX_SSID_LENGTH);
    password.toCharArray(newCredentials.password, MAX_PASSWORD_LENGTH);
    userId.toCharArray(newCredentials.userId, MAX_USERID_LENGTH);
    newCredentials.initialized = true;
    
    BLE.end();  // Stop BLE services
  } else {
    BLE.begin();
    mac = strip(BLE.address(), ':');
    BLE.end();

    Serial.println("damper initialized");
    ssid = String(storedCredentials.ssid);
    password = String(storedCredentials.password);
    userId = String(storedCredentials.userId);

    Serial.println("ssid: " + ssid);
    Serial.println("password: " + password);
    Serial.println("userId: " + userId);
  }

  // Connect to WiFi
  connectToWiFi();

  // Connect and authenticate to Firebase
  connectToFirebase();

  myservo.attach(9);

  // Set initial servo position
  myservo.write(position);
  
  positionPath = userId + "/" + mac + "/position";

  Firebase.setInt(fbdo, positionPath, position);

  // Store received values in flash storage
  if (!storedCredentials.initialized) {
    flashStorage.write(newCredentials);
  }
}

void loop() {
  // Check Firebase for servo position updates
  Serial.println("Getting position...");
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

void setupBLE() {
  if (!BLE.begin()) {
    Serial.println("Starting BLE failed!");
    while (1);
  }
  
  mac = strip(BLE.address(), ':');
  Serial.println("BLE address: " + mac);
  BLE.setDeviceName("iFlow damper");
  BLE.setLocalName("iFlow damper");
  BLE.setConnectable(true);

  if(!BLE.setAdvertisedService(wifiService)){
    Serial.println("Failed to set advertised service");
    while (1);
  }

  wifiService.addCharacteristic(xCharacteristic);

  BLE.addService(wifiService);
  
  xCharacteristic.writeValue("");
  
  int result = BLE.advertise();
  Serial.println("BLE advertise result: " + String(result));
}

void connectToWiFi() {
  Serial.print("Connecting to Wi-Fi...");
  int status = WL_IDLE_STATUS;
  while (status != WL_CONNECTED) {
    status = WiFi.begin(ssid.c_str(), password.c_str());
    delay(1000);
  }
  Serial.println("Connected!");
}

void connectToFirebase() {
  Serial.print("Connecting to firebase");
  Firebase.begin(DATABASE_URL, DATABASE_SECRET, ssid.c_str(), password.c_str());
  Firebase.reconnectWiFi(true);
}

String* split(String data, char separator) {
  static String result[3];
  int startIndex = 0;

  for (int i = 0; i < 3; i++) {
    // Find the separator
    int separatorIndex = data.indexOf(separator, startIndex);

    // If separator is found, extract substring; otherwise, take the rest of the string
    if (separatorIndex != -1) {
      result[i] = data.substring(startIndex, separatorIndex);
      startIndex = separatorIndex + 1;
    } else {
      result[i] = data.substring(startIndex);
      break;
    }
  }

  return result;
}

String strip(const String &input, char charToRemove) {
    String result = "";
    for (unsigned int i = 0; i < input.length(); i++) {
        if (input[i] != charToRemove) {
            result += input[i];
        }
    }
    return result;
}