#include "Firebase_Arduino_WiFiNINA.h"
#include <Servo.h>
#include <ArduinoBLE.h>
#include <FlashStorage.h>

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

// Create an instance of the struct for flash storage
FlashStorage(flashStorage, WifiCredentials);

// Global variables for BLE
BLEService wifiService("1800");  // Use a standard GATT service number
BLEStringCharacteristic ssidCharacteristic("2A00", BLERead | BLEWrite, MAX_SSID_LENGTH);  // Standard GATT characteristic for Device Name, repurposed for SSID
BLEStringCharacteristic passwordCharacteristic("2A01", BLERead | BLEWrite, MAX_PASSWORD_LENGTH);  // Another standard GATT characteristic, repurposed for password
BLEStringCharacteristic userIdCharacteristic("2A04", BLERead | BLEWrite, MAX_USERID_LENGTH);  // Another standard GATT characteristic, repurposed for user ID

// Global variables for WiFi and Firebase
String ssid, password, userId;

void setup() {
  Serial.begin(9600);
  while (!Serial);  // Wait for serial connection
  Serial.println();
  Serial.println("setup started");

  byte mac[6];
  WiFi.macAddress(mac);
  
  for (int i = 5; i >= 0; i--) {
    macAddressInDecimal += String(mac[i]);
  }

  Serial.println("Damper ID: " + macAddressInDecimal);

  // 1. Attempt to retrieve SSID, password, and user ID from flash storage
  WifiCredentials storedCredentials = flashStorage.read();

  if (!storedCredentials.initialized) {
    Serial.println("damper not initialized");
    // 2. Initialize BLE and wait for central device to provide values
    setupBLE();
    
    Serial.println("polling BLE");
    while (!ssidCharacteristic.written() || !passwordCharacteristic.written() || !userIdCharacteristic.written()) {
      Serial.print(".");
      BLE.poll();
      delay(1000);
    }
    Serial.println();
    
    ssid = ssidCharacteristic.value();
    password = passwordCharacteristic.value();
    userId = userIdCharacteristic.value();

    Serial.println("ssid: " + ssid);
    Serial.println("password: " + password);
    Serial.println("userId: " + userId);

    // 3. Store received values in flash storage
    WifiCredentials newCredentials;
    ssid.toCharArray(newCredentials.ssid, MAX_SSID_LENGTH);
    password.toCharArray(newCredentials.password, MAX_PASSWORD_LENGTH);
    userId.toCharArray(newCredentials.userId, MAX_USERID_LENGTH);
    newCredentials.initialized = true;
    flashStorage.write(newCredentials);
    
    BLE.end();  // Stop BLE services
  } else {
    Serial.println("damper initialized");
    ssid = String(storedCredentials.ssid);
    password = String(storedCredentials.password);
    userId = String(storedCredentials.userId);

    Serial.println("ssid: " + ssid);
    Serial.println("password: " + password);
    Serial.println("userId: " + userId);
  }

  // 4. Connect to WiFi
  connectToWiFi();

  // 5. Connect and authenticate to Firebase
  connectToFirebase();

  myservo.attach(9);

  // Set initial servo position
  myservo.write(position);
  
  positionPath = userId + "/" + macAddressInDecimal + "/position";

  Firebase.setInt(fbdo, positionPath, position);
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
  
  BLE.setDeviceName(macAddressInDecimal.c_str());

  if(!BLE.setAdvertisedService(wifiService)){
    Serial.println("Failed to set advertised service");
    while (1);
  }
  
  wifiService.addCharacteristic(ssidCharacteristic);
  wifiService.addCharacteristic(passwordCharacteristic);
  wifiService.addCharacteristic(userIdCharacteristic);
  
  BLE.addService(wifiService);
  
  ssidCharacteristic.setValue("");
  passwordCharacteristic.setValue("");
  userIdCharacteristic.setValue("");
  
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
