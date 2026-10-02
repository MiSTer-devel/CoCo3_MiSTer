#pragma once
#include <cstdint>
#include <cstddef>

// Motorola 6809 disassembler.
//
// `read_byte` returns 0..255, or -1 for an address whose contents are not
// known. The sim feeds it a shadow of every byte the CPU has actually put on
// the bus, so unknown means "the CPU never fetched or wrote this" -- which is
// itself informative, and prints as "??".
//
// Returns the instruction length in bytes (1..5), and writes the mnemonic and
// operand to `out`. On an unknown opcode it emits "FCB $xx" and returns 1, so a
// caller walking a byte stream always makes progress.
int dis6809(uint16_t pc, int (*read_byte)(uint16_t), char* out, size_t outlen);

// Human-readable CC, e.g. "EFHINZVC" with cleared flags lower-cased.
void cc6809_string(uint8_t cc, char out[9]);
