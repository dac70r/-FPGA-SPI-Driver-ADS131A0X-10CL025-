
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
module clock_synthesizer #(parameter COUNTER_LIMIT = 24_999_999)
(
    input 				input_clock, 			// input clock  - 50 Mhz
	 output 				clock_pol				// output clock - 4.167Mhz 
);

reg [31:0] counter = 32'b0;
reg clock_state = 1'b0;

always @ (posedge input_clock)
begin 
	if(counter == COUNTER_LIMIT) begin counter <= 0; clock_state <= ~clock_state; end
	else
		begin counter <= counter + 1; end

end

assign clock_pol = clock_state;

endmodule