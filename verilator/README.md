# CoCo3 Verilator simulation

Runs the core on the host, windowed (ImGui + SDL2) or headless, so you can boot
it, type at it, mount disks, screenshot it and trace the 6809, without a
DE10-Nano or a Quartus build.

It uses the same framework as the FM-7 and Apple-IIgs sims: `sim.v` stands in
for `CoCo3.sv`, `sim/` is the shared ImGui/SDL harness (`sim_bus`, `sim_video`,
`sim_input`, `sim_blkdevice`, ...), and one binary does both modes.

## Build and run

```sh
cd verilator
make                 # -> ./obj_dir/Vemu
make run             # windowed
make headless        # boot headless to frame 150, screenshot
make test            # headless smoke tests (run_tests.sh)
make lint            # elaborate only
```

Needs Verilator 5 (built and tested with 5.044), SDL2, and Python 3 for the
generators (`brew install verilator sdl2`). **Run the binary from this
directory**: the ROM defaults and the `$readmemh` images under `rtl/` are
relative paths.

### ROMs

The core loads its ROMs over ioctl at start-up, the way Main_MiSTer does, so
the sim needs the same two files the MiSTer SD card has in `games/CoCo3/`:

| file | contents | ioctl index |
|---|---|---|
| `roms/boot0.rom` | CoCo 3 ROM (32K, `coco3.rom`) | 0 |
| `roms/boot1.rom` | Disk BASIC 1.1 (8K, `disk11.rom`) | 64 |

They are not in git (`roms/*.rom` is ignored). Copy them from your MiSTer, or
from ToolShed's `cocoroms/` build. `--rom` / `--disk-rom` point elsewhere.

## Headless

```sh
# Boot and print the text screen
./obj_dir/Vemu --headless --stop-at-frame 150 --ascii-end

# Type at BASIC; {RETURN} or \n for Enter, {BREAK}, {CLEAR}, {UP}...
./obj_dir/Vemu --headless --stop-at-frame 260 --type '140:PRINT 2+2\n' --ascii-end

# Floppy in drive 0 (selects MPI slot 4), load and run a program
./obj_dir/Vemu --headless --disk tests/hello.dsk --stop-at-frame 420 \
    --type '140:RUN"HELLO\n' --screenshot 420

# Disassembly trace of frames 10-11
./obj_dir/Vemu --headless --stop-at-frame 11 --trace-cpu trace.txt --trace-from 10
```

`--help` lists everything: cartridge (`--cart`), cassette (`--cas`), CoCoSDC
(`--sdc`), memory size, turbo speed, artifact mode, `--frame-log` (per-frame
framebuffer hash + instruction count), `--trace-bus`, `--vcd`.

BASIC's banner appears around frame 130. Most of that is the core itself:
`coco3fpga.sv` holds `RESET_N` for 143 ms and `CPU_RESET` for 286 ms after
power-on, and the first frame only appears once the video timing leaves reset.
Type from frame 140 on.

`--ascii` prints the 32×16 VDG screen at `$0400` as the CPU last wrote it (from
a shadow of the CPU bus). That is what the tests judge. It does not follow
`WIDTH 40/80` or graphics modes; use a screenshot for those.

Typed keys are held 2 frames with a 2-frame gap, plus 30 frames after each
RETURN (`--key-hold`, `--key-gap`, `--return-gap`). The CoCo has no type-ahead:
while BASIC runs a line it does not scan the keyboard, so keys pressed then are
lost, on the real machine as well as here.

### Tests

`./run_tests.sh [name...]` runs these in parallel (about 8 minutes in all):

| test | does | judged on |
|---|---|---|
| `boot` | power on, wait for the banner | text screen: `DISK EXTENDED COLOR BASIC 2.1`, `OK` |
| `keyboard` | `PRINT 2+2` | text screen: ` 4` |
| `disk` | `RUN"HELLO` from `tests/hello.dsk` | text screen: `HELLO FROM DISK`, ` 42` |
| `width80` | `WIDTH 80`, then print | screenshot (GIME 80-column text) |
| `hscreen` | `HSCREEN 2`, `HCIRCLE`, `HLINE ... B` | screenshot (GIME 320x192 graphics) |

