#include <Arduino.h>
#if defined(ESP32)
  #include <WiFi.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
#endif
#include <Firebase_ESP_Client.h>
#include <NTPClient.h>
#include <WiFiUdp.h>


#include "addons/TokenHelper.h"

#include "addons/RTDBHelper.h"


#define WIFI_SSID "NOS-0B28"
#define WIFI_PASSWORD "HJMJNHVJ"


#define API_KEY "AIzaSyCnAI4vird0-frO8YevKfsFEilwqEN0v3o"


#define DATABASE_URL "https://framekeeper-21f98-default-rtdb.europe-west1.firebasedatabase.app/"


FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
unsigned long sendDataPrevMillis2 = 0;
unsigned long sendDataPrevMillis3 = 0;
unsigned long lastThresholdReadMillis = 0;
unsigned long lastFanMillis = 0;
int count = 0;
bool signupOK = false;

#define SIGNAL_PIN 22
#include <DHT.h>

#define DHT_SENSOR_PIN 4 //  pin connected to DHT22
#define RELAY_FAN_PIN  18 //  pin connected to relay

#define DHT_SENSOR_TYPE DHT22

#define INTERVAL_15_SECS 15000
#define INTERVAL_ONE_HOUR 3600000
#define INTERVAL_15_MINS 900000

int HUM_UPPER_THRESHOLD = 60; // default value
bool fan = true;

DHT dht_sensor(DHT_SENSOR_PIN, DHT_SENSOR_TYPE);


int redPin= 23;
int greenPin = 19;
int  bluePin = 21;


WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

void setup()
{
  Serial.begin(115200);
  dht_sensor.begin(); 
  pinMode(SIGNAL_PIN, INPUT);
  pinMode(redPin,  OUTPUT);              
  pinMode(greenPin, OUTPUT);
  pinMode(bluePin, OUTPUT);
  pinMode(RELAY_FAN_PIN, OUTPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED){
    Serial.print(".");
    delay(300);
  }

  config.api_key = API_KEY;


  config.database_url = DATABASE_URL;


  if (Firebase.signUp(&config, &auth, "", "")){
    signupOK = true;
  }
  else{
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  config.token_status_callback = tokenStatusCallback; 

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  timeClient.begin();
  timeClient.setTimeOffset(0);
}
void switchToUnusedPin() {
  pinMode(RELAY_FAN_PIN, INPUT); 
}
void switchToRelayPin() {
  pinMode(RELAY_FAN_PIN, OUTPUT); 
}

void setColor(int redValue, int greenValue,  int blueValue) {
  analogWrite(redPin, redValue);
  analogWrite(greenPin,  greenValue);
  analogWrite(bluePin, blueValue);
}

String getFormattedDateTime() {
  timeClient.update();
  unsigned long epochTime = timeClient.getEpochTime();
  
  int timeOffset = 0;


  time_t rawtime = epochTime;
  struct tm * timeinfo = localtime(&rawtime);
  if (timeinfo->tm_isdst > 0) {

    timeOffset = 3600;
  }

  epochTime += timeOffset;

  struct tm *ptm = gmtime ((time_t *)&epochTime); 

  int year = ptm->tm_year + 1900;
  int month = ptm->tm_mon + 1;
  int day = ptm->tm_mday;
  int hour = ptm->tm_hour + 1;
  int minute = ptm->tm_min;
  int second = ptm->tm_sec;

  char dateTime[25];
  sprintf(dateTime, "%02d-%02d-%04d %02d:%02d", day, month, year, hour, minute);
  return String(dateTime);
}
void readHumidityThreshold() {
  if (!Firebase.RTDB.getFloat(&fbdo, "rooms/Room1 - Louvre Museum/maxHumidity")) {
  } else {
    HUM_UPPER_THRESHOLD = fbdo.floatData();
  }
}

void readFan() {
  if (!Firebase.RTDB.getBool(&fbdo, "rooms/Room1 - Louvre Museum/fan")) {
  } else {
    fan = fbdo.boolData();
  }
}

void loop() {
  float humi = dht_sensor.readHumidity();
  Serial.println(humi);

  if (millis() - lastThresholdReadMillis >  INTERVAL_15_SECS) { 
    lastThresholdReadMillis = millis();
    readHumidityThreshold();
  }

if (millis() - lastFanMillis >  INTERVAL_15_SECS) { 
    lastFanMillis = millis();
    readFan();
  }

  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > INTERVAL_15_SECS || sendDataPrevMillis == 0)){
      sendDataPrevMillis = millis();
      if (Firebase.RTDB.setFloat(&fbdo, "rooms/Room1 - Louvre Museum/currentHumidity", humi)){
        Serial.println("PASSED");
        Serial.println("PATH: " + fbdo.dataPath());
        Serial.println("TYPE: " + fbdo.dataType());
      }
      else {
        Serial.println("FAILED");
        Serial.println("REASON: " + fbdo.errorReason());
      }
  }

  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis2 > INTERVAL_ONE_HOUR || sendDataPrevMillis2 == 0)){
      sendDataPrevMillis2 = millis();
      String dateTime = getFormattedDateTime();
      String dataString = dateTime + " " + String(humi);
      if (Firebase.RTDB.pushString(&fbdo, "rooms/Room1 - Louvre Museum/humidityHistory", dataString)){
        Serial.println("PASSED");
        Serial.println("PATH: " + fbdo.dataPath());
        Serial.println("TYPE: " + fbdo.dataType());
      }
      else {
        Serial.println("FAILED");
        Serial.println("REASON: " + fbdo.errorReason());
      }
  }



  if(digitalRead(SIGNAL_PIN)==HIGH) {
    setColor(255, 0, 0); 
    
    Serial.println("Movement detected.");


    if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis3 > INTERVAL_15_MINS || sendDataPrevMillis3 == 0)){

      sendDataPrevMillis3 = millis();
      String dateTime = getFormattedDateTime();

      if (Firebase.RTDB.pushString(&fbdo, "rooms/Room1 - Louvre Museum/breachHistory", dateTime)){
        Serial.println("PASSED");
        Serial.println("PATH: " + fbdo.dataPath());
        Serial.println("TYPE: " + fbdo.dataType());
      }
      else {
        Serial.println("FAILED");
        Serial.println("REASON: " + fbdo.errorReason());
      }
    }
    if (Firebase.ready() && signupOK){
          if (Firebase.RTDB.setBool(&fbdo, "rooms/Room1 - Louvre Museum/movement", true)){
            Serial.println("PASSED");
            Serial.println("PATH: " + fbdo.dataPath());
            Serial.println("TYPE: " + fbdo.dataType());
          }
          else {
            Serial.println("FAILED");
            Serial.println("REASON: " + fbdo.errorReason());
          }
    }

  } else {

    if (Firebase.ready() && signupOK){

      if (Firebase.RTDB.setBool(&fbdo, "rooms/Room1 - Louvre Museum/movement", false)){
        Serial.println("PASSED");
        Serial.println("PATH: " + fbdo.dataPath());
        Serial.println("TYPE: " + fbdo.dataType());
      }
      else {
        Serial.println("FAILED");
        Serial.println("REASON: " + fbdo.errorReason());
      }
    }
    setColor(0, 255, 0); 
    Serial.println("Did not detect movement.");
  }
  
  
    if (humi > HUM_UPPER_THRESHOLD && fan) {
      switchToRelayPin();
      Serial.println("Turn the fan on");
    } else  {
      if(!fan){
      switchToUnusedPin();
      }
    }

    if(fan){
      switchToRelayPin();
    }

  delay(1000);
}

