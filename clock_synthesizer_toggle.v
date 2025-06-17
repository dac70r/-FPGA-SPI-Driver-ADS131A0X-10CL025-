/*
* Name:			Clock Synthesizer Module
* Purpose:		This module generates the required clock frequency, by default generates 1hz clock
* Project: 		-
* Interface: 	-
* Author: 		Dennis Wong Guan Ming
* Date:			6/2/2025 
*/

// When creating a clock instance, change parameter (COUNTER_LIMIT) to achieve desired SPI clock
/* Example */
/* clock_synthesizer #(.COUNTER_LIMIT(6)) uut
	(
		.input_clock(system_clock), 							// input clock  - 50 Mhz
		.clock_pol(synthesized_clock_4Mhz)					// output clock - 4.167Mhz
	);
*/
// eg. 50Mhz/ (6*2) = 4.167Mhz

/* Default generates 1 Hz clock */
module clock_synthesizer_toggle #(parameter COUNTER_LIMIT = 24_999_999)
(
    input 				input_clock, 					// input clock  - 50 Mhz
	 input				adc_init_completed_status,
	 input				enable,
	 output				clock_pol,
	 output 				clock_pol_assist,				// output clock - 4.167Mhz
	 output reg [7:0]	spi_bit_count 	= 8'd0
);


reg [31:0] 	counter 			= 32'b0;
reg 			clock_state 	= 1'b0;
reg 			toggle			= 'd1;
reg [31:0]	n					= 'd0;

// ADC INIT COMPLETED, now READ 5 sets of 32bits of DATA
always @ (*)
	begin
		if(adc_init_completed_status)
			n = 66+(64*2);
		else
			n = 66;
	end

// 1. When Enabled, the SPI_SCLK will be generated.
// 2. If spi_bit_counter is smaller than or equal to 63, spi_bit_counter will be incremented by 1, maximum value of spi_bit_counter thus becomes 64
// 3. After 64 spi_bit_counts is accumulated, we will stop inverting the SPI_SCLK.
// 4. The clock will continue counting, but spi_bit_count will not reset until enable is deasserted.
// 5. 2 clocks are generated in the module, 1 is the assisting clock, used as internal clock while the other clock will be output as SPI_SCLK
always @ (posedge input_clock)
begin
	if(enable == 1)
		begin
			if(counter == COUNTER_LIMIT) 
				begin 
					counter <= 0;
					if(spi_bit_count <= n) begin //'d63 + 'd1 + 'd2) begin // initially we put spi_bit_count <= 63 which is ngam ngam but since we need to leave some room between last bit and assertion of CS so added 1 bit
															// then we realized we had to accomodate 2 more spi_bit_count since miso and mosi are sequential logic
						clock_state <= ~clock_state;
						spi_bit_count 	<= spi_bit_count + 'd1;
						end 
					else begin
						spi_bit_count 	<= spi_bit_count;
						clock_state		<= clock_state;
					end
				end
			else
				begin counter <= counter + 1; end
		end
	else
		begin
			counter <= 'd0;
			clock_state <= 'd0;
			spi_bit_count <= 'd0;
		end
end

assign clock_pol 			= (spi_bit_count >'d2 && spi_bit_count <= n) ? clock_state : 'd0;	// contains exactly clock cycles: 32
assign clock_pol_assist = (spi_bit_count <= n) ? clock_state : 'd0;								// contains 1 extra clock cycles: 33
endmodule