Every test's final screenshot is compared byte for byte with `test-ref/`. The
sim is deterministic, so a changed image means the RTL or harness changed what
is drawn. After an intended change, `BLESS=1 ./run_tests.sh` records new
references. Output goes to `test-out/`.

### Speed

About **1.2 simulated frames per second** (boot to BASIC ~125 s on an
Apple-silicon Mac), or ~1.6 fps with `--fast-clocks` (~77 s).

Where the time goes, and the two speed-ups made:

- The CoCo clocks are 114.5 MHz (SDRAM controller, the `data_ready` latch,
  the video line fetcher), 57.3 MHz `clk_sys` (everything else: 48 negedge
  and 10 posedge blocks), 14.3 MHz pixel clock, and CLK_50M for the RTC/UART.
  CLK_28 is unused.
- `status` (the OSD word) used to be a top-level input. It feeds the video
  pixel mux, so Verilator re-evaluated that mux on every eval, about 20% of the
  run time. `sim.v` now registers it, as `hps_io` does on the FPGA.
- `--fast-clocks` steps per half-period of `clk_sys` and runs the 114 MHz
  domain at 57 MHz, halving the evals. At normal CPU speeds an SDRAM access
  still finishes well inside a CPU cycle. All five tests give byte-identical
  screenshots and identical instruction counts either way
  (`SIMARGS=--fast-clocks ./run_tests.sh`). High turbo speeds (6 `clk_sys`
  per CPU cycle at 9.54 MHz) and video fetch bandwidth are where it could
  differ; use the default when timing is the question.

## Serial (RS-232 Pak / FujiNet)

The core's only UART is the RS-232 Pak, a `glb6551` at `$FF68-$FF6B`; on
MiSTer its pins are the `UART_*` signals the FujiNet daemon reaches as
`/dev/ttyS1`. The sim works on those pins, not on the registers:

- **TXD is decoded** at whatever rate the 6551 is programmed for, and every
  byte is printed: `SERIAL TX <frame> <hex> |ascii|`.
- **RXD is driven** from a pty (`--serial-pty`, name printed at start) or from
  `--serial-send FRAME:HEX...`, at the far end's rate: `--serial-baud N`, or by
  default the 6551's transmit rate.
- `--trace-acia` logs every CPU access to `$FF68-$FF6B`, and whether it
  actually reached the chip. The exit summary counts bytes, accesses and
  undecoded accesses, and warns on a receive-clock mismatch.
- The windowed build has a Serial window with the same information.
- `tests/dwserver.py PTY DISK...` is a minimal DriveWire 3 server (stdlib only)
  to stand in for FujiNet: `READEX`, `WRITE`, `TIME`, `DWINIT`, ...

`tests/dw_boot.sh CART DISK STOP [sim args]` wires the two together:

```sh
tests/dw_boot.sh ../../FujiNet_MiSTer/roms/HDBDW3S3.CCC tests/hello.dsk 350 \
    --type '140:RUN"HELLO\n'
```

That boots HDB-DOS over DriveWire (reads LSN 0 and the directory), then
`RUN"HELLO` loads and runs the program from the served image, about 5 minutes.

The sim runs ~50x slower than real time, so the far end sees roughly 400 baud
of real throughput whatever rate is programmed. A real FujiNet may time out
where `dwserver.py` does not.

### FujiNet on this core: what was wrong, and the fix

Tested with FujiNet_MiSTer's carts and the real FujiNet daemon (FujiNet-PC
built for `COCO`, run with FujiNet_MiSTer's `fnconfig.ini` pointed at the sim's
pty; `tests/fujinet_boot.sh`).

