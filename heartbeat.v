
/* Heartbeat Module */

module heartbeat (
    input 				input_clock, 			// input clock  - 50 Mhz
	 output 				clock_pol				// output clock - 1hz 
);

reg [31:0] counter = 32'b0;
reg clock_state = 1'b0;

always @ (posedge input_clock)
begin 
	if(counter == 32'd24_999_999) begin counter <= 0; clock_state <= ~clock_state; end
	else
		begin counter <= counter + 1; end

end

assign clock_pol = clock_state;

endmodule