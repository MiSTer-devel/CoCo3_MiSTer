#============================================================================
#  CoCo3 Verilator simulation
#
#  Same layout as the FM-7 and Apple-IIgs sims: sim.v stands in for CoCo3.sv,
#  sim/ is the shared ImGui/SDL framework, and one binary runs either windowed
#  or with --headless.
#
#    make            build ./obj_dir/Vemu
#    make run        build and launch the windowed sim
#    make headless   build and boot to BASIC headless, screenshot at the end
#    make test       build and run the headless smoke test (run_tests.sh)
#    make lint       elaborate the design only
#    make mem        regenerate rtl/*.mem from the VHDL/MIF sources
#    make clean
#
#  No ghdl step. The build uses the Verilog cycle-accurate 6809 (mc6809glb.v,
#  selected by CoCo3_CYC_ACC_6809 in rtl/config.sv), and the VHDL entities it
#  does instantiate -- ROMs, RAMs, the font -- are converted by hand in rtl/:
#
#    rtl/rom/coco_rom_32K.vhd, coco_rom_8K.vhd, coco_rom_cart.vhd,
#    coco_rom_16.vhd, coco3_char_rom.vhd          -> rtl/coco_rom.v
#    rtl/sram/coco_ram.vhd, coco_vid_ram_buf.vhd  -> rtl/coco_sram.v
#
#  Quartus-only pieces are replaced as well: rtl/VDAC.v (altsyncram) by
#  rtl/VDAC.v here, rtl/sdram/sdram2.sv by rtl/sdram2.sv here (same controller,
#  chip model instead of pins), and the PLL by clocks driven from sim_main.
#============================================================================

V     = verilator
RTL   = ../rtl
TOP   = --top-module emu

# Verilator 5 demands --no-timing for the cosmetic `#` delays; 4.x rejects the
# flag. Same probe as the FM-7 Makefile.
VERILATOR_MAJOR := $(shell verilator --version 2>/dev/null | sed -n 's/^Verilator \([0-9][0-9]*\).*/\1/p')
NO_TIMING       := $(if $(filter 4,$(VERILATOR_MAJOR)),,--no-timing)

# -Wno-PROCASSWIRE: coco3fpga.sv and fdc.sv declare a number of registers as
# `wire` and assign them in always blocks (Build_Info, VMA, PIX_CLK_D, the $FF40
# latch, ...). Quartus accepts that and so does Verilator once the check is
# waived; the RTL is left as it is.
V_DEFINE = +define+SIMULATION=1 -Wno-PROCASSWIRE \
	--timescale-override 1ps/1ps -Wno-TIMESCALEMOD -Wno-fatal \
	$(NO_TIMING) --converge-limit 6000 \
	-I$(RTL)

# VCD tracing: `make clean && make TRACE=1`, then run with --vcd <file> and a
# --trace-from/--trace-until window (a 114 MHz design dumps ~1 GB a frame).
ifeq ($(TRACE),1)
V_DEFINE += --trace
CXX_DEFINE += -DVM_TRACE_VCD=1
else
CXX_DEFINE += -DVM_TRACE_VCD=0
endif

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S), Darwin)
	LIBS += -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo `sdl2-config --libs`
	LIBS += -L/usr/local/lib -L/opt/local/lib -L/opt/homebrew/lib
	CXXFLAGS += `sdl2-config --cflags`
	CXXFLAGS += `sdl2-config --cflags | sed 's|include/SDL2|include/|'`
	CXXFLAGS += -I/usr/local/include -I/opt/local/include -I/opt/homebrew/include
endif

ifeq ($(UNAME_S), Linux)
	LIBS += -lGL -ldl `sdl2-config --libs`
	CXXFLAGS += `sdl2-config --cflags`
endif

ifeq ($(findstring MINGW,$(UNAME_S)),MINGW)
	LIBS += -lgdi32 -lopengl32 -limm32 `pkg-config --static --libs sdl2`
	CXXFLAGS += `pkg-config --cflags sdl2`