1. **The 6551 was unreachable with a cart in slot 3.** `coco3fpga.sv` decoded
   `$FF68-$FF6B` only when the Multi-Pak I/O select was slot 1
   (`MPI_SCS == 0`), and the OSD offers only slots 2-4. HDB-DOS programmed the
   chip and polled status forever. It read `$AA` from an empty bus, stopped at
   `HDB-DOS 1.5 SY6551 COCO 3`, and transmitted nothing. On a real CoCo the
   SCS line covers only `$FF40-$FF5F`, and the RS-232 Pak decodes `$FF68` from
   the address bus, so it works in any slot. **Fix:** `RS232_EN` no longer
   looks at `MPI_SCS`.
2. **The 19,200 cart received at 115,200.** `HDBDW3L3_19200.CCC` writes
   control `$0F`. Bit 4 = 0 selects the "external" receive clock, which
   `uart_6551.v` tied to the 1.8475 MHz enable, i.e. 115,200 baud. The cart
   transmitted at 19,200 and received garbage: FujiNet logged `Checksum error:
   expected 65280, got 57344`. **Fix:** the receiver is clocked from the baud
   generator (`RX_CLK = TX_CLK`). That is unchanged for control `$1x` and for
   baud select 0.

With both fixes, the L3 cart at 19,200 (the MiSTer configuration) boots from the
real FujiNet daemon with no checksum errors, and gets to FujiNet's CONFIG
splash. The S3 cart (115,200) reaches the CONFIG host-slots screen.

On the FPGA the rest of the path already works. `sys_top.v` wires the core's
`UART_*` pins straight to the HPS UART (`/dev/ttyS1`), whatever the OSD UART
mode. The 6551 only transmits while CTS is low, and CTS is the HPS UART's RTS.
FujiNet-PC turns off `CRTSCTS` and leaves RTS as Linux sets it on open
(asserted), so that holds while `start_fujinet.sh` has the port open.

**Sim-only caveat:** FujiNet times out reads after 500 ms of wall-clock time,
and the sim runs ~50x slower than real time. The CoCo cannot return a sector's
checksum in time, and FujiNet logs `got 65535`. These tests used a FujiNet
build with `.readTimeout(120000)` in `lib/bus/drivewire/drivewire.cpp`. On
hardware the stock value is fine.

## Windowed

`make run`. Windows: the video, a CPU/GIME inspector (registers, `$FF90`, a
live disassembly from the bus shadow), Control (run/pause/step, reset, cold
boot, screenshot, the OSD options, cart/cassette/floppy/SDC file dialogs) and a
console. Keys go to the CoCo from the host keyboard through the same PS/2 path
as on hardware.

## What is simulated, and what is replaced

`sim.v` wires the core the way `CoCo3.sv` does, including the OSD `status` word
decode, the joystick centring and the cassette RAM. The replacements:

| on MiSTer | here | why |
|---|---|---|
| PLL (114.545/57.27/28.64/14.32 MHz) | clocks from `sim_main.cpp` | all phase 0, exact /2 /4 /8, so they are derived from one counter and all rise in the same eval |
| `rtl/sdram/sdram2.sv` | `rtl/sdram2.sv` | same controller logic, plus a CAS-3, burst-2 SDR chip model in place of the `SDRAM_*` pins |
| `hps_io` keyboard | `sys/hps_io.sv`'s own `ps2_device` | `ps2_key` events are fed into the real PS/2 serializer at `PS2DIV(2400)`, so `cocokey.v` sees the same serial stream |
| `rtl/VDAC.v` (altsyncram) | `rtl/VDAC.v` | registered dual-port RAM, preloaded from `VDAC.mif` |
| VHDL ROM/RAM entities | `rtl/coco_rom.v`, `rtl/coco_sram.v` | Verilog conversions, see below |

### VHDL to Verilog

