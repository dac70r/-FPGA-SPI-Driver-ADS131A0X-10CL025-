
/*
* Name:			ADC Driver Driver Development
* Purpose:		ADC Interface (Wrapper)
* ADC Model: 	ADS131A0x 
* Project: 		ViCAT LSC Proj 
* Interface: 	SPI Protocol, Cyclone 10 LP Intel FPGA
* Author: 		Dennis Wong Guan Ming
* Date:			6/2/2025 
*/
module ADS131A0X(

		input 				system_clock, 			// 50 Mhz system clock
		input					reset_n,					// Reset activated by push button
		output				heartbeat,	

		/* Core SPI Signals for ADC */
		output 				SPI_SCLK,				// SPI SCLK
		output				SPI_CS,					//	SPI CS
		output 				SPI_RESET,				// SPI_RESET
		output 				SPI_MOSI,				// SPI MOSI
		input 				SPI_MISO,				// SPI MISO
		input					SPI_DRDY,				// SPI DRDY
	
		output [3:0] 		FIFO_WR_EN,
		output [3:0]		FIFO_RD_EN,
		output [3:0]		rdempty,
		output [3:0]		wrfull,

		/* Debugging purposes */
		// for debugging this module use only, do not include when integrating with main design
		output				clock_4_167Mhz_debug,		// Keeps track of the main clock used in Submodule
		output				clock_8_333Mhz_debug,		// Keeps track of the main clock used in Submodule
		output [5:0]		state,					 		// Keeps track of the current state of SPI 		- for debugging (remove in final design)
		//output [5:0]		state_2,	
		output [4:0]		state_tracker_output,
		output [31:0]		spi_miso_data_output,	
		output [7:0]		adc_init_state,
		output [8:0]		spi_bit_count,								// spi_bit_count/2 = actual bits of the SPI
		output [7:0]		spi_bit_count_32max,
		output				signal_B_negedge
);
wire [31:0]		Channel0_Raw;
wire [31:0]		Channel1_Raw;
wire [31:0]		Channel2_Raw;
wire [31:0]		Channel3_Raw;

wire [31:0] Channel0_Raw_Read;
wire [31:0] Channel1_Raw_Read;
wire [31:0] Channel2_Raw_Read;
wire [31:0] Channel3_Raw_Read;

/* SPI_Master Instance */
SPI_Master SPI_Master_uut
(
	.system_clock(system_clock),							// System Clock from FPGA - 50Mhz
	.reset_n(reset_n),										// Reset_n manually activated by push button	
	.SPI_MOSI(SPI_MOSI),										// SPI MOSI
	.SPI_MISO(SPI_MISO),										// SPI MISO
	.SPI_CS(SPI_CS),											//	SPI CS
	.SPI_SCLK(SPI_SCLK),										// SPI SCLK
	.SPI_RESET(SPI_RESET),
	.SPI_DRDY(SPI_DRDY),
	
	.Channel0_Raw(Channel0_Raw),
	.Channel1_Raw(Channel1_Raw),
	.Channel2_Raw(Channel2_Raw),
	.Channel3_Raw(Channel3_Raw),
	.FIFO_WR_EN(FIFO_WR_EN),
	
	// Non crucial Signals (for simulation and debugging)
	.clock_4_167Mhz_debug(clock_4_167Mhz_debug),
	.clock_8_333Mhz_debug(clock_8_333Mhz_debug),
	
	.state(state),												// Keeps track of the current state of SPI
	//.state_2(state_2),
	.spi_miso_data_output(spi_miso_data_output),		// debug - keeps track of the spi_miso_data received
	.adc_init_state(adc_init_state),
	.spi_bit_count(spi_bit_count),						// spi_bit_count/2 = actual bits of the SPI
	.spi_bit_count_32max(spi_bit_count_32max),
	.signal_B_negedge(signal_B_negedge)
);

/* Heartbeat Instance */
heartbeat heartbeat_uut
(
    .input_clock(system_clock), 							// 50 Mhz system clock
	 .clock_pol(heartbeat)									// output clock to led0 @ 1Mhz
);

// FIFO Chn0
my_fifo my_fifo_uut0(
	.aclr(!reset_n),
	.data(Channel0_Raw),
	
	.rdclk(synthesized_clock_12_5Mhz),
	.rdreq(FIFO_RD_EN[0]),
	
	.wrclk(synthesized_clock_4_167Mhz),
	.wrreq(FIFO_WR_EN[0]),
	
	.q(Channel0_Raw_Read),
	.rdempty(rdempty[0]),
	.wrfull(wrfull[0])
);

// FIFO Chn1
my_fifo my_fifo_uut1(
	.aclr(!reset_n),
	.data(Channel1_Raw),
	
	.rdclk(synthesized_clock_12_5Mhz),
	.rdreq(FIFO_RD_EN[0]),
	
	.wrclk(synthesized_clock_4_167Mhz),
	.wrreq(FIFO_WR_EN[1]),
	
	.q(Channel1_Raw_Read),
	.rdempty(rdempty[1]),
	.wrfull(wrfull[1])
);

// FIFO Chn2
my_fifo my_fifo_uut2(
	.aclr(!reset_n),
	.data(Channel2_Raw),
	
	.rdclk(synthesized_clock_12_5Mhz),
	.rdreq(FIFO_RD_EN[0]),
	
	.wrclk(synthesized_clock_4_167Mhz),
	.wrreq(FIFO_WR_EN[2]),
	
	.q(Channel2_Raw_Read),
	.rdempty(rdempty[2]),
	.wrfull(wrfull[2])
);

// FIFO Chn3
my_fifo my_fifo_uut3(
	.aclr(!reset_n),
	.data(Channel3_Raw),
	
	.rdclk(synthesized_clock_12_5Mhz),
	.rdreq(FIFO_RD_EN[0]),
	
	.wrclk(synthesized_clock_4_167Mhz),
	.wrreq(FIFO_WR_EN[3]),
	
	.q(Channel3_Raw_Read),
	.rdempty(rdempty[3]),
	.wrfull(wrfull[3])
);

wire synthesized_clock_4_167Mhz;
wire synthesized_clock_12_5Mhz;

clock_synthesizer #(.COUNTER_LIMIT(6)) my_fifo_clk_write
(
	.input_clock(system_clock), 							// input clock  - 50 Mhz
	.clock_pol(synthesized_clock_4_167Mhz)					// output clock - 4.167Mhz
);

//---------------------FIFO Read Clock---------------------------------------------//
// For testing purposes: In real scenario, NIOS will provide clock to read this from FIFO
// Note: 
//			1. All four channels are driven by the same "rdreq signal"

clock_synthesizer #(.COUNTER_LIMIT(7)) my_fifo_clk_read
(
    .input_clock(system_clock), 								// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_12_5Mhz)				// output clock - 4.167Mhz 
);

reg [3:0] FIFO_RD_EN_i = 4'd0;

always @ (posedge synthesized_clock_12_5Mhz)
begin
	FIFO_RD_EN_i[0] <= ~FIFO_RD_EN_i[0];
end

assign FIFO_RD_EN[0]	= FIFO_RD_EN_i[0] ? 1 : 0;

endmodule