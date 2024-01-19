////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.x.x
// File Name:		config_inc.v
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

// This file is a configuration definition include file.  The CoCo3FPGA for MiSTer source files
// can be built into multiple objects which have mutually exclusive features.

`define Config_Debug_Value (`config_num_1 | `config_num_2 | `config_num_3 | `config_num_4 | `config_num_5 | `config_num_6 | `config_num_7 | `config_num_8)
`define Config_Debug_FLAG	8'h55
`define FEATURE_1 8'h01
`define FEATURE_2 8'h02
`define FEATURE_3 8'h04
`define FEATURE_4 8'h08
`define FEATURE_5 8'h10
`define FEATURE_6 8'h20
`define FEATURE_7 8'h40
`define FEATURE_8 8'h80
`define config_num_1 8'h00
`define config_num_2 8'h00
`define config_num_3 8'h00
`define config_num_4 8'h00
`define config_num_5 8'h00
`define config_num_6 8'h00
`define config_num_7 8'h00
`define config_num_8 8'h00

`define	set_feature(Feat_Name, Feat_Mask) \
`define Feat_Name \
`ifndef config_value_1 \
	`define config_value_1 Feat_Mask \
	`define config_num_1 Feat_Mask \
`else \
	`ifndef config_value_2 \
		`define config_value_2 Feat_Mask \
		`define config_num_2 Feat_Mask \
	`else \
		`ifndef config_value_3 \
			`define config_value_3 Feat_Mask \
			`define config_num_3 Feat_Mask \
		`else \
			`ifndef config_value_4 \
				`define config_value_4 Feat_Mask \
				`define config_num_4 Feat_Mask \
			`else \
				`ifndef config_value_5 \
					`define config_value_5 Feat_Mask \
					`define config_num_5 Feat_Mask \
				`else \
					`ifndef config_value_6 \
						`define config_value_6 Feat_Mask \
						`define config_num_6 Feat_Mask \
					`else \
						`ifndef config_value_7 \
							`define config_value_7 Feat_Mask \
							`define config_num_7 Feat_Mask \
						`else \
							`ifndef config_value_8 \
								`define config_value_8 Feat_Mask \
								`define config_num_8 Feat_Mask \
							`endif \
						`endif \
					`endif \
				`endif \
			`endif \
		`endif \
	`endif \
`endif
