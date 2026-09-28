#!/usr/bin/env python3
"""Minimal DriveWire 3 server for the sim's --serial-pty.

Serves one or more .dsk images (256-byte sectors, LSN n at offset n*256) to
HDB-DOS DW over the pty the sim prints at start-up:

    ./obj_dir/Vemu --serial-pty ... &          # prints "Serial: ... on pty /dev/ttysNNN"
    python3 tests/dwserver.py /dev/ttysNNN tests/hello.dsk

It is a test stand-in for FujiNet / pyDriveWire, covering only what HDB-DOS
uses: READ/READEX/REREAD(EX), WRITE/REWRITE, TIME, INIT/TERM/RESET/NOP and
DWINIT. Every operation is logged. Writes go to memory, never to the file.
Uses only the standard library.
"""
import os
import sys
import termios
import time
import tty

OP_NOP, OP_TIME, OP_INIT, OP_TERM = 0x00, 0x23, 0x49, 0x54
OP_READ, OP_REREAD, OP_READEX, OP_REREADEX = 0x52, 0x72, 0xD2, 0xF2
OP_WRITE, OP_REWRITE, OP_DWINIT = 0x57, 0x77, 0x5A
OP_RESETS = (0xFE, 0xFF, 0xF8)
E_OK, E_CRC, E_NOTRDY = 0x00, 0xF3, 0xF6


def log(msg):
    print(f"[dw {time.strftime('%H:%M:%S')}] {msg}", flush=True)


class Port:
    def __init__(self, path):
        self.fd = os.open(path, os.O_RDWR | os.O_NOCTTY)
        tty.setraw(self.fd)
        attrs = termios.tcgetattr(self.fd)
        attrs[3] &= ~termios.ECHO
        termios.tcsetattr(self.fd, termios.TCSANOW, attrs)

    def read(self, n):
        out = b""
        while len(out) < n:
            chunk = os.read(self.fd, n - len(out))
            if not chunk:
                raise EOFError
            out += chunk
        return out

    def write(self, data):
        os.write(self.fd, data)


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    port = Port(sys.argv[1])
    disks = [bytearray(open(p, "rb").read()) for p in sys.argv[2:]]
    for i, p in enumerate(sys.argv[2:]):
        log(f"drive {i}: {p} ({len(disks[i]) // 256} sectors)")

    def sector(drive, lsn):
        if drive >= len(disks):
            return None
        d = disks[drive]
        off = lsn * 256
        return bytes(d[off:off + 256]).ljust(256, b"\x00") if off < len(d) else bytes(256)

    while True:
        op = port.read(1)[0]
        if op in (OP_READEX, OP_REREADEX):
            drive, *l = port.read(4)
            lsn = (l[0] << 16) | (l[1] << 8) | l[2]
            data = sector(drive, lsn)
            port.write(data if data is not None else bytes(256))
            csum = int.from_bytes(port.read(2), "big")
            ok = data is not None and csum == sum(data) & 0xFFFF
            err = E_OK if ok else (E_NOTRDY if data is None else E_CRC)
            port.write(bytes([err]))
            log(f"{'REREADEX' if op == OP_REREADEX else 'READEX'} drive {drive} LSN {lsn}"
                f" -> {'ok' if ok else f'error ${err:02X} (their checksum ${csum:04X})'}")
        elif op in (OP_READ, OP_REREAD):
            drive, *l = port.read(4)
            lsn = (l[0] << 16) | (l[1] << 8) | l[2]
            data = sector(drive, lsn)
            if data is None:
                port.write(bytes([E_NOTRDY]))
            else:
                port.write(bytes([E_OK]) + data + (sum(data) & 0xFFFF).to_bytes(2, "big"))
            log(f"READ drive {drive} LSN {lsn}")
        elif op in (OP_WRITE, OP_REWRITE):
            drive, *l = port.read(4)
            lsn = (l[0] << 16) | (l[1] << 8) | l[2]
            data = port.read(256)
            csum = int.from_bytes(port.read(2), "big")
            ok = csum == sum(data) & 0xFFFF and drive < len(disks)
            if ok:
                d = disks[drive]
                need = (lsn + 1) * 256
                if len(d) < need:
                    d.extend(bytes(need - len(d)))
                d[lsn * 256:need] = data
            port.write(bytes([E_OK if ok else E_CRC]))
            log(f"WRITE drive {drive} LSN {lsn} -> {'ok' if ok else 'checksum error'}")
        elif op == OP_TIME:
            t = time.localtime()
            port.write(bytes([t.tm_year - 1900, t.tm_mon, t.tm_mday,
                              t.tm_hour, t.tm_min, t.tm_sec]))
            log("TIME")
        elif op == OP_DWINIT:
            caps = port.read(1)[0]
            port.write(bytes([0x00]))
            log(f"DWINIT (client caps ${caps:02X})")
        elif op in (OP_INIT, OP_TERM, OP_NOP) or op in OP_RESETS:
            log(f"op ${op:02X}")
        else:
            log(f"unknown op ${op:02X} -- ignored")


if __name__ == "__main__":
    try:
        main()
    except (EOFError, KeyboardInterrupt):
        pass
