	component nios is
		port (
			clk_clk                                                : in  std_logic                      := 'X';             -- clk
			reset_reset_n                                          : in  std_logic                      := 'X';             -- reset_n
			adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_data_in : in  std_logic_vector(127 downto 0) := (others => 'X'); -- fifo_data_in
			adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_empty   : in  std_logic                      := 'X';             -- fifo_empty
			adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_rdreq   : out std_logic                                          -- fifo_rdreq
		);
	end component nios;

	u0 : component nios
		port map (
			clk_clk                                                => CONNECTED_TO_clk_clk,                                                --                                       clk.clk
			reset_reset_n                                          => CONNECTED_TO_reset_reset_n,                                          --                                     reset.reset_n
			adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_data_in => CONNECTED_TO_adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_data_in, -- adc_fifo_reader_0_adc_fifo_reader_conduit.fifo_data_in
			adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_empty   => CONNECTED_TO_adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_empty,   --                                          .fifo_empty
			adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_rdreq   => CONNECTED_TO_adc_fifo_reader_0_adc_fifo_reader_conduit_fifo_rdreq    --                                          .fifo_rdreq
		);

