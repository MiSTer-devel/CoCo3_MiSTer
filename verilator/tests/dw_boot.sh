#!/usr/bin/env bash
#
# Boot a DriveWire cart (e.g. FujiNet's HDB-DOS SY6551 build) with the sim's
# RS-232 Pak bridged to tests/dwserver.py serving a disk image.
#
#   tests/dw_boot.sh CART DISK STOP_FRAME [extra sim args...]
#
#   tests/dw_boot.sh ../../FujiNet_MiSTer/roms/HDBDW3S3.CCC tests/hello.dsk 350 \
#       --type '140:RUN"HELLO\n'
#
# Output: dw_boot.log (sim), dw_boot.dw.log (server), dw_boot_frame_NNNN.png.
# Needs the RS232_EN fix in rtl/coco3fpga.sv (or --acia-any-slot on older RTL);
# see README, "FujiNet on this core".

set -u
cd "$(dirname "$0")/.."
[ $# -ge 3 ] || { sed -n 3,14p "$0"; exit 2; }
cart=$1; disk=$2; stop=$3; shift 3

./obj_dir/Vemu --headless --cart "$cart" --serial-pty --stop-at-frame "$stop" \
	--screenshot "$stop" --screenshot-prefix dw_boot --ascii-end "$@" > dw_boot.log 2>&1 &
sim=$!
pty=
for _ in $(seq 1 100); do
	pty=$(grep -o '/dev/ttys[0-9]*\|/dev/pts/[0-9]*' dw_boot.log | head -1)
	[ -n "$pty" ] && break
	sleep 0.1
done
[ -n "$pty" ] || { echo "sim did not open a pty"; kill $sim; exit 1; }
echo "sim on $pty, serving $disk"
python3 tests/dwserver.py "$pty" "$disk" > dw_boot.dw.log 2>&1 &
dw=$!
trap 'kill $sim $dw 2>/dev/null' INT TERM
wait $sim
kill $dw 2>/dev/null

echo "--- DriveWire server"; cat dw_boot.dw.log
echo "--- sim"; grep -E '^\||^Serial' dw_boot.log | grep -v '^|  *|$'
