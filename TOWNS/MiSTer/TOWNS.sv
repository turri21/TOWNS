//============================================================================
//  FM TOWNS
//
//  Port to MiSTer
//  Copyright (C) 2017,2020 Alexey Melnikov
//  Copyright (C) 2021 Puu
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,



	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign USER_OUT  = '1;

assign AUDIO_MIX = 0;
assign VGA_SL    = 0;
assign VGA_F1    = 0;
assign VGA_SCALER = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;

assign LED_USER  = ioctl_download & ~ldr_done;
assign LED_DISK  = {disk_led, sd_act};
assign LED_POWER = 0;
assign BUTTONS   = 0;
 
assign VIDEO_ARX = status[1] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[1] ? 8'd9  : 8'd3; 

`include "build_id.v" 
parameter CONF_STR = {
	"TOWNS;;",
	"-;",
	"O1,Aspect ratio,4:3,16:9;",
	"-;",
	"R2,Reset;",
	"OTV,DEBUG,off,memaccess,io_access,dma_access,interrupt,IO_and_DMA,none,on;",
//	"OT,SEEKWAIT,off,on;",
//	"OU,TXWAIT,off,on;",
	"-;",
	"S0,D88,FDD0;",
	"S1,D88,FDD1;",
	"S2,ISO,CD-ROM;",
	"S3,HDFH0 ,HDD;",
	"-;",
	"FS1,RAM,LOAD SRAM;",
	"R3,SAVE;",
	"O45,MOUSE CONNECT,OFF,PORT 1,PORT 2,FMR;",
	"RA,int0;",
	"RB,int1;",
	"RC,int2;",
	"RD,int3;",
	"RE,int4;",
	"RF,int5;",
	"RG,int6;",
	"RH,int7;",
	"RI,int8;",
	"RJ,int9;",
	"RK,inta;",
	"RL,intb;",
	"RM,intc;",
	"RN,intd;",
	"RO,inte;",
	"RP,intf;",
//	"O34,BOOT,FDD0,FDD1,HDD0,CD-ROM;",
//	"O5,HMA,INUSE,USE;",
//	"O9B,EMS(MB),0M,1M,2M,3M,4M,5M,6M,7M;",
//	"O68,EMS(kB),0k,128k,256k,384k,512k,640k,768k,896k;",
//	"OFH,RAMDISK(MB),0M,1M,2M,3M,4M,5M,6M,7M;",
//	"OCE,RAMDISK(kB),128k,256k,384k,512k,640k,768k,896k;",
	"J,A,B,C,X,Y,Z,Run,Select;",
	"V,v",`BUILD_DATE
};

/////////////////  CLOCKS  ////////////////////////

wire clk_ram, clk_mem, clk_sys, clk_vid0, clk_vid1, clk_vid2, clk_vid3;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_ram),
	.outclk_2(clk_mem),
	.outclk_3(clk_vid),
	.locked(pll_locked)
);

