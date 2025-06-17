
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


endmodule