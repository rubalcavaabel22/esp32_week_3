#pragma once
#include <Arduino.h>

// Blinker: parpadeo no bloqueante (sin delay) usando millis()
class Blinker {
 public:
  Blinker(uint8_t pin, uint32_t onMs = 200, uint32_t offMs = 800);

  void begin();  // pinMode + estado inicial
  void run();    // llámalo en loop()

  // ----- Ayudas para pruebas (opcionales) -----
  bool state() const { return state_; }   // true: LED ON
  uint8_t pin() const { return pin_; }

 private:
  uint8_t pin_;
  uint32_t onMs_, offMs_;
  uint32_t last_;
  bool state_;
};
