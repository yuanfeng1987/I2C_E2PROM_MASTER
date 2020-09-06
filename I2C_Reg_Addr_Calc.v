// set i2C current read or write address
module I2C_Reg_Addr_Calc(input wire i_RST_n,
							  input wire i_clk10MHz,
							  input wire [2:0] i_Current_State,
							  input wire [7:0] Clock_Timer,
							  input wire [7:0] i_Start_Addr,
							  
							  output reg [7:0] o_Current_Addr,   // the current i2c reg address
							  output reg o_Read_Setting_Flag
                        );


	always @(posedge i_clk10MHz or negedge i_RST_n)
	begin
		if (!i_RST_n)
			begin
			o_Current_Addr<=8'b0000_0000;
			o_Read_Setting_Flag<=`Read_Setting_NotDone;
			end
		else
			begin
				if (i_Current_State==`Idle)
				begin
					o_Current_Addr<=o_Current_Addr;
					o_Read_Setting_Flag<=`Read_Setting_NotDone;
				end
				else if (i_Current_State==`Start)
					begin
						o_Current_Addr<=o_Current_Addr;
						if (o_Current_Addr==i_Start_Addr)
							o_Read_Setting_Flag<=`Read_Setting_Done;
						else
							o_Read_Setting_Flag<=`Read_Setting_NotDone;  // o_Read_Setting_Flag
					end
				else if (i_Current_State==`Chip_Addr_Send)
					begin
						o_Current_Addr<=o_Current_Addr;
						o_Read_Setting_Flag<=o_Read_Setting_Flag;
					end
				else if (i_Current_State==`Reg_Addr_Send)
					begin
						o_Current_Addr<=i_Start_Addr;
						o_Read_Setting_Flag<=`Read_Setting_Done ;
					end
				else if ((i_Current_State==`Data_Send)|(i_Current_State==`Data_Rcv))
					begin
						if (Clock_Timer==8'b0001_0101)
							o_Current_Addr<=o_Current_Addr+1'b1;
					end
				else
					begin
						o_Current_Addr<=o_Current_Addr;
						o_Read_Setting_Flag<=`Read_Setting_NotDone;
					end
						
			end
	end
endmodule