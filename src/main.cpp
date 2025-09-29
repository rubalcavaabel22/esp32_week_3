// Requerido SOLO en ESP32-S3 
//#define ARDUINO_USB_MODE 1
//#define ARDUINO_USB_CDC_ON_BOOT 1

#include <Arduino.h>
#include "blinker.h"
#include "AvgFilter.h"

// Pueden venir de build_flags; si no, ponemos defaults
#ifndef LED_PIN
#define LED_PIN 48        // S3 DevKitC típico
#endif
#ifndef ANALOG_PIN
#define ANALOG_PIN 34     // ESP32 dev: GPIO34 (solo entrada, ADC)
#endif
#ifndef ADC_MV_REF
#define ADC_MV_REF 3300   // referencia aprox para convertir a mV
#endif

Blinker   led(LED_PIN, 150, 350);
AvgFilter filt(16);                   // ventana de 16 muestras

void setup() {
  Serial.begin(115200);
  delay(100);
  Serial.println("Semana 3: AvgFilter + ADC ✅");
  led.begin();

  // Ajustes básicos de ADC (12 bits común en ESP32/ESP32-S3)
  analogReadResolution(12); // 0..4095
  // Si quieres rango ~3.3V (opcional; depende del pin):
  // analogSetPinAttenuation(ANALOG_PIN, ADC_11db);
}

static inline float raw_to_mv(int raw) {
  // Si tu core soporta analogReadMilliVolts(ANALOG_PIN), úsal0.
  // Aquí usamos conversión lineal aproximada:
  return (raw * (float)ADC_MV_REF) / 4095.0f;
}

void loop() {
  led.run();

  static uint32_t t = millis();
  if (millis() - t >= 100) {          // cada 100 ms
    int   raw = analogRead(ANALOG_PIN);
    float mv  = raw_to_mv(raw);
    filt.push((float)raw);

    Serial.print("RAW: ");  Serial.print(raw);
    Serial.print(" | AVG("); Serial.print(filt.size()); Serial.print("): ");
    Serial.print(filt.mean(), 1);
    Serial.print(" | V: "); Serial.print(mv / 1000.0f, 3);
    Serial.println(" V");

    t = millis();
  }
}
