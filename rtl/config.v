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

`include "..\RTL\config_inc.v"

//	If defined the Config_Debug sets the FEATURE MASKS all OR'd together which appears on COCO space at FFF1 & (FFF0 = 0x55 as a debug flag)
`define	Config_Debug

// Feature list - note only FEATURE_1 - FEATURE_8 are supported
///////////////////////////////////////////////////////////////////////////////////////////////////////////
`set_feature(CoCo3_Horz_INT_FIX, FEATURE_1)			// Connection of the horz int to the Mister CoCo3 V5 rasterizer

//`set_feature(CoCo3_Vert_INT_FIX, FEATURE_2)		// Connection of the vert int to the Mister CoCo3 V5 rasterizer

`set_feature(CoCo3_CYC_ACC_6809, FEATURE_3)			// Use cycle accurate 6809

//`set_feature(CoCo3_sdc_override_size, FEATURE_4)	// Define static size value

//`set_feature(CoCo3_sdc_fix_os9_driver, FEATURE_5)	// fix sdc query disk size issue in llcocosdc driver in multipak enviroment

//`set_feature(CoCo3_disable_GART_in_GIMEX, FEATURE_6)// Disable GIMEX ram transfers [GIMEX detection in OS( EOU]

