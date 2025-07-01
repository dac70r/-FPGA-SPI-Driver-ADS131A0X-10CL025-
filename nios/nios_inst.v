	nios u0 (
		.clk_clk                                                (<connected-to-clk_clk>),                                                //                                       clk.clk
		.reset_reset_n                                          (<connected-to-reset_reset_n>),                                          //                                     reset.reset_n
		.adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_data_in (<connected-to-adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_data_in>), // adc_fifo_reader_0_adc_fifo_reader_conduit.fifo_data_in
		.adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_empty   (<connected-to-adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_empty>),   //                                          .fifo_empty
		.adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_rdreq   (<connected-to-adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_rdreq>)    //                                          .fifo_rdreq
	);

