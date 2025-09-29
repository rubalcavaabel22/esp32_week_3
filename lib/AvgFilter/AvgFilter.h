#pragma once
#include <Arduino.h>
#include <vector>

// Promedio móvil con ventana fija (O(1) por muestra)
class AvgFilter {
 public:
  explicit AvgFilter(size_t window = 16)
  : w_(window ? window : 1), buf_(w_, 0.0f), head_(0), count_(0), sum_(0.0f) {}

  void reset() {
    head_ = 0; count_ = 0; sum_ = 0.0f;
    std::fill(buf_.begin(), buf_.end(), 0.0f);
  }

  void push(float v) {
    if (count_ < w_) {               // llenar buffer
      sum_ += v; buf_[head_] = v;
      head_ = (head_ + 1) % w_; count_++;
      return;
    }
    // buffer lleno: sacar el más viejo y meter el nuevo
    sum_ -= buf_[head_];
    buf_[head_] = v;
    sum_ += v;
    head_ = (head_ + 1) % w_;
  }

  float mean()  const { return count_ ? (sum_ / count_) : 0.0f; }
  size_t size() const { return w_; }
  size_t count()const { return count_; }

 private:
  size_t w_;
  std::vector<float> buf_;
  size_t head_, count_;
  float sum_;
};
