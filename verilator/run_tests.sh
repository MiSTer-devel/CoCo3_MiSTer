#!/usr/bin/env bash
#
# Headless smoke tests for the CoCo3 sim. Each test boots the machine, types at
# BASIC on a frame schedule, and is judged two ways:
#
#   * the TEXT SCREEN ($0400, as the CPU wrote it) must contain every expected
#     string -- this is what says the machine did the right thing;
#   * the final SCREENSHOT is compared byte for byte with $REF/<name>.png --
#     this is what catches a video change nobody meant to make.
#
# The sim is deterministic, so a screenshot only moves when the RTL (or the
# harness) moves it. When a change is intentional, bless the new references:
#
#   BLESS=1 ./run_tests.sh
#
# A test with no reference is reported "new" and does not fail the run.
# Tests run in parallel; each is a few minutes (the sim runs at ~1.2 frames/s,
# and the core's own power-on reset plus the BASIC banner take ~130 frames).
#
#   ./run_tests.sh               all tests
#   ./run_tests.sh boot disk     just those
#
# Needs roms/boot0.rom (CoCo3 ROM) and roms/boot1.rom (Disk BASIC 1.1); see
# README.md.

set -u
cd "$(dirname "$0")"

EXE=./obj_dir/Vemu
OUT=${OUT:-test-out}
SIMARGS=${SIMARGS:-}            # extra sim options for every test, e.g. --fast-clocks
REF=${REF:-test-ref}
mkdir -p "$OUT" "$REF"

if [ ! -x "$EXE" ]; then echo "build first: make"; exit 2; fi
for r in roms/boot0.rom roms/boot1.rom; do
	[ -f "$r" ] || { echo "missing $r -- see README.md"; exit 2; }
done
[ -f tests/hello.dsk ] || python3 tests/make_test_disk.py >/dev/null

# name | stop frame | extra args | expected strings (;-separated)
TESTS=(
	"boot|150||DISK EXTENDED COLOR BASIC 2.1;OK"
	"keyboard|260|--type '140:PRINT 2+2\\n'|PRINT 2+2; 4"
	"disk|420|--disk tests/hello.dsk --type '140:RUN\"HELLO\\n'|HELLO FROM DISK; 42"
	# GIME modes. --ascii only reads the 32-column VDG screen, so these two are
	# judged on the screenshot alone.
	"width80|330|--type '140:WIDTH 80\\nPRINT \"80 COLUMNS\"\\n'|"
	"hscreen|560|--type '140:HSCREEN2:HCIRCLE(160,96),60,4:HLINE(0,0)-(319,191),PSET,B:FORI=1TO9E9:NEXT\\n'|"
)

want=("$@")
selected() {
	[ ${#want[@]} -eq 0 ] && return 0
	for w in "${want[@]}"; do [ "$w" = "$1" ] && return 0; done
	return 1
}

pids=()
names=()
for t in "${TESTS[@]}"; do
	IFS='|' read -r name stop extra expect <<<"$t"
	selected "$name" || continue
	# shellcheck disable=SC2086
	eval "set -- $extra"
	# shellcheck disable=SC2086
	( "$EXE" --headless --stop-at-frame "$stop" $SIMARGS "$@" \
		--screenshot "$stop" --screenshot-prefix "$OUT/$name" --ascii-end \
		> "$OUT/$name.log" 2>&1 ) &
	pids+=($!)
	names+=("$name")
done

for p in "${pids[@]}"; do wait "$p"; done

fail=0
printf "%-10s %-6s %-9s %s\n" TEST SCREEN IMAGE NOTES
for t in "${TESTS[@]}"; do
	IFS='|' read -r name stop extra expect <<<"$t"
	selected "$name" || continue
	log="$OUT/$name.log"
	shot=$(printf "%s/%s_frame_%04d.png" "$OUT" "$name" "$stop")
	notes=""

	screen=ok
	if [ -n "$expect" ]; then           # bash 3.2: an empty array is "unbound" under set -u
		IFS=';' read -r -a strings <<<"$expect"
		for s in "${strings[@]}"; do
			if ! grep -qF -- "|$s" "$log"; then screen=FAIL; notes="$notes missing \"$s\";"; fi
		done
	else
		screen=-
	fi

	image=ok
	if [ ! -f "$shot" ]; then
		image=FAIL; notes="$notes no screenshot;"
	elif [ -n "${BLESS:-}" ]; then
		cp "$shot" "$REF/$name.png"; image=blessed
	elif [ ! -f "$REF/$name.png" ]; then
		image=new
	elif ! cmp -s "$shot" "$REF/$name.png"; then
		image=CHANGED; notes="$notes differs from $REF/$name.png;"
	fi

	[ "$screen" = FAIL ] && fail=1
	[ "$image" = FAIL ] || [ "$image" = CHANGED ] && fail=1
	notes="$notes $(grep -o 'Finished at frame.*' "$log" | sed 's/, active.*//')"
	printf "%-10s %-6s %-9s %s\n" "$name" "$screen" "$image" "$notes"
done

exit $fail
