#pragma once
#include <Arduino.h>
#include <vector>
#include <algorithm>

// Filtro de mediana con ventana fija.
// O(1) insertar, O(N log N) al calcular la mediana (copiamos+ordenamos).
class MedianFilter {
public:
  explicit MedianFilter(size_t window = 5)
  : w_(window ? window : 1), buf_(w_, 0.0f), head_(0), count_(0) {}

  void reset() {
    head_ = 0; count_ = 0;
    std::fill(buf_.begin(), buf_.end(), 0.0f);
  }

  void push(float v) {
    if (count_ < w_) { buf_[head_] = v; head_ = (head_ + 1) % w_; count_++; return; }
    buf_[head_] = v;
    head_ = (head_ + 1) % w_;
  }

  // “Azúcar” para estilo update()
  float update(float v) { push(v); return median(); }

  float median() const {
    if (!count_) return 0.0f;
    // Copiamos los primeros 'count_' elementos en orden circular
    std::vector<float> tmp; tmp.reserve(count_);
    size_t idx = (head_ + w_ - count_) % w_; // inicio real de la ventana
    for (size_t i = 0; i < count_; ++i) {
      tmp.push_back(buf_[(idx + i) % w_]);
    }
    std::sort(tmp.begin(), tmp.end());
    if (count_ & 1) {
      return tmp[count_ / 2];
    } else {
      // Para N par: promedio de los 2 del centro
      size_t r = count_ / 2;
      return 0.5f * (tmp[r - 1] + tmp[r]);
    }
  }

  size_t size()  const { return w_; }
  size_t count() const { return count_; }

private:
  size_t w_;
  std::vector<float> buf_;
  size_t head_, count_;
};

