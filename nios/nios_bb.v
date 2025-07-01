
module nios (
	clk_clk,
	reset_reset_n,
	adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_data_in,
	adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_empty,
	adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_rdreq);	

	input		clk_clk;
	input		reset_reset_n;
	input	[127:0]	adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_data_in;
	input		adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_empty;
	output		adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_rdreq;
endmodule
