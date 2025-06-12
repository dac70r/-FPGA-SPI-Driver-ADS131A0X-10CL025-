
/* SPI Module */

module SPI_Master 
(
	input 				system_clock,									// System Clock from FPGA - 50Mhz
	input 				reset_n,											// Reset button
	
	output 				SPI_MOSI,										// SPI MOSI
	input 				SPI_MISO,										// SPI MISO
	output				SPI_CS,											//	SPI CS
	output 				SPI_SCLK,										// SPI SCLK
	output 		 		SPI_RESET,										// SPI_RESET - to reset the ADC
	input					trigger,											// External Trigger to Start Transactions
	
	/* Not essential signals - can be removed */
	output				clock_4_167Mhz_debug,						// Main Clock of this Submodule
	output				clock_8_333Mhz_debug,						// Sub Clock of this Submodule
	
	output 	 	[4:0] state,											// debug - tracks the presentState of SPI
	output		[4:0] state_2,											// debug - tracks the nextState of SPI
	output 		[31:0]spi_clock_cycles_output,					// debug - keeps track of the 
	
	output		[4:0]	state_tracker_output,						// deprecated
	output 		[31:0]spi_miso_data_output,						// debug - keeps track of the spi_miso_data received
	
	output reg	[7:0] spi_miso_data_cc_output,
	output		[3:0] spi_mosi_byte_count_output,				// debug - keeps track of the command sent
	output reg	[7:0]	spi_transaction_count = 8'd0,
	output				spi_sclk_clock_state_2_removed_output
);

wire	synthesized_clock_8_333Mhz;					// Main Clock of this Submodule	
wire	synthesized_clock_4_167Mhz;					// Sub Clock of this Submodule							
wire	[7:0]	count_cs_tracker;							// Tracks the Clock Cycles within each SPI Transmission

// Local Signals
//wire 			SPI_SCLK_Temp; 										// Previous, used in SPI with CS Consideration
reg 			SPI_MOSI_Temp 		= 1'd0;
reg 			SPI_CS_Temp 		= 1'd1;							
reg			SPI_RESET_Temp		= 1'd1;
reg 			SPI_SCLK_Temp   	= 1'b0;             		// The state of I2C_SCLK, used in State Machine Output Logic
reg [31:0]  spi_clock_cycles  = 32'd0;             	// Register for keeping track of number of Clock Cycles elapsed
reg [31:0]  spi_miso_data 		= 32'd0;

/* SPI State Definition */
// Define state encoding using localparams
localparam RESET        						= 5'd0;
localparam IDLE        							= 5'd1;
localparam ADC_INIT_START       				= 5'd2;
localparam ADC_INIT_START_STABLE				= 5'd3;
localparam ADC_INIT_COMPLETE					= 5'd4;
localparam WAIT_TRANSACTION					= 5'd5;
localparam TRANSACTION_START					= 5'd6;
localparam TRANSACTION_START_STABLE			= 5'd7;
localparam TRANSACTION_COMPLETE				= 5'd8;

// Current and Next States 
reg [4:0] presentState					 		= 5'd0;
reg [4:0] nextState	 							= 5'd0;

// Local Registers and Counters
wire				SPI_SCLK_internal_use;
reg	[4:0]		state_tracker							= 5'd0;
reg	[7:0] 	adc_reset_count						= 8'd0;		// Counter for ADC Reset (Single Use)	
reg	[31:0]	delay_counter_transition_logic	= 32'd0;		// Counter for tracking 50ns delay in Setting Up ADC

/* SPI MOSI Handler Signals */
reg [7:0]	spi_mosi_bit_count 	= 'd0;
reg [3:0]	spi_mosi_byte_count	= 'd0;

/* Hard Code Messages */
localparam		ADC_UNLOCK_0655	= 32'h0655_0000;

clock_synthesizer #(.COUNTER_LIMIT(3)) uut0
(
    .input_clock(system_clock), 								// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_8_333Mhz)				// output clock - 4.167Mhz 
);

clock_synthesizer #(.COUNTER_LIMIT(6)) uut1
(
    .input_clock(system_clock),					 			// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_4_167Mhz)				// output clock - 4.167Mhz 
);

