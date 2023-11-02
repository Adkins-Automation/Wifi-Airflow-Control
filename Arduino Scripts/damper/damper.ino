#include "Firebase_Arduino_WiFiNINA.h"
#include <Servo.h>
#include <ArduinoBLE.h>
#include <FlashStorage.h>
#include <ArduinoHttpClient.h>
#include <ArduinoJson.h>

#define DATABASE_URL "iflow-fe711-default-rtdb.firebaseio.com"
#define DATABASE_SECRET "Y9Fjdu4CvnlpcBMtpTGx13hj4aQ5eFAwm4cQWhZn"

//Define Firebase data object
FirebaseData fbdo;

Servo myservo;
int position = 0; // Initial position
bool pauseSchedule = false;

String mac; // used as damper id
String devicePath;
String labelPath;
String positionPath; // firebase path to position value of this damper
String lastHeartbeatPath;
String schedulePath;
String pauseSchedulePath;
String lastChangePath;

unsigned long initialUnixTime = 0;     // Unix timestamp from server
unsigned long initialMillis = 0;       // millis() value when unixtime was retrieved
unsigned long lastScheduleCheck = 0;

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

struct LastChange {
  int time;
  int position;
  bool scheduled;
};

LastChange lastChange;

struct Schedule {
    int time;
    int days;
    int position;
};

#define MAX_SCHEDULES 10  // Assuming a maximum of 10 schedule entries. Adjust as needed.

WifiCredentials newCredentials;

// Create an instance of the struct for flash storage
FlashStorage(flashStorage, WifiCredentials);

// Global variables for BLE
BLEService wifiService("1800");  // Use a standard GATT service number
BLEStringCharacteristic xCharacteristic("2AC4", BLERead | BLEWrite, 126);

WiFiClient wifi;
HttpClient client = HttpClient(wifi, "worldtimeapi.org", 80);

// Global variables for WiFi and Firebase
String ssid, password, userId;