altddio_out
#(
	.extend_oe_disable("OFF"),
	.intended_device_family("Cyclone V"),
	.invert_output("OFF"),
	.lpm_hint("UNUSED"),
	.lpm_type("altddio_out"),
	.oe_reg("UNREGISTERED"),
	.power_up_high("OFF"),
	.width(1)
)
sdramclk_ddr
(
	.datain_h(1'b0),
	.datain_l(1'b1),
	.outclock(clk_ram),
	.dataout(SDRAM_CLK),
	.aclr(1'b0),
	.aset(1'b0),
	.oe(1'b1),
	.outclocken(1'b1),
	.sclr(1'b0),
	.sset(1'b0)
);

/////////////////  HPS  ///////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire [15:0] joystick_0, joystick_1;

wire  [11:0] joyA = ~{joystick_0[11:4],joystick_0[0],joystick_0[1],joystick_0[2],joystick_0[3]};
wire  [11:0] joyB = ~{joystick_1[11:4],joystick_1[0],joystick_1[1],joystick_1[2],joystick_1[3]};

wire        ioctl_download;
wire        ioctl_upload;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire        ioctl_rd;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

wire        ps2_kbd_clk_out;
wire        ps2_kbd_data_out;
wire        ps2_kbd_clk_in;
wire        ps2_kbd_data_in;
wire        ps2_mouse_clk_out;
wire        ps2_mouse_data_out;
wire        ps2_mouse_clk_in;
wire        ps2_mouse_data_in;

wire  [31:0] sd_lba[4];
wire   [3:0] sd_rd;
wire   [3:0] sd_wr;

wire  [3:0] sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din[4];
wire        sd_buff_wr;
//wire [15:0] sd_req_type = 0;
wire  [3:0] img_mounted;
wire  [3:0] img_readonly;
wire [63:0] img_size;

wire [65:0] ps2_key;
wire [64:0] sysrtc;
wire			vclk;

hps_io #(.CONF_STR(CONF_STR), .PS2DIV(600), .PS2WE(1), .VDNUM(4)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

//	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	
	.TIMESTAMP(TIMESTAMP),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
//	.sd_req_type(sd_req_type),
 
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_rd(ioctl_rd),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_wait(ldr_wr),
	.ioctl_upload_req(ioctl_upload_req),

	.ps2_kbd_clk_out(ps2_kbd_clk_out),
	.ps2_kbd_data_out(ps2_kbd_data_out),
	.ps2_kbd_clk_in(ps2_kbd_clk_in),
	.ps2_kbd_data_in(ps2_kbd_data_in),
	.ps2_mouse_clk_out(ps2_mouse_clk_out),
	.ps2_mouse_data_out(ps2_mouse_data_out),
	.ps2_mouse_clk_in(ps2_mouse_clk_in),
	.ps2_mouse_data_in(ps2_mouse_data_in),

	.ps2_key(ps2_key),
	
	.RTC(sysrtc),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);

/////////////////  RESET  /////////////////////////

reg reset_n = 0;
always @(posedge clk_sys) begin
	reg old_download;
	
	old_download <= ioctl_download;
	if(~old_download & ioctl_download) reset_n <= 1;
end

wire reset = buttons[1] | status[2];
///////////////////////////////////////////////////


assign CLK_VIDEO = clk_vid;
assign AUDIO_S = 1;
wire [2:0] debclk = status[31:29];
wire fdd_seekwait = status[29];
wire fdd_txwait = status[30];
wire ioctl_upload_req;
wire cmosstore = status[3];
wire [1:0] mousecon = status[5:4];
//wire cmos_hma = status[5];
//wire [5:0] cmos_ems = status[11:6];
//wire [5:0] cmos_ramdisk = status[17:12];

wire disk_led;
wire [15:0] fint = status[25:10];


TOWNSMiSTer towns_top
(
	.sysclk(clk_sys),
	.ramclk(clk_mem),
	.vidclk(clk_vid),
	.plllock(pll_locked),
	
	.sysrtc(sysrtc),

	.pMemCke(SDRAM_CKE),
	.pMemCs_n(SDRAM_nCS),
	.pMemRas_n(SDRAM_nRAS),
	.pMemCas_n(SDRAM_nCAS),
	.pMemWe_n(SDRAM_nWE),
	.pMemUdq(SDRAM_DQMH),
	.pMemLdq(SDRAM_DQML),
	.pMemBa1(SDRAM_BA[1]),
	.pMemBa0(SDRAM_BA[0]),
	.pMemAdr(SDRAM_A),
	.pMemDat(SDRAM_DQ),

	.INI_INDEX(ioctl_index),
	.INI_ADDR(ioctl_addr[20:0]),
	.INI_WDAT(ioctl_dout),
	.INI_OE(ioctl_download & ~ldr_done),
	.INI_WR(ldr_wr),
	.INI_ACK(ldr_ack),
	.INI_DONE(ldr_done),
	.INI_RDAT(ioctl_din),
	.INI_RD(ioctl_rd),
	.INI_ULREQ(ioctl_upload_req),
	.INI_UL(ioctl_upload),

	.pPs2Clkin(ps2_kbd_clk_out),
	.pPs2Clkout(ps2_kbd_clk_in),
	.pPs2Datin(ps2_kbd_data_out),
	.pPs2Datout(ps2_kbd_data_in),

	.pPmsClkin(ps2_mouse_clk_out),
	.pPmsClkout(ps2_mouse_clk_in),
	.pPmsDatin(ps2_mouse_data_out),
	.pPmsDatout(ps2_mouse_data_in),

	.pJoyA(joyA),
	.pJoyB(joyB),

	.mist_mounted(img_mounted),
	.mist_readonly(img_readonly),
	.mist_imgsize(img_size),

	.mist_lba0(sd_lba[0]),
	.mist_lba1(sd_lba[1]),
	.mist_lba2(sd_lba[2]),
	.mist_lba3(sd_lba[3]),
	.mist_rd(sd_rd),
	.mist_wr(sd_wr),
	.mist_ack(sd_ack),

	.mist_buffaddr(sd_buff_addr),
	.mist_buffdout(sd_buff_dout),
	.mist_buffdin0(sd_buff_din[0]),
	.mist_buffdin1(sd_buff_din[1]),
	.mist_buffdin2(sd_buff_din[2]),
	.mist_buffdin3(sd_buff_din[3]),
	.mist_buffwr(sd_buff_wr),

	.pLed(disk_led),
	.cmosstore(cmosstore),
	.debclk(debclk),
	.fdd_seekwait(fdd_seekwait),
	.fdd_txwait(fdd_txwait),
//	.cmos_hma(cmos_hma),
//	.cmos_ems(cmos_ems),
//	.cmos_ramdisk(cmos_ramdisk),
	.mousecon(mousecon),
	.fint(fint),

	.pVid_R(VGA_R),
	.pVid_G(VGA_G),
	.pVid_B(VGA_B),
	.pVid_HS(VGA_HS),
	.pVid_VS(VGA_VS),
	.pVid_EN(VGA_DE),
	.pVid_Clk(CE_PIXEL),

	.pSnd_L(AUDIO_L),
	.pSnd_R(AUDIO_R),
	
	.rstn(reset_n & ~reset)
);

wire ldr_ack;
reg ldr_wr = 0;
reg ldr_done = 0;
always @(posedge clk_sys) begin
	reg old_ack, old_download;

	old_download <= ioctl_download;
	old_ack <= ldr_ack;

	if(~old_ack & ldr_ack & ldr_wr) ldr_wr <= 0;
	if(ioctl_wr & ~ldr_done) ldr_wr <= 1;

	if(old_download & ~ioctl_download) ldr_done <= 1;
end


//////////////////   SD LED   ///////////////////
reg sd_act;

always @(posedge clk_sys) begin
	reg old_mosi, old_miso;
	integer timeout = 0;

	old_mosi <= SD_MOSI;
	old_miso <= SD_MISO;

	sd_act <= 0;
	if(timeout < 1000000) begin
		timeout <= timeout + 1;
		sd_act <= 1;
	end

	if((old_mosi ^ SD_MOSI) || (old_miso ^ SD_MISO)) timeout <= 0;
end

endmodule