endif

CC_OPT    = -O2
V_OPT     = -O3 --x-assign fast --x-initial fast --noassert
CXXFLAGS += $(CC_OPT) $(CXX_DEFINE) -I../sim/imgui -I../sim -I.. -g
LDFLAGS   = $(LIBS)
EXE       = ./obj_dir/Vemu

V_SRC = \
	sim.vlt \
	sim.v \
	rtl/sdram2.sv \
	rtl/coco_rom.v \
	rtl/coco_sram.v \
	rtl/VDAC.v \
	../sys/hps_io.sv \
	$(RTL)/coco3fpga.sv \
	$(RTL)/EE_Cold_Bt.v \
	$(RTL)/cassette.v \
	$(RTL)/square_gen.v \
	$(RTL)/AMW.v \
	$(RTL)/rtc.sv \
	$(RTL)/fdc.sv \
	$(RTL)/wd1793.sv \
	$(RTL)/sdc.sv \
	$(RTL)/sdc_top.sv \
	$(RTL)/Auto_Run.sv \
	$(RTL)/ps2_mouse.v \
	$(RTL)/coco_mem_fetch.sv \
	$(RTL)/Cassette_Write.sv \
	$(RTL)/cocokey.v \
	$(RTL)/PS2_Key/ps2_keyboard.v \
	$(RTL)/UART_6551/uart_6551.v \
	$(RTL)/UART_6551/6551tx.v \
	$(RTL)/UART_6551/6551rx.v \
	$(RTL)/mc6809glb/mc6809glb.v \
	$(RTL)/Mister_Video.v \
	$(RTL)/Mister_Video_GIMEX.v

C_SRC = \
	sim_main.cpp dis6809.cpp serial.cpp \
	sim/sim_bus.cpp sim/sim_clock.cpp sim/sim_console.cpp sim/sim_video.cpp \
	sim/sim_blkdevice.cpp sim/sim_input.cpp sim/sim_audio.cpp \
	sim/imgui/imgui_impl_sdl.cpp sim/imgui/imgui_impl_opengl2.cpp \
	sim/imgui/imgui_draw.cpp sim/imgui/imgui_widgets.cpp sim/imgui/imgui_tables.cpp \
	sim/imgui/imgui.cpp sim/imgui/ImGuiFileDialog.cpp \
	sim/imgui/implot.cpp sim/imgui/implot_items.cpp

VOUT = obj_dir/Vemu.cpp

all: $(EXE)

$(VOUT): $(V_SRC) Makefile
	$V -cc $(V_OPT) -LDFLAGS "$(LDFLAGS)" -exe --Mdir ./obj_dir \
		$(V_DEFINE) $(TOP) -CFLAGS "$(CXXFLAGS)" $(V_SRC) $(C_SRC)

$(EXE): $(VOUT) $(C_SRC) sim/*.h dis6809.h serial.h
	(cd obj_dir; $(MAKE) -f Vemu.mk OBJCACHE= OPT_FAST="-O2" OPT_SLOW="-O0" OPT_GLOBAL="-O2")

lint:
	$V --lint-only $(V_DEFINE) -Wno-WIDTH $(TOP) $(V_SRC)

mem:
	python3 gen_mem.py

run: all
	$(EXE)

headless: all
	$(EXE) --headless --stop-at-frame 150 --screenshot 150

test: all
	./run_tests.sh

clean:
	rm -rf obj_dir

.PHONY: all lint mem run headless test clean

# Disassembler self-check. Standalone -- no Verilator, no core.
distest: dis6809_test.cpp dis6809.cpp dis6809.h
	mkdir -p obj_dir && c++ -O1 -o obj_dir/distest dis6809_test.cpp dis6809.cpp -I. && ./obj_dir/distest

.PHONY: distest
