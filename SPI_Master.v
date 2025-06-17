
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
	input					SPI_DRDY,
	
	output reg 	[31:0]Channel0_Raw,
	/* Not essential signals - can be removed */
	output				clock_4_167Mhz_debug,						// Main Clock of this Submodule
	output				clock_8_333Mhz_debug,						// Sub Clock of this Submodule
	
	output 	 	[5:0] state,											// debug - tracks the presentState of SPI
	//output		[5:0] state_2,											// debug - tracks the nextState of SPI
	output 		[31:0]spi_miso_data_output,						// debug - keeps track of the spi_miso_data received
	output 		[7:0]	adc_init_state,								// Keeps track of which state we are in at the ADC Init Phase
	output 		[8:0]	spi_bit_count,									// spi_bit_count/2 = actual bits of the SPI
	output reg	[7:0]	spi_bit_count_32max,							// spi_bit_count/2 = actual bits of the SPI
	output				signal_B_negedge				
);

wire	synthesized_clock_8_333Mhz;					// Main Clock of this Submodule	
wire	synthesized_clock_4_167Mhz;					// Sub Clock of this Submodule		
wire	clock_pol_assist;					

// Local Signals
//wire 			SPI_SCLK_Temp; 										// Previous, used in SPI with CS Consideration
reg 			SPI_MOSI_Temp 		= 1'd0;
reg 			SPI_CS_Temp 		= 1'd1;							
reg			SPI_RESET_Temp		= 1'd1;
reg 			SPI_SCLK_Temp   	= 1'b0;             		// The state of I2C_SCLK, used in State Machine Output Logic
reg [31:0]  spi_miso_data 		= 32'd0;
reg [31:0]	Channel0_Raw_local= 32'd0;

/* SPI State Definition */
// Define state encoding using localparams
localparam RESET        						= 'd0;
localparam IDLE        							= 'd1;
localparam ADC_RESET			       			= 'd2;
localparam ADC_RESET_COMPLETE					= 'd3;

localparam ADC_INIT_START       				= 'd4;
localparam ADC_INIT_START_STABLE				= 'd5;
localparam ADC_INIT_COMPLETE					= 'd6;

localparam WAIT_TRANSACTION					= 'd7;
localparam TRANSACTION_START					= 'd8;
localparam TRANSACTION_START_STABLE			= 'd9;
localparam TRANSACTION_COMPLETE				= 'd10;

localparam ADC_INIT_START_0655					= 'd11;
localparam ADC_INIT_START_STABLE_0655			= 'd12;
localparam ADC_INIT_COMPLETE_0655				= 'd13;

localparam ADC_INIT_START_0555					= 'd14;
localparam ADC_INIT_START_STABLE_0555			= 'd15;
localparam ADC_INIT_COMPLETE_0555				= 'd16;

localparam ADC_INIT_START_0033					= 'd17;
localparam ADC_INIT_START_STABLE_0033			= 'd18;
localparam ADC_INIT_COMPLETE_0033				= 'd19;

localparam ADC_INIT_START_4B68					= 'd20;
localparam ADC_INIT_START_STABLE_4B68			= 'd21;
localparam ADC_INIT_COMPLETE_4B68				= 'd22;

localparam ADC_INIT_START_4F0F					= 'd23;
localparam ADC_INIT_START_STABLE_4F0F			= 'd24;
localparam ADC_INIT_COMPLETE_4F0F				= 'd25;

localparam ADC_INIT_START_4C3E					= 'd26;
localparam ADC_INIT_START_STABLE_4C3E			= 'd27;
localparam ADC_INIT_COMPLETE_4C3E				= 'd28;

localparam ADC_INIT_START_4D02					= 'd29;
localparam ADC_INIT_START_STABLE_4D02			= 'd30;
localparam ADC_INIT_COMPLETE_4D02				= 'd31;

localparam ADC_INIT_START_4E25					= 'd32;
localparam ADC_INIT_START_STABLE_4E25			= 'd33;
localparam ADC_INIT_COMPLETE_4E25				= 'd34;

// Current and Next States 
reg [5:0] presentState					 		= 'd0;
reg [5:0] nextState	 							= 'd0;

