#!/usr/bin/env python3
"""Build tests/hello.dsk: a Disk BASIC (DECB) floppy holding one ASCII BASIC
program, HELLO.BAS. Used by run_tests.sh to exercise the FDC path end to end:
wd1793 -> fdc.sv -> hps block device -> sim_blkdevice.

Layout (35 tracks x 18 sectors x 256 bytes, sectors numbered from 1):
  track 17 sector 2      FAT, one byte per granule (68 granules of 9 sectors)
  track 17 sectors 3-11  directory, 32-byte entries
Granules 0/1 are track 0 sectors 1-9 / 10-18, granule 2k is track k (k<17),
and so on, skipping the directory track.
"""
import os

TRACKS, SECTORS, SSIZE = 35, 18, 256
img = bytearray(b'\xff' * (TRACKS * SECTORS * SSIZE))

def sector(track, sec):                 # sec is 1-based
    off = (track * SECTORS + sec - 1) * SSIZE
    return off

prog = b'10 PRINT "HELLO FROM DISK"\r20 PRINT 6*7\r'

# The program goes in granule 0 (track 0, sectors 1..9); it fits in one sector.
img[sector(0, 1):sector(0, 1) + SSIZE] = prog.ljust(SSIZE, b'\x00')

# FAT: granule 0 is the last granule of the file and uses 1 sector.
fat = sector(17, 2)
img[fat:fat + SSIZE] = b'\xff' * SSIZE
img[fat + 0] = 0xC0 | 1
img[fat + 68:fat + SSIZE] = b'\x00' * (SSIZE - 68)

# Directory: first entry HELLO.BAS, BASIC (type 0), ASCII (flag $FF).
d = sector(17, 3)
entry = bytearray(32)
entry[0:8]   = b'HELLO   '
entry[8:11]  = b'BAS'
entry[11]    = 0x00                 # file type: BASIC program
entry[12]    = 0xFF                 # ASCII
entry[13]    = 0                    # first granule
entry[14:16] = len(prog).to_bytes(2, 'big')   # bytes used in the last sector
img[d:d + 32] = entry
# Unused entries start with $FF ("never used"); the rest of the track is $FF.

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'hello.dsk')
open(out, 'wb').write(img)
print(f'wrote {out} ({len(img)} bytes)')
