////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.x.x
// File Name:		config.v
//
// CoCo3 in an FPGA
//
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 5.x
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
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// MISTer Conversion by Stan Hodge and Alan Steremberg (& Gary Becker)
// stan.pda@gmail.com
// 
////////////////////////////////////////////////////////////////////////////////

// This file is a configuration definition file.  The CoCo3FPGA for MiSTer source files
// can be built into multiple objects which have mutually exclusive features.

//	The debug value holds upto 8 feature settings [1 per bit] - when Config_Debug is set this appears at FFF1
`define	Config_Debug
`define Config_Debug_Value (`config_value_1 + `config_value_2 + `config_value_3 + `config_value_4 + `config_value_5 + `config_value_6 + `config_value_7 + `config_value_8)
`define Config_Debug_FLAG	8'h55
// Feature list - note the support area below needs editing for debug support...
///////////////////////////////////////////////////////////////////////////////////////////////////////////
`define CoCo3_Horz_INT_FIX	8'h01		// Connection of the horz int to the Mister CoCo3 V5 rasterizer

`define CoCo3_Vert_INT_FIX	8'h02		// Connection of the vert int to the Mister CoCo3 V5 rasterizer



///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	This is support info to create the Config_Debug_Value referenced above
`ifdef CoCo3_Horz_INT_FIX
	`define config_value_1 `CoCo3_Horz_INT_FIX
`else
	`define config_value_1 8'h00
`endif

`ifdef CoCo3_Vert_INT_FIX
	`define config_value_2 `CoCo3_Vert_INT_FIX
`else
	`define config_value_2 8'h00
`endif

`ifdef NOT_DEFINED_YET
	`define config_value_3 `NOT_DEFINED_YET
`else
	`define config_value_3 8'h00
`endif

`ifdef NOT_DEFINED_YET
	`define config_value_4 `NOT_DEFINED_YET
`else
	`define config_value_4 8'h00
`endif

`ifdef NOT_DEFINED_YET
	`define config_value_5 `NOT_DEFINED_YET
`else
	`define config_value_5 8'h00
`endif

`ifdef NOT_DEFINED_YET
	`define config_value_6 `NOT_DEFINED_YET
`else
	`define config_value_6 8'h00
`endif

`ifdef NOT_DEFINED_YET
	`define config_value_7 `NOT_DEFINED_YET
`else
	`define config_value_7 8'h00
`endif

`ifdef NOT_DEFINED_YET
	`define config_value_8 `NOT_DEFINED_YET
`else
	`define config_value_8 8'h00
`endif