// Local Registers and Counters
reg	[31:0] 	adc_reset_count						= 8'd0;		// Counter for ADC Reset (Single Use)	
reg	[7:0]		adc_init_state_i						= 8'd0;		// Keeps track of which state we are in at the ADC Init Phase
reg 				adc_init_completed 					= 'd0;
reg 				spi_sclk_enable 						= 'd0;

/* Hard Coded Messages */
localparam [31:0]		ADC_READY_0000		= 32'h0000_0000;
localparam [31:0]		ADC_UNLOCK_0655	= 32'h0655_0000;
localparam [31:0]		ADC_WAKEUP_0033	= 32'h0033_0000;	
localparam [31:0]		ADC_LOCKED_0555	= 32'h0555_0000;
localparam [31:0]		ADC_SETTING_4B68 	= 32'h4B68_0000;
localparam [31:0]		ADC_SETTING_4F0F  = 32'h4F0F_0000;
localparam [31:0]		ADC_SETTING_4C3E 	= 32'h4C3E_0000;
localparam [31:0]		ADC_SETTING_4D02 	= 32'h4D02_0000;
localparam [31:0]		ADC_SETTING_4E25 	= 32'h4E25_0000;

localparam	no_of_channels 							= 'd4;
localparam	no_of_spi_bit_counts_per_channel 	= 'd64;

/* ADC Raw Values */
// reg [31:0]		Channel0_Raw							= 32'd0;

clock_synthesizer #(.COUNTER_LIMIT(3)) uut0
(
    .input_clock(system_clock), 								// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_8_333Mhz)				// output clock - 4.167Mhz 
);

clock_synthesizer_toggle #(.COUNTER_LIMIT(6)) uut1
(
    .input_clock(system_clock),					 			// input clock  - 50 Mhz
	 .adc_init_completed_status(adc_init_completed),
	 .enable(spi_sclk_enable),
	 .clock_pol(synthesized_clock_4_167Mhz),				// output clock - 4.167Mhz 
	 .clock_pol_assist(clock_pol_assist),
	 .spi_bit_count(spi_bit_count)
);

