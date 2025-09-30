// src/main.cpp
#include <Arduino.h>
#include "AvgFilter.h"
#include "EmaFilter.h"
#include "MedianFilter.h"

// Puedes sobreescribirlos desde platformio.ini con -D LED_PIN=X, -D ANALOG_PIN=Y
#ifndef LED_PIN
  #define LED_PIN 2        // LED onboard típico (ajústalo a tu placa)
#endif

#ifndef ANALOG_PIN
  #define ANALOG_PIN 34    // ADC en ESP32 (entrada sólo, sin pullups)
#endif

// Filtros
AvgFilter   filt_avg(10);     // media móvil ventana 10
EmaFilter   filt_ema(0.2f);   // alpha = 0.2
MedianFilter filt_med(7);     // ventana 7 (IMPAR)

// Helpers de timing (µs)
static inline uint32_t now_us() { return micros(); }

void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // Cabecera EXACTA que esperan los scripts
  Serial.println("raw,avg,ema,med,dt_avg_us,dt_ema_us,dt_med_us");
}

void loop() {
  // Lee ADC (ESP32 es 12-bit por defecto: 0..4095)
  int raw = analogRead(ANALOG_PIN);

  // --- AVG ---
  uint32_t t0 = now_us();
  float v_avg = filt_avg.update((float)raw);
  uint32_t dt_avg = now_us() - t0;

  // --- EMA ---
  t0 = now_us();
  float v_ema = filt_ema.update((float)raw);
  uint32_t dt_ema = now_us() - t0;

  // --- MED ---
  t0 = now_us();
  int v_med = filt_med.update(raw);
  uint32_t dt_med = now_us() - t0;

  // Imprime en el orden/campos exactos
  Serial.print(raw);        Serial.print(",");
  Serial.print((int)v_avg); Serial.print(",");
  Serial.print((int)v_ema); Serial.print(",");
  Serial.print(v_med);      Serial.print(",");
  Serial.print(dt_avg);     Serial.print(",");
  Serial.print(dt_ema);     Serial.print(",");
  Serial.println(dt_med);

  // Blink suave para “vida” del firmware
  static uint32_t t_blink = 0;
  uint32_t now = millis();
  if (now - t_blink >= 500) {
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    t_blink = now;
  }

  // Pequeño respiro para no inundar el puerto (ajusta si quieres más muestras)
  delay(1);
}
