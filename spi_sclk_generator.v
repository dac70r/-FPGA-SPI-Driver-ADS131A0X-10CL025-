
/* SPI Clock Generator with CS Consideration */
/*

	Working Principle: We use the State Machine to activate the counter mechanism in order to generate the SPI_SCLK

*/
module spi_sclk_generator (
	 input				system_clock,
	 output 				SPI_SCLK,
	 output				SPI_SCLK_internal_use,
	 output				spi_sclk_clock_state_2_removed_output,
	 output		[7:0]	CLOCK_CYCLES,
	 input		[4:0]	state_machine					// State Machine
);


// This Block is triggered by the State Machine (TRANSACTION_IN_PROGRESS) State to generate SPI_SCLK
// If NOT, SPI_SCLK will be deasserted 
localparam TRANSACTION_IN_PROGRESS 			= 3'd6;
localparam TRANSACTION_IN_PROGRESS_0655 	= 3'd9;
localparam TRANSACTION_IN_PROGRESS_0555 	= 3'd12;
reg [31:0] 	spi_sclk_counter 					= 32'b0;
reg 			spi_sclk_clock_state 			= 1'b1;
reg			spi_sclk_clock_state_2_removed= 1'b1;
reg [7:0]	CLOCK_CYCLES_Temp 				= 8'd0;
reg			spi_transaction_done_Temp		= 1'd0;
wire			synthesized_clock_8_333Mhz;
wire			synthesized_clock_4_167Mhz;

/* Clock Synthesizer - 8.333Mhz*/
clock_synthesizer #(.COUNTER_LIMIT(3))
clock_synthesizer_uut_0
(
	 .input_clock(system_clock), 										// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_8_333Mhz)						// output clock - 5Mhz
);

/* Clock Synthesizer - 4.167Mhz*/
clock_synthesizer #(.COUNTER_LIMIT(6))
clock_synthesizer_uut_1
(
	 .input_clock(system_clock), 										// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_4_167Mhz)						// output clock - 5Mhz
);

always @ (posedge synthesized_clock_8_333Mhz)
begin
	if(state_machine == TRANSACTION_IN_PROGRESS) 
		begin
			//if(spi_sclk_counter == 5) 		// Change the number to modify the frequency of SPI_SCLK
				//begin
					//spi_sclk_counter 		<= 32'd0;
					//spi_sclk_clock_state <= ~spi_sclk_clock_state;
					if(CLOCK_CYCLES_Temp <= ('d15 + 'd16 + 'd16 + 'd16)) //65
						begin
							spi_sclk_clock_state <= ~spi_sclk_clock_state;
							//if(CLOCK_CYCLES_Temp <= 1)
								//spi_sclk_clock_state_2_removed <= 'd0;
							//else
								//spi_sclk_clock_state_2_removed <= ~spi_sclk_clock_state;
							CLOCK_CYCLES_Temp		<= CLOCK_CYCLES_Temp + 'd1;
						end
					else	
						spi_sclk_clock_state <= spi_sclk_clock_state;
				//end
			//else
				//begin spi_sclk_counter <= spi_sclk_counter + 1; end 
		end
	else 
		begin
			//spi_sclk_counter 	<= 32'd0; 
			spi_sclk_clock_state <= 1'd0;
			CLOCK_CYCLES_Temp		<= 'd0;
		end
end
 
assign SPI_SCLK_internal_use	= spi_sclk_clock_state;
assign SPI_SCLK 					= spi_sclk_clock_state; //(CLOCK_CYCLES_Temp <= 32) ? spi_sclk_clock_state: 'd0;
assign CLOCK_CYCLES 				= CLOCK_CYCLES_Temp;
assign spi_sclk_clock_state_2_removed_output = spi_sclk_clock_state_2_removed;

 
endmodule