// SPI_MOSI (For now: ADC Init - CPOL = 0, CPHA = 1)
always @ (posedge clock_pol_assist) // SPI_SCLK_Temp)
begin
	//--------------------------adc_init_not_yet_complete---------------------------------
	if(adc_init_completed == 0) begin
		if(spi_bit_count == 0)
			spi_bit_count_32max <= 'd1;
		else if (spi_bit_count <66)
			spi_bit_count_32max <= (spi_bit_count_32max + 'd1) % 33;
		else
			spi_bit_count_32max <= 'd0;
		
		if(spi_bit_count >2) begin
			case(adc_init_state_i)
					0: SPI_MOSI_Temp 		<= ADC_READY_0000			['d32 - spi_bit_count_32max];
					1: SPI_MOSI_Temp 		<= ADC_UNLOCK_0655		['d32 - spi_bit_count_32max];
					2: SPI_MOSI_Temp 		<= ADC_SETTING_4B68		['d32 - spi_bit_count_32max];
					3:	SPI_MOSI_Temp 		<= ADC_WAKEUP_0033		['d32 - spi_bit_count_32max]; 
					4: SPI_MOSI_Temp 		<= ADC_LOCKED_0555		['d32 - spi_bit_count_32max];
					5: SPI_MOSI_Temp 		<= ADC_SETTING_4F0F		['d32 - spi_bit_count_32max];
					6: SPI_MOSI_Temp 		<= ADC_SETTING_4C3E		['d32 - spi_bit_count_32max];
					7: SPI_MOSI_Temp 		<= ADC_SETTING_4D02		['d32 - spi_bit_count_32max];
					8: SPI_MOSI_Temp 		<= ADC_SETTING_4E25		['d32 - spi_bit_count_32max];
					default:
						SPI_MOSI_Temp 		<= ADC_READY_0000			['d32 - spi_bit_count_32max];
			endcase
		end
	end
	//--------------------------adc_init_completed----------------------------------------
	else begin
		SPI_MOSI_Temp 		<= 'd0;	// Always outputing 0 during read
		if(spi_bit_count == 0)
			spi_bit_count_32max <= 'd1;
		else if (spi_bit_count <66 + 64*4)
			spi_bit_count_32max <= spi_bit_count_32max + 'd1;
		else
			spi_bit_count_32max <= 'd0;
	end
end

// SPI_MISO Collection
always @ (negedge synthesized_clock_4_167Mhz) // SPI_SCLK_Temp)
begin
	if((presentState == ADC_INIT_START_STABLE 
	|| presentState == ADC_INIT_START_STABLE_0555 
	|| presentState == ADC_INIT_START_STABLE_0655 
	|| presentState == ADC_INIT_START_STABLE_0033
	|| presentState == ADC_INIT_START_STABLE_4B68
	|| presentState == ADC_INIT_START_STABLE_4F0F
	|| presentState == ADC_INIT_START_STABLE_4C3E
	|| presentState == ADC_INIT_START_STABLE_4D02
	|| presentState == ADC_INIT_START_STABLE_4E25
	|| presentState == TRANSACTION_START_STABLE))
	begin
	//--------------------------adc_init_completed--------------------------------
		if(adc_init_completed==1)
			begin
				if(spi_bit_count_32max >= 2 && spi_bit_count_32max <= 33)
					begin
						if(spi_bit_count_32max == 0)
							spi_miso_data[0] <= SPI_MISO;
						else	
							spi_miso_data['d33 - spi_bit_count_32max] <= SPI_MISO;
					end
				else if(spi_bit_count_32max >= 34 && spi_bit_count_32max <= 65)
					begin
						if(spi_bit_count_32max == 0) begin 
							spi_miso_data[0] <= SPI_MISO; end
						else begin
							spi_miso_data['d33 - (spi_bit_count_32max-32*1)] <= SPI_MISO; end
					end
				else if(spi_bit_count_32max >= 66 && spi_bit_count_32max <= 97)
					begin
						if(spi_bit_count_32max == 0)
							spi_miso_data[0] <= SPI_MISO;
						else
							spi_miso_data['d33 - (spi_bit_count_32max-32*2)] <= SPI_MISO;
					end
				else if(spi_bit_count_32max >= 98 && spi_bit_count_32max <= 129)
					begin
						if(spi_bit_count_32max == 0)
							spi_miso_data[0] <= SPI_MISO;
						else
							spi_miso_data['d33 - (spi_bit_count_32max-32*3)] <= SPI_MISO;
					end
				else if(spi_bit_count_32max >= 130 && spi_bit_count_32max <= 161)
					begin
						if(spi_bit_count_32max == 0)
							spi_miso_data[0] <= SPI_MISO;
						else
							spi_miso_data['d33 - (spi_bit_count_32max-32*4)] <= SPI_MISO;
					end
				else
					begin 
						//TODO: ERROR 
					end
			end
	//--------------------------!adc_init_completed-------------------------------
		else begin
			if(spi_bit_count_32max == 0)
				spi_miso_data[0] <= SPI_MISO;
			else
				spi_miso_data['d33 - spi_bit_count_32max] <= SPI_MISO;
		end
	end
end

// Interrupt Service Routine ISR for SPI_DRDY
reg [1:0] signal_B_sync;
//wire signal_B_negedge;

always @ (posedge synthesized_clock_8_333Mhz)
begin
	if(adc_init_completed == 1)
	begin
		signal_B_sync[0]	<= SPI_DRDY;
		signal_B_sync[1]	<= signal_B_sync[0];
	end
end

assign	signal_B_negedge = (signal_B_sync[1] == 'd1 && signal_B_sync[0] == 'd0);

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
					SPI_CS_Temp			<= 'd1;
					spi_sclk_enable	<= 'd0;
					adc_init_completed<= 'd0;
				end
        IDLE: begin
					SPI_CS_Temp			<= 'd1; 
					spi_sclk_enable	<= 'd0;
					adc_reset_count	<= 'd0;					// reset the ADC Reset Counter
					adc_init_completed<= 'd0;
				end
		  ADC_RESET: begin
					SPI_CS_Temp			<= 'd1; 
					spi_sclk_enable	<= 'd0;
					SPI_RESET_Temp		<= 'd0;
					adc_reset_count	<= adc_reset_count +'d1;	// Increment the counter (5ms)
				end
		  ADC_RESET_COMPLETE: begin
					SPI_CS_Temp			<= 'd1;
					spi_sclk_enable	<= 'd0;	
					SPI_RESET_Temp		<= 'd1;
					adc_reset_count	<= adc_reset_count +'d1;	// Increment the counter (20ms)
				end
		  ADC_INIT_START: begin 
					SPI_CS_Temp			<= 'd0; 
					spi_sclk_enable	<= 'd0;
					adc_init_state_i 	<= 'd0;
				end
		  ADC_INIT_START_STABLE: begin
					SPI_CS_Temp			<= SPI_CS_Temp;
					spi_sclk_enable	<= 'd1;	
				end
		  ADC_INIT_COMPLETE: begin
					SPI_CS_Temp 		<= 'd1;
					spi_sclk_enable	<= 'd0;	
				end
				
		  ADC_INIT_START_0655: begin 
					SPI_CS_Temp			<= 'd0; 
					spi_sclk_enable	<= 'd0;
					adc_init_state_i 	<= 'd1;
				end
		  ADC_INIT_START_STABLE_0655: begin
					SPI_CS_Temp			<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_0655: begin
					SPI_CS_Temp 		<= 'd1;
					spi_sclk_enable	<= 'd0;	
				end
				
		 ADC_INIT_START_0555: begin 
					SPI_CS_Temp			<= 'd0;
					spi_sclk_enable	<= 'd0;	
					adc_init_state_i  <= 'd4;
				end
		  ADC_INIT_START_STABLE_0555: begin
					SPI_CS_Temp			<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_0555: begin
					SPI_CS_Temp 		<= 'd1;
					spi_sclk_enable	<= 'd0;	
				end
				
		  ADC_INIT_START_0033: begin 
					SPI_CS_Temp			<= 'd0;
					spi_sclk_enable	<= 'd0;	
					adc_init_state_i 	<= 'd3;
				end
		  ADC_INIT_START_STABLE_0033: begin
					SPI_CS_Temp					<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_0033: begin
					SPI_CS_Temp 		<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end
	//-------------------------------------			
		  ADC_INIT_START_4B68: begin 
					SPI_CS_Temp			<= 'd0;
				spi_sclk_enable		<= 'd0;	
					adc_init_state_i 	<= 'd2;
				end
		  ADC_INIT_START_STABLE_4B68: begin
					SPI_CS_Temp			<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_4B68: begin
					SPI_CS_Temp 		<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end
	//-------------------------------------
		  ADC_INIT_START_4C3E: begin 
					SPI_CS_Temp			<= 'd0;
				spi_sclk_enable		<= 'd0;	
					adc_init_state_i 	<= 'd6;
				end
		  ADC_INIT_START_STABLE_4C3E: begin
					SPI_CS_Temp			<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_4C3E: begin
					SPI_CS_Temp 		<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end
	//-------------------------------------
		  ADC_INIT_START_4D02: begin 
					SPI_CS_Temp			<= 'd0;
				spi_sclk_enable		<= 'd0;	
					adc_init_state_i 	<= 'd7;
				end
		  ADC_INIT_START_STABLE_4D02: begin
					SPI_CS_Temp			<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_4D02: begin
					SPI_CS_Temp 		<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end
	//-------------------------------------
		  ADC_INIT_START_4E25: begin 
					SPI_CS_Temp			<= 'd0;
				spi_sclk_enable		<= 'd0;	
					adc_init_state_i 	<= 'd8;
				end
		  ADC_INIT_START_STABLE_4E25: begin
					SPI_CS_Temp			<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_4E25: begin
					SPI_CS_Temp 		<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end
	//--------------------------------------			
		 ADC_INIT_START_4F0F: begin 
					SPI_CS_Temp			<= 'd0;
				spi_sclk_enable		<= 'd0;	
					adc_init_state_i 	<= 'd5;
				end
		  ADC_INIT_START_STABLE_4F0F: begin
					SPI_CS_Temp			<= SPI_CS_Temp; 
					spi_sclk_enable	<= 'd1;
				end
		  ADC_INIT_COMPLETE_4F0F: begin
					SPI_CS_Temp 		<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end
				
		  WAIT_TRANSACTION: begin 
					SPI_CS_Temp 		<= 'd1; 
					adc_init_completed<= 'd1;
				end
		  TRANSACTION_START: begin 
					SPI_CS_Temp			<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end
		  TRANSACTION_START_STABLE: begin
					//SPI_CS_Temp			<= SPI_CS_Temp;
					adc_init_state_i 	<= 'd0;	
					if(adc_init_completed == 1 && signal_B_negedge == 1) 
						begin
							SPI_CS_Temp			<= 'd0;
							spi_sclk_enable	<= 'd1;
						end
				end
		  TRANSACTION_COMPLETE: begin
					SPI_CS_Temp			<= 'd1; 
					spi_sclk_enable	<= 'd0;
				end 
		  default: begin
					SPI_CS_Temp 		<= 'd1; 
					spi_sclk_enable	<= 'd0;
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
				nextState = ADC_RESET;
		  ADC_RESET:
				begin
					if(adc_reset_count == 'd41_665)
						nextState = ADC_RESET_COMPLETE;
					else
						nextState = ADC_RESET;
				end
		  ADC_RESET_COMPLETE: begin
					if(adc_reset_count == 'd41_665 + 'd166_660)
						nextState = ADC_INIT_START;
					else
						nextState = ADC_RESET_COMPLETE;
				end
		  ADC_INIT_START: begin
					nextState = ADC_INIT_START_STABLE;
				end
		  ADC_INIT_START_STABLE:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE; 
						end
					else
						nextState = ADC_INIT_START_STABLE;
				end
		  ADC_INIT_COMPLETE: begin
					if(spi_miso_data == 32'hff04_0000)
						begin nextState = ADC_INIT_START_0655; end 
					else
						nextState = ADC_INIT_START;
				end
				
		ADC_INIT_START_0655: begin
					nextState = ADC_INIT_START_STABLE_0655;
				end
				
		  ADC_INIT_START_STABLE_0655:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_0655; 
						end
					else
						nextState = ADC_INIT_START_STABLE_0655;
				end
		  ADC_INIT_COMPLETE_0655: begin
					if(spi_miso_data == 32'h0655_0000)
						begin nextState = ADC_INIT_START_4B68; end
					else
						nextState = ADC_INIT_START_0655;
				end
		//----------------------------------------------------------		
		  ADC_INIT_START_4B68:
				nextState = ADC_INIT_START_STABLE_4B68;
		  ADC_INIT_START_STABLE_4B68:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_4B68; 
						end
					else
						nextState = ADC_INIT_START_STABLE_4B68;
				end
		  ADC_INIT_COMPLETE_4B68: begin
					if(spi_miso_data == 32'h2B68_0000)
						begin nextState = ADC_INIT_START_4C3E; end
					else
						nextState = ADC_INIT_START_4B68;
				end
		//----------------------------------------------------------		
		  ADC_INIT_START_4C3E:
				nextState = ADC_INIT_START_STABLE_4C3E;
		  ADC_INIT_START_STABLE_4C3E:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_4C3E; 
						end
					else
						nextState = ADC_INIT_START_STABLE_4C3E;
				end
		  ADC_INIT_COMPLETE_4C3E: begin
					if(spi_miso_data == 32'h2C3E_0000)
						begin nextState = ADC_INIT_START_4D02; end
					else
						nextState = ADC_INIT_START_4C3E;
				end
		//----------------------------------------------------------		
		  ADC_INIT_START_4D02:
				nextState = ADC_INIT_START_STABLE_4D02;
		  ADC_INIT_START_STABLE_4D02:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_4D02; 
						end
					else
						nextState = ADC_INIT_START_STABLE_4D02;
				end
		  ADC_INIT_COMPLETE_4D02: begin
					if(spi_miso_data == 32'h2D02_0000)
						begin nextState = ADC_INIT_START_4E25; end
					else
						nextState = ADC_INIT_START_4D02;
				end
		//----------------------------------------------------------		
		  ADC_INIT_START_4E25:
				nextState = ADC_INIT_START_STABLE_4E25;
		  ADC_INIT_START_STABLE_4E25:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_4E25; 
						end
					else
						nextState = ADC_INIT_START_STABLE_4E25;
				end
		  ADC_INIT_COMPLETE_4E25: begin
					if(spi_miso_data == 32'h2E25_0000)
						begin nextState = ADC_INIT_START_4F0F; end
					else
						nextState = ADC_INIT_START_4E25;
				end
		//----------------------------------------------------------		
		  ADC_INIT_START_4F0F:
				nextState = ADC_INIT_START_STABLE_4F0F;
		  ADC_INIT_START_STABLE_4F0F:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_4F0F; 
						end
					else
						nextState = ADC_INIT_START_STABLE_4F0F;
				end
		  ADC_INIT_COMPLETE_4F0F: begin
					if(spi_miso_data == 32'h2F0F_0000)
						begin nextState = ADC_INIT_START_0033; end
					else
						nextState = ADC_INIT_START_4F0F;
				end
		//-----------------------------------------------------------	
		  ADC_INIT_START_0033:
				nextState = ADC_INIT_START_STABLE_0033;
		  ADC_INIT_START_STABLE_0033:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_0033; 
						end
					else
						nextState = ADC_INIT_START_STABLE_0033;
				end
		  ADC_INIT_COMPLETE_0033: begin
					if(spi_miso_data == 32'h0033_0000)
						begin nextState = ADC_INIT_START_0555; end
					else
						nextState = ADC_INIT_START_0033;
				end
		//------------------------------------------------------------	
		  ADC_INIT_START_0555:
				nextState = ADC_INIT_START_STABLE_0555;
		  ADC_INIT_START_STABLE_0555:
				begin
					if (spi_bit_count == 'd67) // initially was 65, now we add 2 more 
						begin
							nextState = ADC_INIT_COMPLETE_0555; 
						end
					else
						nextState = ADC_INIT_START_STABLE_0555;
				end
		  ADC_INIT_COMPLETE_0555: begin
					if(spi_miso_data == 32'h0555_0000)
						begin nextState = WAIT_TRANSACTION; end//IDLE; end  // for testing
					else
						nextState = ADC_INIT_START_0555;
				end
		//-------------------------------------------------------------	
		  WAIT_TRANSACTION:
				nextState = TRANSACTION_START;
		  TRANSACTION_START:
				nextState = TRANSACTION_START_STABLE;
		  TRANSACTION_START_STABLE: 
				begin
					if (spi_bit_count == 'd67+no_of_spi_bit_counts_per_channel*no_of_channels) // initially was 65, now we add 2 more 
						nextState = TRANSACTION_COMPLETE; 
					else
						nextState = TRANSACTION_START_STABLE;
				end
		  TRANSACTION_COMPLETE: 
				nextState = WAIT_TRANSACTION; 
		 //-------------------------------------------------------------
		  default:
				nextState = RESET;
    endcase
end

// Assigning Value to Channel 0
always @ (*)
begin
	if(spi_bit_count_32max == 64)
		Channel0_Raw = spi_miso_data;
	else
		Channel0_Raw = Channel0_Raw;
end

	// Core Signals 
	assign SPI_SCLK						= synthesized_clock_4_167Mhz; //SPI_SCLK_Temp;
	assign SPI_CS							= SPI_CS_Temp;
	assign SPI_MOSI 						= SPI_MOSI_Temp;
	assign SPI_RESET						= SPI_RESET_Temp;
	
	// Debug by Dennis
	assign clock_4_167Mhz_debug		= clock_pol_assist;
	assign clock_8_333Mhz_debug		= synthesized_clock_8_333Mhz;
	
	assign state 							= presentState;
	assign spi_miso_data_output		= spi_miso_data;
	assign adc_init_state 				= adc_init_state_i;

	//assign state_2							= nextState;
endmodule 


