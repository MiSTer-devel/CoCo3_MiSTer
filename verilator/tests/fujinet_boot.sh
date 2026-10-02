#!/usr/bin/env bash
#
# Boot a FujiNet cart against the real FujiNet daemon (FujiNet-PC, the same code
# the MiSTer build runs on the HPS), bridged to the sim's RS-232 Pak by a pty.
#
#   tests/fujinet_boot.sh FUJINET_DIST CART STOP_FRAME [extra sim args...]
#
#   FUJINET_DIST  a FujiNet-PC `make dist` directory for FUJINET_TARGET=COCO
#                 (fujinet binary + data/). A copy is made; the original is not
#                 touched.
#   CONFIG        env: fnconfig.ini to start from (default: FujiNet_MiSTer's
#                 config/fnconfig.ini). Only [Serial] port is changed.
#
#   tests/fujinet_boot.sh ~/fn/dist ../../FujiNet_MiSTer/roms/HDBDW3L3_19200.CCC 400 \
#       --fast-clocks
#
# Output in $OUT (default fujinet_boot/): sim.log, fujinet.log, screenshot.

set -u
cd "$(dirname "$0")/.."
[ $# -ge 3 ] || { sed -n 3,18p "$0"; exit 2; }
dist=$1; cart=$2; stop=$3; shift 3
config=${CONFIG:-../../FujiNet_MiSTer/config/fnconfig.ini}
out=${OUT:-fujinet_boot}
rm -rf "$out"; mkdir -p "$out/fn"
cp -R "$dist"/. "$out/fn/"
mkdir -p "$out/fn/SD"

./obj_dir/Vemu --headless --cart "$cart" --serial-pty --stop-at-frame "$stop" \
	--screenshot "$stop" --screenshot-prefix "$out/shot" --ascii-end "$@" > "$out/sim.log" 2>&1 &
sim=$!
pty=
for _ in $(seq 1 100); do
	pty=$(grep -o '/dev/ttys[0-9]*\|/dev/pts/[0-9]*' "$out/sim.log" | head -1)
	[ -n "$pty" ] && break
	sleep 0.1
done
[ -n "$pty" ] || { echo "sim did not open a pty"; kill $sim; exit 1; }

sed "s|^port=.*|port=$pty|" "$config" > "$out/fn/fnconfig.ini"
echo "sim on $pty; FujiNet config from $config"
( cd "$out/fn" && exec ./fujinet -c fnconfig.ini -s SD ) > "$out/fujinet.log" 2>&1 &
fn=$!
trap 'kill $sim $fn 2>/dev/null' INT TERM
wait $sim
kill $fn 2>/dev/null

echo "--- sim"
grep -E '^\||^Serial' "$out/sim.log" | grep -v '^|  *|$'
echo "--- FujiNet (DriveWire lines)"
grep -a -i -E 'drivewire|op_|readex|read |sector|lsn|timeout|checksum|mount|serial' "$out/fujinet.log" | head -60
