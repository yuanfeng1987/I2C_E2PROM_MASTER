	// this block is to deal with the Clock_Timer and its related signals
module I2C_Clock_Timer(input wire i_RST_n,
							  input wire i_clk10MHz,
							  input wire [2:0] i_Current_State,
							  
							  output reg [7:0] Clock_Timer,
							  output reg o_Timer_Flag
							 );	

	reg [7:0] Clock_Timer_Threshold;

	always @(posedge i_clk10MHz or negedge i_RST_n)
	begin
		// deal with the Clock_Timer when reset
		if (!i_RST_n)
			begin
				Clock_Timer<=8'b0000_0000;
				o_Timer_Flag<=`Time_NotExpired;
				Clock_Timer_Threshold<=`Start_Timer;
			end
			
		else
		// in normal operation state
			begin
				if (i_Current_State==`Idle)
					begin
						Clock_Timer<=8'b0000_0000;
						o_Timer_Flag<=`Time_NotExpired;
						Clock_Timer_Threshold<=`Start_Timer;
					end
				//  the process of Clock_Timer is similar in the following 6 states.
				else if((i_Current_State==`Start)|(i_Current_State==`Stop)|(i_Current_State==`Chip_Addr_Send)|(i_Current_State==`Reg_Addr_Send)|(i_Current_State==`Data_Send)|(i_Current_State==`Data_Rcv))
					begin
						if(i_Current_State==`Start)
							Clock_Timer_Threshold<=`Start_Timer;
						else if (i_Current_State==`Stop)
							Clock_Timer_Threshold<=`Stop_Timer;
						else
							Clock_Timer_Threshold<=`RS_Data_Timer;
				      // o_Timer_Flag must be set one clock before the clear of Clock_Timer. Because the transfer of Current_State will be  a clock latency.
						// if the Clock_Timer is cleared one clock earlier, SDA and SCL will output a clock signal undesired (Clock_Timer<=8'b0000_0000).
						Clock_Timer<=Clock_Timer+1'b1;
						if (Clock_Timer>Clock_Timer_Threshold)
							Clock_Timer<=8'b0000_0000;
						if (Clock_Timer==Clock_Timer_Threshold)
							o_Timer_Flag<=`Time_Expired;
						else
							o_Timer_Flag<=`Time_NotExpired;
					end
				// this is the undefined state, the function is the same as Idle
				else
					begin
						Clock_Timer<=8'b0000_0000;
						o_Timer_Flag<=`Time_NotExpired;
						Clock_Timer_Threshold<=8'b0000_0000;
					end
			end
	end
	
endmodule