// SPI_MOSI (For now: ADC Init - CPOL = 0, CPHA = 1)
always @ (posedge SPI_SCLK_Temp)
begin
	SPI_MOSI_Temp 		<= ADC_UNLOCK_0655['d32 - spi_miso_data_cc_output];
end

// SPI_MISO Collection
always @ (negedge SPI_SCLK_Temp)
begin
	if((presentState == ADC_INIT_START_STABLE || presentState == TRANSACTION_START_STABLE))
	begin
		spi_miso_data['d32 - spi_miso_data_cc_output] <= SPI_MISO;
		//spi_miso_data_output['d32 - spi_miso_data_cc_output] <= SPI_MISO;
		//if(spi_miso_data_cc_output >= 1)
			//begin spi_miso_data[spi_miso_data_cc_output] <= SPI_MISO; end
	end
	//if(spi_miso_data_cc_output == 'd32) begin spi_miso_data <= spi_miso_data >> 'd1; end
end

// State Machine Next State Logic 
always @ (posedge synthesized_clock_8_333Mhz)
begin
    if(!reset_n)
        presentState <= RESET;
    else
        presentState <= nextState;
end

// State Machine Output Logic (Sequential)
// Parameters: SPI_SCLK, SPI_CS
// SPI_SCLK: Generates the SPI_SCLK Signal for each State Machine State
always @ (posedge synthesized_clock_8_333Mhz)
begin
    case(presentState)
        RESET: begin
					SPI_CS_Temp		<= 'd1;
					SPI_SCLK_Temp 	<= 'd0; 
				end
        IDLE: begin
					SPI_CS_Temp		<= 'd1; 
					SPI_SCLK_Temp 	<= 'd0; 
				end
		  ADC_INIT_START: begin 
					SPI_CS_Temp		<= 'd0; 
					SPI_SCLK_Temp 	<= 'd0; 
				end
		  ADC_INIT_START_STABLE: begin
					SPI_CS_Temp					<= SPI_CS_Temp; 
					spi_clock_cycles        <= (spi_clock_cycles + 'd1) % 64;
					SPI_SCLK_Temp 				<= ~SPI_SCLK_Temp; /*
					if(spi_clock_cycles%2==0)
						spi_miso_data_cc_output <= (spi_miso_data_cc_output + 'd1) % 32; */
					if(spi_clock_cycles%2==0) 
					begin
						if (spi_miso_data_cc_output == 'd32)
							spi_miso_data_cc_output <= 'd1;
						else
							spi_miso_data_cc_output <= spi_miso_data_cc_output + 'd1;
					end
				end
		  ADC_INIT_COMPLETE: begin
					SPI_CS_Temp 	<= 'd1; 
					SPI_SCLK_Temp 	<= 'd0; 
				end
		  WAIT_TRANSACTION: begin 
					SPI_CS_Temp 	<= 'd1; 
					SPI_SCLK_Temp 	<= 'd0; 
				end
		  TRANSACTION_START: begin 
					SPI_CS_Temp		<= 'd0; 
					SPI_SCLK_Temp 	<= 'd0; 
				end
		  TRANSACTION_START_STABLE: begin
					SPI_CS_Temp					<= SPI_CS_Temp; 
					spi_clock_cycles        <= (spi_clock_cycles + 'd1) % 64;
					SPI_SCLK_Temp 				<= ~SPI_SCLK_Temp; /*
					if(spi_clock_cycles%2==0)
						spi_miso_data_cc_output <= (spi_miso_data_cc_output + 'd1) % 32; */
					if(spi_clock_cycles%2==0) 
					begin
						if (spi_miso_data_cc_output == 'd32)
							spi_miso_data_cc_output <= 'd1;
						else
							spi_miso_data_cc_output <= spi_miso_data_cc_output + 'd1;
					end
				end
		  TRANSACTION_COMPLETE: begin
					SPI_CS_Temp		<= 'd1; 
					SPI_SCLK_Temp 	<= 'd0; 
				end
		  default: begin
					SPI_CS_Temp 	<= 'd1; 
					SPI_SCLK_Temp 	<= 'd0; 
				end
    endcase
end

// State Machine Transition Logic (Combinational)
// Determines the condition to change to the nextState
always @ (*)
begin 
    case(presentState)
        RESET:
            nextState = IDLE;
        IDLE:
				nextState = ADC_INIT_START;
		  ADC_INIT_START:
				nextState = ADC_INIT_START_STABLE;
		  ADC_INIT_START_STABLE:
				begin
					if(spi_clock_cycles == 'd64 - 'd1)
						nextState = ADC_INIT_COMPLETE;
					else
						nextState = ADC_INIT_START_STABLE;
				end
		  ADC_INIT_COMPLETE:
				nextState = WAIT_TRANSACTION;
		  WAIT_TRANSACTION:
				nextState = TRANSACTION_START;
		  TRANSACTION_START:
				nextState = TRANSACTION_START_STABLE;
		  TRANSACTION_START_STABLE: 
				begin
					if(spi_clock_cycles == 'd64 - 'd1)
						nextState = TRANSACTION_COMPLETE;
					else
						nextState = TRANSACTION_START_STABLE;
				end
		  TRANSACTION_COMPLETE: 
				nextState = IDLE;
				
		  default:
				nextState = RESET;
    endcase
end

	// Core Signals 
	assign SPI_SCLK						= SPI_SCLK_Temp;
	assign SPI_CS							= SPI_CS_Temp;
	assign SPI_MOSI 						= SPI_MOSI_Temp;
	assign SPI_RESET						= SPI_RESET_Temp;
	
	// Debug by Dennis
	assign clock_4_167Mhz_debug		= synthesized_clock_4_167Mhz;
	assign clock_8_333Mhz_debug		= synthesized_clock_8_333Mhz;
	
	assign state 							= presentState;
	assign state_2							= nextState;
	assign spi_clock_cycles_output 	= spi_clock_cycles;
	assign state_tracker_output 		= state_tracker;
	assign spi_miso_data_output		= spi_miso_data;
	
	assign spi_mosi_byte_count_output= spi_mosi_byte_count;
endmodule 


