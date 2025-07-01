/*

	Avalon Memory Mapped FIFO Reader
	For 
	4 Channels of ADC

*/

module adc_fifo_reader_mm_slave (
    input          		clk,
    input          		reset_n,

    // Avalon-MM slave signals - Data to NIOS 
    input   [1:0]  		address,		
    input          		read,				
    output  reg [127:0] readdata,		
    output         		waitrequest,	

    // FIFO signals - Data from ADC
    input   [127:0] 		fifo_data_in,
    input          		fifo_empty,
    output  reg      	fifo_rdreq
);

assign waitrequest = 0;  // Always ready for read

always @(posedge clk or negedge reset_n) begin

	if (!reset_n) begin
	  readdata   <= 32'd0;
	  fifo_rdreq <= 1'b0;
	end 
	
	else begin
        fifo_rdreq <= 1'b0;
			
			// Run Condition: Avalon Read Signal + FIFO is not empty
        if (read && address == 2'd0 && !fifo_empty) begin
            fifo_rdreq <= 1'b1;              // Read Enable to FIFO
            readdata   <= fifo_data_in;      // latch data for NIOS read
        end
    end
end

endmodule