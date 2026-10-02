#!/usr/bin/env python3
"""Regenerate the $readmemh images the Verilog conversions load.

  rtl/rom/coco3_char_rom.vhd  -> verilator/rtl/coco3_char_rom.mem  (4096 x 8)
  rtl/VDAC.mif                -> verilator/rtl/vdac.mem            ( 256 x 16)

Run from the verilator/ directory after either source changes.
"""
import re, sys

def char_rom():
    src = open('../rtl/rom/coco3_char_rom.vhd').read()
    body = src[src.index('signal RAM'):src.index(');', src.index('signal RAM'))]
    vals = re.findall(r'x"([0-9A-Fa-f]{2})"', body)
    if len(vals) != 4096:
        sys.exit(f'coco3_char_rom.vhd: expected 4096 bytes, found {len(vals)}')
    with open('rtl/coco3_char_rom.mem', 'w') as f:
        for i in range(0, 4096, 16):
            f.write(' '.join(v.upper() for v in vals[i:i+16]) + '\n')

def vdac():
    mem = [0] * 256
    txt = open('../rtl/VDAC.mif').read()
    txt = txt[txt.index('CONTENT BEGIN') + len('CONTENT BEGIN'):txt.index('END;')]
    for line in txt.splitlines():
        line = line.split('--')[0].strip().rstrip(';')
        if ':' not in line:
            continue
        addr, data = (s.strip() for s in line.split(':', 1))
        words = data.split()
        if addr.startswith('['):            # [lo..hi] : value
            lo, hi = (int(x, 16) for x in addr[1:-1].split('..'))
            for a in range(lo, hi + 1):
                mem[a] = int(words[0], 16)
        else:
            base = int(addr, 16)
            for i, w in enumerate(words):
                mem[base + i] = int(w, 16)
    with open('rtl/vdac.mem', 'w') as f:
        for i in range(0, 256, 8):
            f.write(' '.join(f'{v:04X}' for v in mem[i:i+8]) + '\n')

char_rom()
vdac()