The build uses the Verilog cycle-accurate 6809 (`rtl/mc6809glb/mc6809glb.v`),
because `rtl/config.sv` defines `CoCo3_CYC_ACC_6809`. The VHDL CPU
(`rtl/CPU09/cpu09*.vhd`) is not instantiated, so nothing needs ghdl. The VHDL
the core does use was converted by hand, one module per entity with the same
names and ports:

| VHDL | Verilog |
|---|---|
| `rtl/rom/coco_rom_32K.vhd`, `coco_rom_8K.vhd`, `coco_rom_cart.vhd` | `rtl/coco_rom.v` (`COCO_ROM_32K`, `COCO_ROM_8K`, `COCO_ROM_CART`) |
| `rtl/rom/coco_rom_16.vhd` | `rtl/coco_rom.v` (`COCO_ROM_16`) |
| `rtl/rom/coco3_char_rom.vhd` | `rtl/coco_rom.v` (`coco3_Char_ROM`) + `rtl/coco3_char_rom.mem` |
| `rtl/sram/coco_ram.vhd`, `coco_vid_ram_buf.vhd` | `rtl/coco_sram.v` (`COCO_SRAM`, `COCO_VID_RAM_BUF`) |

`make mem` (`gen_mem.py`) regenerates `rtl/coco3_char_rom.mem` from the font
table in the VHDL and `rtl/vdac.mem` from `rtl/VDAC.mif`.

## Traps found while bringing it up

**Verilator re-runs block-local initialisers.** A variable declared with an
initialiser inside an `always` block, like `reg [4:0] state = STATE_STARTUP;` in
`sdram2.sv`, is re-initialised every time the block runs under Verilator 5.044.
It is not a one-time static. The SDRAM controller was pinned in
`STATE_STARTUP`, and the CPU stalled on its first RAM access. The sim copy
hoists those registers to module scope. Look for this in any other core
(`make lint` flags them as `IMPLICITSTATIC`).

**Quartus powers async-set registers up at 1.** A register with an asynchronous
set is built with NOT-gate push-back, so it starts at 1 on the FPGA and at 0
here. `mc6809x`'s `NMILatched` (active low) is one of them. At 0 the CPU took a
phantom NMI on its first instruction. `sim.v` sets it to 1 in an `initial`
block, which models the FPGA's power-up state.

**`// verilator ...` in a comment is a pragma.** A comment line that *starts*
with the word "verilator" is parsed as a directive and fails the build with
`BADVLTPRAGMA`.

**`rtl/wd1793.sv`:** `spt_addr` and `buff_wr` were declared inside `generate`
blocks but assigned outside them. Quartus accepts that. Verilator rejects
`spt_addr`, and silently makes `buff_wr` a separate implicit net, so the
sector-buffer write strobe would never reach the RAM. Both are now declared at
module scope. FM-7 made the same fix to its copy of the file. There is no
behavioural change on the FPGA.

The core also declares some registers as `wire` and assigns them in `always`
blocks (`Build_Info`, `VMA`, `PIX_CLK_D`, the `$FF40` latch in `fdc.sv`).
Quartus accepts it. The Makefile passes `-Wno-PROCASSWIRE` rather than editing
the RTL.

## Files

```
Makefile            build, lint, test
sim.v               emu top: CoCo3.sv without sys/, plus debug taps
sim_main.cpp        clocks, options, headless loop, ImGui windows
serial.{cpp,h}      6551 line model: TXD decoder, RXD driver, pty bridge
sim.vlt             Verilator config (forceable net for --acia-any-slot)
dis6809.{cpp,h}     6809 disassembler (shared with FM-7)
run_tests.sh        smoke tests, judged on text screen + screenshot
gen_mem.py          VHDL/MIF -> rtl/*.mem
rtl/                Verilog conversions and sim replacements
sim/                shared ImGui/SDL framework
tests/              make_test_disk.py -> hello.dsk (Disk BASIC image),
                    dwserver.py (minimal DriveWire 3 server)
test-ref/           blessed screenshots for run_tests.sh
```
