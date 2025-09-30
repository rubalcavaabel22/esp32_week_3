#pragma once
#include <Arduino.h>

// Exponential Moving Average: y[n] = alpha*x[n] + (1-alpha)*y[n-1]
// alpha: 0..1  (cercano a 1 reacciona rápido, cercano a 0 suaviza más)
class EmaFilter {
public:
  explicit EmaFilter(float alpha = 0.1f) : alpha_(alpha), inited_(false), y_(0.0f) {}

  void reset() { inited_ = false; y_ = 0.0f; }

  void setAlpha(float a) { alpha_ = constrain(a, 0.0f, 1.0f); }
  float alpha() const { return alpha_; }

  void push(float x) {
    if (!inited_) { y_ = x; inited_ = true; return; }
    y_ = alpha_ * x + (1.0f - alpha_) * y_;
  }

  // “Azúcar” estilo update() → devuelve la salida actual
  float update(float x) { push(x); return y_; }

  float value() const { return y_; }

private:
  float alpha_;
  bool  inited_;
  float y_;
};
