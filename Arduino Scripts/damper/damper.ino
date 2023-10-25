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

String mac; // used as damper id
String labelPath;
String positionPath; // firebase path to position value of this damper
String lastHeartbeatPath;
String schedulePath;

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

struct TimePosition {
    int time;
    int position;
};

#define MAX_SCHEDULES_PER_DAY 10  // Assuming a maximum of 10 schedule entries per day. Adjust as needed.

struct DaySchedule {
    int day;
    TimePosition schedule[MAX_SCHEDULES_PER_DAY];
    int scheduleCount;  // To track the number of entries in the schedule array.
};

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
  
  String devicePath = userId + "/" + mac;
  positionPath = devicePath + "/position";
  lastHeartbeatPath = devicePath + "/lastHeartbeat";
  labelPath = devicePath + "/label";
  schedulePath = devicePath + "/schedule";


  // Store received values in flash storage
  if (!storedCredentials.initialized) {
    setLabel();
    setPosition();
    getCurrentMillis();
    sendHeartbeat();
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
    }
    delay(2000); // Delay to prevent rapid Firebase requests. Adjust as needed.
    sendHeartbeat();

    unsigned long unixtime = initialUnixTime + ((millis() - initialMillis) / 1000);
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
      setPosition();
      setLabel();
      getCurrentMillis();
      sendHeartbeat();
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

DaySchedule* getSchedule() {
    static DaySchedule daySchedules[7];  // One for each day of the week

    // Initialize daySchedules with default values
    for (int i = 0; i < 7; i++) {
      daySchedules[i].scheduleCount = 0;
      for (int j = 0; j < MAX_SCHEDULES_PER_DAY; j++) {
        daySchedules[i].schedule[j].time = -1;
        daySchedules[i].schedule[j].position = -1;
      }
    }

    if (Firebase.getJSON(fbdo, schedulePath)) {
        String scheduleJson = fbdo.jsonData();
        DynamicJsonDocument doc(2048); 
        deserializeJson(doc, scheduleJson);

        for (JsonPair kv : doc.as<JsonObject>()) {
        int day = String(kv.key().c_str()).substring(1).toInt();
        JsonObject dayScheduleJson = kv.value().as<JsonObject>();

        DaySchedule currentDay;
        currentDay.day = day;
        currentDay.scheduleCount = 0;

        for (JsonPair dayKv : dayScheduleJson) {
          if (currentDay.scheduleCount < MAX_SCHEDULES_PER_DAY) {
            TimePosition timePos;
            timePos.time = String(dayKv.key().c_str()).toInt();
            timePos.position = dayKv.value().as<int>();

            currentDay.schedule[currentDay.scheduleCount] = timePos;
            currentDay.scheduleCount++;
          }
        }
        daySchedules[day] = currentDay;
      }
    } else {
      Serial.println("Failed to retrieve schedule from Firebase: " + fbdo.errorReason());
    }

    return daySchedules;  // Return the array even if empty
}

void applySchedule(){
  Serial.println("Getting schedule...");
  DaySchedule* daySchedules = getSchedule();
  printDaySchedules(daySchedules);

  unsigned long unixtime = initialUnixTime + ((millis() - initialMillis) / 1000);

  // Convert current Unix time to day of the week and HHMM format.
  int adjustedUnixTime = unixtime - (4 * 3600);  // subtract 4 hours
  int currentDayOfWeek = ((adjustedUnixTime / 86400 + 4) % 7) - 1; // 1970-01-01 was a Thursday (day 4). -1 for index
  int currentTime = ((adjustedUnixTime % 86400) / 3600) * 100 + ((adjustedUnixTime % 3600) / 60);


  Serial.println("Current day of week: " + String(currentDayOfWeek));
  Serial.println("Current time: " + String(currentTime));

  DaySchedule* todayPtr = &daySchedules[currentDayOfWeek];

  Serial.println("Printing todayPtr:");
  Serial.println("Day: " + String(todayPtr->day));
  Serial.println("ScheduleCount: " + String(todayPtr->scheduleCount));

  for (int i = 0; i < todayPtr->scheduleCount; i++) {
      Serial.print("Time: ");
      Serial.print(todayPtr->schedule[i].time);
      Serial.print(", Position: ");
      Serial.println(todayPtr->schedule[i].position);
  }

  // Find the latest scheduled time that is before or equal to the current time.
  int latestScheduledTime = -1;
  int scheduledPosition = -1;

  for (int i = 0; i < todayPtr->scheduleCount; i++) {
    if (todayPtr->schedule[i].time <= currentTime && todayPtr->schedule[i].time > latestScheduledTime) {
      latestScheduledTime = todayPtr->schedule[i].time;
      scheduledPosition = todayPtr->schedule[i].position;
    }
  }

  Serial.println("Latest scheduled time: " + String(latestScheduledTime));
  Serial.println("Scheduled position: " + String(scheduledPosition));

  if (scheduledPosition != -1 && scheduledPosition != position) {
    myservo.write(scheduledPosition);
    position = scheduledPosition;
    setPosition();
  }
}

void printDaySchedules(DaySchedule* daySchedules) {
    Serial.println("Printing Day Schedules:");

    // Loop through each day of the week
    for (int i = 0; i < 7; i++) {
        Serial.println("Day: " + String(i));
        Serial.println("ScheduleCount: " + String(daySchedules[i].scheduleCount));

        // For each day, loop through the scheduled times
        for (int j = 0; j < daySchedules[i].scheduleCount; j++) {
            if (daySchedules[i].schedule[j].time == -1) {
              break; // exit the inner for loop
            }

            Serial.print("Time: ");
            Serial.print(daySchedules[i].schedule[j].time);
            Serial.print(", Position: ");
            Serial.println(daySchedules[i].schedule[j].position);
        }

        Serial.println("----");
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

void sendHeartbeat() {
  unsigned long unixtime = initialUnixTime + ((millis() - initialMillis) / 1000);
  Serial.print("lastHeartbeat: ");
  Serial.println(unixtime);

  while(!Firebase.setInt(fbdo, lastHeartbeatPath, unixtime));
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