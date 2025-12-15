#include <Arduino.h>
#include <WebServer.h>
#include <Adafruit_NeoPixel.h>
#include <ArduinoJson.h>
#include <WiFiManager.h>  // https://github.com/tzapu/WiFiManager

// ---------- LED strip ----------
const uint8_t LED_PIN   = D10;   // change if you wired to another pin
const uint16_t NUM_LEDS = 30;    // set to your strip length

Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);

// ---------- Lamp state ----------
bool   g_isOn      = false;
float  g_intensity = 0.6f;       // 0.0–1.0
uint8_t g_r = 255, g_g = 184, g_b = 144; // default warm color

WebServer server(80);

// ---------- Helpers ----------
void applyLeds() {
  uint8_t r = uint8_t(g_r * g_intensity);
  uint8_t g = uint8_t(g_g * g_intensity);
  uint8_t b = uint8_t(g_b * g_intensity);

  if (!g_isOn) {
    r = g = b = 0;
  }

  for (uint16_t i = 0; i < NUM_LEDS; ++i) {
    strip.setPixelColor(i, strip.Color(r, g, b));
  }
  strip.show();
}

void sendJsonStatus() {
  StaticJsonDocument<256> doc;
  doc["isOn"]      = g_isOn;
  doc["intensity"] = g_intensity;
  doc["r"]         = g_r;
  doc["g"]         = g_g;
  doc["b"]         = g_b;

  String json;
  serializeJson(doc, json);
  server.send(200, "application/json", json);
}

// ---------- HTTP handlers ----------

// POST /on
void handleOn() {
  g_isOn = true;
  applyLeds();
  server.send(200, "text/plain", "on");
}

// POST /off
void handleOff() {
  g_isOn = false;
  applyLeds();
  server.send(200, "text/plain", "off");
}

// POST /color { "r": 255, "g": 100, "b": 50 }
void handleColor() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "missing body");
    return;
  }

  StaticJsonDocument<128> doc;
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    server.send(400, "text/plain", "invalid json");
    return;
  }

  g_r = doc["r"] | g_r;
  g_g = doc["g"] | g_g;
  g_b = doc["b"] | g_b;

  applyLeds();
  server.send(200, "text/plain", "color set");
}

// POST /intensity { "value": 0.6 }
void handleIntensity() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "missing body");
    return;
  }

  StaticJsonDocument<128> doc;
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    server.send(400, "text/plain", "invalid json");
    return;
  }

  float v = doc["value"] | g_intensity;
  v = constrain(v, 0.0f, 1.0f);
  g_intensity = v;

  applyLeds();
  server.send(200, "text/plain", "intensity set");
}

// GET /status
// matches the iOS `Status` struct: { isOn, intensity, r, g, b }
void handleStatus() {
  sendJsonStatus();
}

// ---------- Setup & loop ----------
void setup() {
  Serial.begin(115200);
  delay(200);

  strip.begin();
  strip.show(); // all off

  Serial.println();
  Serial.println("Starting WiFiManager...");

  WiFiManager wifiManager;
  wifiManager.setClass("invert");        // optional: dark theme, per WiFiManager docs

  // Will try saved credentials; if none / fail, opens AP "SmartLamp-Setup"
  bool res = wifiManager.autoConnect("SmartLamp-Setup");
  if (!res) {
    Serial.println("Failed to connect, restarting...");
    delay(3000);
    ESP.restart();
  }

  Serial.print("Connected. IP: ");
  Serial.println(WiFi.localIP());

  server.on("/on",        HTTP_POST, handleOn);
  server.on("/off",       HTTP_POST, handleOff);
  server.on("/color",     HTTP_POST, handleColor);
  server.on("/intensity", HTTP_POST, handleIntensity);
  server.on("/status",    HTTP_GET,  handleStatus);

  server.begin();
  Serial.println("HTTP server started");

  applyLeds();
}

void loop() {
  server.handleClient();
}