void setup() {
  Serial.begin(9600);
  delay(5000);
  //while (!Serial);  // Wait for serial connection
  Serial.println();
  Serial.println("setup started");

  // Attempt to retrieve SSID, password, and user ID from flash storage
  WifiCredentials storedCredentials = flashStorage.read();

  // for testing purposes only //
  // userId = "ecnlzD6NLnbXqx47qcaeU2KgfDr2";
  // ssid = "Zenfone 9_3070";
  // password = "mme9h4xpeq9mtdw";
  // ssid = "Adkins";
  // password = "chuck1229";
  // ssid.toCharArray(storedCredentials.ssid, MAX_SSID_LENGTH);
  // password.toCharArray(storedCredentials.password, MAX_PASSWORD_LENGTH);
  // userId.toCharArray(storedCredentials.userId, MAX_USERID_LENGTH);
  // storedCredentials.initialized = true;
  // ... //

  if (!storedCredentials.initialized) {
    Serial.println("damper not initialized");
    initialize();
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

  connectToWiFi();
  connectToFirebase();

  myservo.attach(9);
  
  devicePath = userId + "/" + mac;
  positionPath = devicePath + "/position";
  lastHeartbeatPath = devicePath + "/lastHeartbeat";
  labelPath = devicePath + "/label";
  schedulePath = devicePath + "/schedule";
  pauseSchedulePath = devicePath + "/pauseSchedule";
  lastChangePath = devicePath + "/lastChange";

  // Store received values in flash storage
  if (!storedCredentials.initialized) {
    getCurrentMillis();
    uploadDamper();
    Serial.println("Writing to flash storage");
    flashStorage.write(newCredentials);
  }else if (Firebase.getInt(fbdo, positionPath)) {
    position = fbdo.intData();
    Serial.println("retreived position: " + String(position));
    myservo.write(position);
    getCurrentMillis();
    sendHeartbeat();
  }
}

void loop() {
  // Check Firebase for servo position updates
  Serial.print("Getting position... ");
  if (Firebase.getInt(fbdo, positionPath)) {
    Serial.println(fbdo.intData());
    int newPosition = fbdo.intData();
    if (newPosition != position) {
      myservo.write(newPosition);
      position = newPosition;
      setLastChange(false);
    }
    delay(2000); // Delay to prevent rapid Firebase requests. Adjust as needed.
    sendHeartbeat();

    unsigned long unixtime = getUnixtime();
    if(unixtime - lastScheduleCheck > 60){
      lastScheduleCheck = unixtime;
      applySchedule();
    }
  } else {
    // Handle error if needed
    Serial.println("Failed to retrieve position from Firebase: " + fbdo.errorReason());
    if(fbdo.errorReason() == "path not exist"){
      Serial.println("resetting...");
      position = 0;
      myservo.write(position);
      resetWifiModule();
      eraseWifiCredentials();
      initialize();
      connectToWiFi();
      connectToFirebase();
      getCurrentMillis();
      uploadDamper();
      Serial.println("Overwriting flash storage");
      flashStorage.write(newCredentials);
    }
  }

  delay(2000); // Delay to prevent rapid Firebase requests. Adjust as needed.
}

void initialize(){
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
    digitalWrite(LED_BUILTIN, LOW);
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
  Serial.println("Connecting to Wi-Fi...");
  Serial.println("ssid: " + ssid);
  Serial.println("password: " + password);
  Serial.println("Wi-Fi Status: " + String(WiFi.status()));

  int status = WL_IDLE_STATUS;
  while (status != WL_CONNECTED) {
    status = WiFi.begin(ssid.c_str(), password.c_str());
    Serial.println("Wi-Fi status: " + String(status));
    delay(1000);
  }
  Serial.println("Connected!");
}

void connectToFirebase() {
  Serial.println("Connecting to firebase");
  Firebase.begin(DATABASE_URL, DATABASE_SECRET, ssid.c_str(), password.c_str());
  Firebase.reconnectWiFi(true);
}

Schedule* getSchedule() {
  static Schedule fetchedSchedules[MAX_SCHEDULES];
  for (int i = 0; i < MAX_SCHEDULES; i++) {
    fetchedSchedules[i].time = -1;
    fetchedSchedules[i].days = 0;
    fetchedSchedules[i].position = -1;
  }

  if (Firebase.getJSON(fbdo, schedulePath)) {
    String scheduleJson = fbdo.jsonData();
    DynamicJsonDocument doc(2048);
    deserializeJson(doc, scheduleJson);

    int index = 0;
    for (JsonPair kv : doc.as<JsonObject>()) {
      Schedule currentSchedule;
      String key = String(kv.key().c_str());
      JsonObject scheduleJson = kv.value().as<JsonObject>();

      currentSchedule.time = scheduleJson["time"].as<int>();
      currentSchedule.days = scheduleJson["days"].as<int>();
      currentSchedule.position = scheduleJson["position"].as<int>();

      fetchedSchedules[index] = currentSchedule;
      index++;
      if (index >= MAX_SCHEDULES) {
        break;  // We've hit the maximum number of schedules.
      }
    }
  } else {
    Serial.println("Failed to retrieve schedule from Firebase: " + fbdo.errorReason());
  }

  return fetchedSchedules;  // Return the array even if empty
}

void applySchedule() {
  Serial.println("Getting schedule...");

  if(Firebase.getBool(fbdo, pauseSchedulePath)){
    pauseSchedule = fbdo.boolData();
    if(pauseSchedule){
      Serial.println("Schedule paused");
      return;
    }
  }

  Schedule* fetchedSchedules = getSchedule();

  // Print fetched schedules for debugging purposes
  for (int i = 0; i < MAX_SCHEDULES; i++) {
    if(fetchedSchedules[i].time < 0) continue;
    Serial.print("Time: ");
    Serial.print(fetchedSchedules[i].time);
    Serial.print(", Days: ");
    Serial.print(fetchedSchedules[i].days);
    Serial.print(", Position: ");
    Serial.println(fetchedSchedules[i].position);
  }

  // Convert current Unix time to day of the week and HHMM format.
  unsigned long unixtime = getUnixtime() - (4 * 3600);  // subtract 4 hours; TODO: get time zone
  int currentDayOfWeek = ((unixtime / 86400 + 4) % 7) - 1; // 1970-01-01 was a Thursday (day 4) - 1 for index.
  if(currentDayOfWeek == -1){
    currentDayOfWeek = 6; // Convert Sunday from -1 to 6
  }
  int currentTime = toTimeOfDay(unixtime);

  Serial.println("Current day of week: " + String(currentDayOfWeek));
  Serial.println("Current time: " + String(currentTime));

  // Get the bitmask for the current day of the week
  int currentDayBitmask = 1 << currentDayOfWeek;

  // Find the latest scheduled time that is before or equal to the current time.
  int latestScheduledTime = -2;
  int scheduledPosition = -1;

  for (int i = 0; i < MAX_SCHEDULES; i++) {
    // Serial.println("Checking schedule at index: " + String(i));
    // Serial.println("Schedule time: " + String(fetchedSchedules[i].time));
    // Serial.println("Current time: " + String(currentTime));
    // Serial.println("Latest scheduled time: " + String(latestScheduledTime));
    // Serial.println("Schedule days bitmask: " + String(fetchedSchedules[i].days, BIN));
    // Serial.println("Current day bitmask: " + String(currentDayBitmask, BIN));
    // Serial.println("Bitwise AND result: " + String(fetchedSchedules[i].days & currentDayBitmask, BIN));

    if (fetchedSchedules[i].time <= currentTime && fetchedSchedules[i].time > latestScheduledTime && (fetchedSchedules[i].days & currentDayBitmask)) {
      latestScheduledTime = fetchedSchedules[i].time;
      scheduledPosition = fetchedSchedules[i].position;
    }
  }

  Serial.println("Latest scheduled time: " + String(latestScheduledTime));
  Serial.println("Scheduled position: " + String(scheduledPosition));

  unsigned long lastChangeTime = lastChange.time - (4 * 3600);  // subtract 4 hours; TODO: get time zone
  bool isLastChangeToday = isSameDay(lastChangeTime, unixtime);
  int lastChangeTimeOfDay = toTimeOfDay(lastChangeTime);

  Serial.println("Last change time: " + String(lastChange.time) + ", position: " + String(lastChange.position) + ", scheduled: " + String(lastChange.scheduled));
  Serial.println("Last change was today: " + String(isLastChangeToday));
  Serial.println("Last change time of day: " + String(lastChangeTimeOfDay));

  if (latestScheduledTime <= lastChangeTimeOfDay && isLastChangeToday) {
    Serial.println("A change has already occured since the last schedule time");
    return;
  }

  if (scheduledPosition != -1 && scheduledPosition != position) {
    myservo.write(scheduledPosition);
    position = scheduledPosition;
    setPosition();
    setLastChange(true);
  }
}

void setPosition() {
  Serial.println("Uploading position: " + String(position));
  while(!Firebase.setInt(fbdo, positionPath, position));
}

void setLabel() {
  String label = "Damper " + mac;
  Serial.println("Uploading label: " + label);
  while(!Firebase.setString(fbdo, labelPath, label));
}

void setPauseSchedule(){
  Serial.println("Uploading pauseSchedule: " + String(pauseSchedule));
  while(!Firebase.setInt(fbdo, pauseSchedulePath, pauseSchedule));
}

void sendHeartbeat() {
  unsigned long unixtime = getUnixtime();
  Serial.print("lastHeartbeat: ");
  Serial.println(unixtime);

  while(!Firebase.setInt(fbdo, lastHeartbeatPath, unixtime));
}

void setLastChange(bool scheduled) {
  lastChange.time = getUnixtime();
  lastChange.position = position;
  lastChange.scheduled = scheduled;

  DynamicJsonDocument doc(1024);
  doc["time"] = lastChange.time;
  doc["position"] = lastChange.position;
  doc["scheduled"] = lastChange.scheduled;

  String data;
  serializeJson(doc, data);

  Serial.println("Uploading lastChange: " + data);

  while(!Firebase.setJSON(fbdo, lastChangePath, data));
}

void uploadDamper() {
    // Create a JSON object for the data
    DynamicJsonDocument doc(1024);
    doc["position"] = position;
    doc["label"] = String("Damper ") + mac;
    doc["pauseSchedule"] = pauseSchedule;
    doc["lastHeartbeat"] = getUnixtime();

    // Convert the JSON object to a string
    String data;
    serializeJson(doc, data);
  
    Serial.println("Uploading combined data to Firebase: " + data);

    // Make a single call to Firebase
    while(!Firebase.setJSON(fbdo, devicePath, data));
}

void getCurrentMillis(){
  Serial.println("Getting Unix timestamp...");

  int httpResponseCode = client.get("/api/ip");

  String response = client.responseBody();
  Serial.println(response);
  String unixtime = extractUnixTime(response);
  Serial.println("Unixtime: " + unixtime);
  if(unixtime){
    initialUnixTime = unixtime.toInt();
    initialMillis = millis();
    Serial.print("initialMillis: ");
    Serial.println(initialMillis);
  }
}

String extractUnixTime(const String &response) {
  const String searchToken = "\"unixtime\":";
  int startIndex = response.indexOf(searchToken);
  
  if (startIndex == -1) {
    return "Not Found";
  }
  
  startIndex += searchToken.length();
  int endIndex = response.indexOf(",", startIndex);
  
  return response.substring(startIndex, endIndex);
}


void eraseWifiCredentials() {
  ssid = "";
  password = "";
  userId = "";

  memset(newCredentials.ssid, 0, sizeof(newCredentials.ssid));
  memset(newCredentials.password, 0, sizeof(newCredentials.password));
  memset(newCredentials.userId, 0, sizeof(newCredentials.userId));
  newCredentials.initialized = false;

  // Write the empty struct to flash storage
  flashStorage.write(newCredentials);
}

void resetWifiModule(){
  Serial.println("disconnecting Wi-Fi...");
  WiFi.disconnect();
  delay(5000);
  WiFi.end();
}

unsigned long getUnixtime(){
  return initialUnixTime + ((millis() - initialMillis) / 1000);
}

int toTimeOfDay(unsigned long unixtime){

  // Calculate the time of day
  int secondsInDay = unixtime % 86400;
  int hour = secondsInDay / 3600;
  int minute = (secondsInDay % 3600) / 60;

  // Convert to HHMM format
  int timeOfDayHHMM = hour * 100 + minute;

  return timeOfDayHHMM;
}

bool isSameDay(int unixtime1, int unixtime2) {
  const int secondsPerDay = 86400;

  // Calculate the number of days since the Unix epoch for each timestamp
  int day1 = unixtime1 / secondsPerDay;
  int day2 = unixtime2 / secondsPerDay;

  // If the day numbers are equal, the timestamps are from the same day
  return day1 == day2;
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