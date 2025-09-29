#include <Arduino.h>
#include <unity.h>
#include "AvgFilter.h"

void test_avg_basic() {
  AvgFilter f(4);
  f.push(4); f.push(8);
  TEST_ASSERT_FLOAT_WITHIN(0.01, 6.0, f.mean());
  f.push(0); f.push(0);
  TEST_ASSERT_FLOAT_WITHIN(0.01, 3.0, f.mean());  // (4+8+0+0)/4
  f.push(8); // sale el 4, queda 8+0+0+8=16 -> 4
  TEST_ASSERT_FLOAT_WITHIN(0.01, 4.0, f.mean());
}
void setup() { UNITY_BEGIN(); RUN_TEST(test_avg_basic); UNITY_END(); }
void loop() {}
