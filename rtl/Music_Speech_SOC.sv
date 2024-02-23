////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.x.x
// File Name:		Music_Speech.sv
//
// CoCo3 in an FPGA
//
////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
//
// Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
//
////////////////////////////////////////////////////////////////////////////////
// Stan Hodge
//
//	Music_Speech.sv by Stan Hodge 02/16/24
////////////////////////////////////////////////////////////////////////////////

module Music_Speech_SOC(
input				RESET_N,
input				CLKIN,
input				CLK_1_78,

input				INT1_N,
input				INT3_N,

output		[7:0]	PORT_A,
output		[7:0]	PORT_B,
output		[7:0]	PORT_C,
output		[7:0]	PORT_D_OUT,
input		[7:0]	PORT_D_IN
);

//////////////////////////////////////////////////////////////////////////////////
// 09 Processor

wire			VMA, RW_N, HALT, CPU_IRQ_N, CPU_FIRQ_N, NMI_09;
wire	[15:0]	ADDRESS;
wire	[7:0]	DATA_IN, DATA_OUT;

// CPU section copyrighted by John Kent
cpu09 GLBCPU09(
	.clk(CLKIN),
	.rst(!RESET_N),
	.vma(VMA),
	.addr(ADDRESS),
	.rw(RW_N),
	.data_in(DATA_IN),
	.data_out(DATA_OUT),
	.halt(HALT),
	.hold(hold | ~cpu_ena),		// ???
	.irq(!CPU_IRQ_N),
	.firq(!CPU_FIRQ_N),
	.nmi(NMI_09)
);



endmodule
