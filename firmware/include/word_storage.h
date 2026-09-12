#pragma once
#include <stddef.h>
#include <stdint.h>

// IRAM permits only aligned 32-bit accesses. Never pass its address directly to
// TLS, hashing, flash I/O or drawing libraries that may use byte/halfword accesses.
// volatile prevents the compiler replacing these accesses with byte instructions.
inline void storeWordBytes(volatile uint32_t* storage, size_t offset,
                           const uint8_t* input, size_t count) {
  while (count) {
    const size_t lane = offset % 4;
    const size_t amount = count < 4 - lane ? count : 4 - lane;
    uint32_t word = lane == 0 && amount == 4 ? 0 : storage[offset / 4];
    for (size_t i = 0; i < amount; ++i) {
      const unsigned shift = (lane + i) * 8;
      word = (word & ~(uint32_t(255) << shift)) | (uint32_t(input[i]) << shift);
    }
    storage[offset / 4] = word;
    input += amount;
    offset += amount;
    count -= amount;
  }
}

inline void loadWordBytes(const volatile uint32_t* storage, size_t offset,
                          uint8_t* output, size_t count) {
  while (count) {
    const size_t lane = offset % 4;
    const size_t amount = count < 4 - lane ? count : 4 - lane;
    const uint32_t word = storage[offset / 4];
    for (size_t i = 0; i < amount; ++i)
      output[i] = static_cast<uint8_t>(word >> ((lane + i) * 8));
    output += amount;
    offset += amount;
    count -= amount;
  }
}

// Exercise real allocated memory before networking, including fragmented reads,
// odd byte offsets, preserved surrounding bytes and the end of the allocation.
inline bool checkWordStorage(volatile uint32_t* storage, size_t capacity) {
  uint8_t input[37], output[41];
  for (size_t i = 0; i < sizeof(input); ++i) input[i] = static_cast<uint8_t>(i * 73 + 19);
  const size_t starts[] = {1, 2, 3, capacity - sizeof(input) - 1};
  for (size_t start : starts) {
    const size_t first = (start - 1) / 4;
    const size_t last = (start + sizeof(input)) / 4;
    for (size_t i = first; i <= last; ++i) storage[i] = 0xA5A5A5A5;
    size_t written = 0;
    while (written < sizeof(input)) {
      size_t amount = written % 7 + 1;
      if (amount > sizeof(input) - written) amount = sizeof(input) - written;
      storeWordBytes(storage, start + written, input + written, amount);
      written += amount;
    }
    loadWordBytes(storage, start - 1, output, sizeof(input) + 2);
    if (output[0] != 0xA5 || output[sizeof(input) + 1] != 0xA5) return false;
    for (size_t i = 0; i < sizeof(input); ++i) if (output[i + 1] != input[i]) return false;
  }
  return true;
}
