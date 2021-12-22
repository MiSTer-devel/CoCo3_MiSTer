--//////////////////////////////////////////////////////////////////////////////
-- Project Name:	CoCo3FPGA Version 4.0
-- File Name:		coco_ram.vhd
--
-- CoCo3 in an FPGA
--
-- Revision: 4.0 07/10/16
--//////////////////////////////////////////////////////////////////////////////
--
-- CPU section copyrighted by John Kent
-- The FDC co-processor copyrighted Daniel Wallner.
-- SDRAM Controller copyrighted by XESS Corp.
--
--//////////////////////////////////////////////////////////////////////////////
--
-- Color Computer 3 compatible system on a chip
--
-- Version : 4.1.2
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
--  1.0			Full Release
--  2.0			Partial Release
--  3.0			Full Release
--  3.0.0.1		Update to fix DoD interrupt issue
--	3.0.1.0		Update to fix 32/40 CoCO3 Text issue and add 2 Meg max memory
--	4.0.X.X		Full Release
--	4.1.2.X		Fixed 6502 code for drivewire, removed timer, fixed 6551 baud 
--				rate (& DE2-115 compiler symbol)
--//////////////////////////////////////////////////////////////////////////////
-- Gary Becker
-- gary_L_becker@yahoo.com
--//////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////
-- DE2-115 Conversion by Stan Hodge
-- shodgefamily@yahoo.com
--//////////////////////////////////////////////////////////////////////////////
-- MISTer conversion work by Stan Hodge and Alan Steremberg


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity COCO_SRAM is
  port (
	CLK				: in	std_logic;
    ADDR        	: in    std_logic_vector(15 downto 0);
	R_W				: in	std_logic;
	DATA_I			: in	std_logic_vector(7 downto 0);
    DATA_O        	: out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of COCO_SRAM is

  type SRAM_ARRAY is array(0 to 65535) of std_logic_vector(7 downto 0);
  signal SRAM : SRAM_ARRAY;

begin

  P_SRAM : process(CLK,ADDR,R_W,DATA_I)
  begin
	if CLK'event and CLK='1' then
		if R_W = '0' then
    		SRAM(to_integer(unsigned(ADDR))) <= DATA_I;
		end if;
	end if;
  end process;

  DATA_O <= SRAM(to_integer(unsigned(ADDR)));

end RTL;
