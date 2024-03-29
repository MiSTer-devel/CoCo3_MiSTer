--//////////////////////////////////////////////////////////////////////////////
-- Project Name:	CoCo3FPGA Version Mister
-- File Name:		coco_rom_16.vhd
--
-- CoCo3 in an FPGA
--
--//////////////////////////////////////////////////////////////////////////////
--
--
--//////////////////////////////////////////////////////////////////////////////
--
-- Color Computer 3 compatible system on a chip
--
--
-- Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--																		   
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://groups.yahoo.com/group/CoCo3FPGA
--
-- File history :
--
--//////////////////////////////////////////////////////////////////////////////
-- Gary Becker
-- gary_L_becker@yahoo.com
--//////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////
-- MISTer conversion work by Stan Hodge and Alan Steremberg



library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity COCO_ROM_16 is
  port (
--	Main CPU Port
    ADDR        : in    std_logic_vector(3 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of COCO_ROM_16 is

	type ROM_ARRAY is array(0 to 15) of std_logic_vector(7 downto 0);
	signal ROM : ROM_ARRAY:= (
--	Clear $71 [Warm Start Flag]
    x"80",x"07",x"00",x"71",x"00", 	-- valid, nc, nc, nc, nc, nc, nc, a24
									-- a23, a22, a21, a20, a19, a18, a17, a16
									-- a15, a14, a13, a12, a11, a10, a09, a08
									-- a07, a06, a05, a04, a03, a02, a01, a00
									-- d07, d06, d05, d04, d03, d02, d01, d00

--	Set $C000 <- $55 [Clear D in DK identifier in rom]
    x"80",x"07",x"C0",x"00",x"55",	-- valid, nc, nc, nc, nc, nc, nc, a24
									-- a23, a22, a21, a20, a19, a18, a17, a16
									-- a15, a14, a13, a12, a11, a10, a09, a08
									-- a07, a06, a05, a04, a03, a02, a01, a00
									-- d07, d06, d05, d04, d03, d02, d01, d00

--	Clear $72 [Warm Start Jump]
    x"80",x"07",x"00",x"72",x"00", 	-- valid, nc, nc, nc, nc, nc, nc, a24
									-- a23, a22, a21, a20, a19, a18, a17, a16
									-- a15, a14, a13, a12, a11, a10, a09, a08
									-- a07, a06, a05, a04, a03, a02, a01, a00
									-- d07, d06, d05, d04, d03, d02, d01, d00
	
	x"00"							-- valid, nc, nc, nc, nc, nc, nc, a24
	);

begin

	DATA <= ROM(to_integer(unsigned(ADDR)));

end RTL;
