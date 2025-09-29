#include "blinker.h"

Blinker::Blinker(uint8_t pin, uint32_t onMs, uint32_t offMs)
  : pin_(pin), onMs_(onMs), offMs_(offMs), last_(0), state_(false) {}

void Blinker::begin() {
  pinMode(pin_, OUTPUT);
  digitalWrite(pin_, LOW);
  state_ = false;
  last_ = millis();
}

void Blinker::run() {
  const uint32_t now = millis();
  const uint32_t period = state_ ? onMs_ : offMs_;
  if (now - last_ >= period) {
    state_ = !state_;
    digitalWrite(pin_, state_ ? HIGH : LOW);
    last_ = now;
  }
}
