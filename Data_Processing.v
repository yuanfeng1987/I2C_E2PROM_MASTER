// I2C data processing module
// State transfer 

//State define
//`define Idle 3'b000
//`define Start 3'b001
//`define Chip_Addr_Send 3'b010
//`define Reg_Addr_Send 3'b011
//`define Data_Send 3'b100
//`define Data_Rcv 3'b101
//`define Stop 3'b110

//// whether I2C module is enabled or not: 
//`define I2C_disabled 1'b0
//`define I2C_Enabled 1'b1
////I2C module read or write enabled :i_R_W
//`define Read_Enabled 1'b1
//`define Wrt_Enabled 1'b0
//// The receiving or sending data is finished or not : 
//`define Data_RS_Done 1'b0
//`define Data_RS_NotDone 1'b1
//// The E2PROM current addr is the required addr
//`define Read_Setting_Done 1'b1
//`define Read_Setting_NotDone 1'b0
//// The clock time reached the preset value, the current action is done
//`define Timer_Expired  1'b0
//`define Timer_NotExpired  1'b1
//// whether fault occurs during current state:
//`define Err_Yes 1'b1
//`define Err_No  1'b0
//
//
//// timer expiraion value definition
//`define Start_Timer 8'b0010_1000
//`define Send_Timer 8'b1110_0001
//`define Receive_Timer 8'b1110_0001
//`define Stop_Timer 8'b0010_1000
//
//`define Stop_Timer_Ph1 8'b0000_1111
//`define Stop_Timer_Ph2 8'b0001_1001

module Data_Processing(input wire i_RST_n,
							  input wire i_clk10MHz,
							  input wire [2:0] i_Current_State,
							  input wire [6:0] i_Chip_Addr,
							  input wire i_R_W,
							  input wire [7:0] i_Start_Addr,
							  input wire [7:0] i_Data_WR,
							  input wire [7:0] i_Data_Num,
							  input wire [7:0] Clock_Timer,  // the clock number counted in current state.
							  input wire o_Read_Setting_Flag,
							  
							  inout wire io_I2C_SCL,
							  inout wire io_I2C_SDA,
							  
							  output reg [7:0] o_Data_Rcv,
							  output reg o_Err_Flag,
							  output reg o_Num_Remain,
							  output reg ACK_value
						    );
	reg [1:0] Err_Cnt;      // error number
	reg [7:0] Data_RS_Num;  // the receiving or sending data number , not the finished!
	reg I2C_SCL_tmp;
	reg I2C_SDA_tmp;
	reg [7:0] Data_out_temp;
	
	
	always @(posedge i_clk10MHz or negedge i_RST_n)
	begin
		if (!i_RST_n)
		begin
			I2C_SCL_tmp<=1'b1;
			I2C_SDA_tmp<=1'b1;
			o_Data_Rcv<=8'b0000_0000;
			o_Err_Flag<=`Err_No;
			Err_Cnt<=2'b00;
			Data_out_temp<=8'b0000_0000;
		end
		else 
			
			// this is the function of the idle state, including the initialization of regs.
			if (i_Current_State==`Idle)
				begin
					I2C_SCL_tmp<=1'b1;
					I2C_SDA_tmp<=1'b1;
					Err_Cnt<=2'b00;
					o_Err_Flag<=`Err_No;
					ACK_value<=1'b0;
				end
				
			// this is the beginning of Start state.
			else if (i_Current_State==`Start)
				begin
					// send out start sequence
					if (Clock_Timer<`Start_Timer_Ph1)
						begin
							I2C_SCL_tmp<=1'b0;
							I2C_SDA_tmp<=1'b1;
						end
					else if (Clock_Timer<`Start_Timer_Ph2)
						begin
							I2C_SCL_tmp<=1'b1;
							I2C_SDA_tmp<=1'b1;
						end
					else
						begin
							I2C_SCL_tmp<=1'b1;
							I2C_SDA_tmp<=1'b0;
						end	
				end
			else if ((i_Current_State==`Chip_Addr_Send)|(i_Current_State==`Reg_Addr_Send)|(i_Current_State==`Data_Send)|(i_Current_State==`Data_Rcv))
				 begin
					// SCL generation, 400kHz for data output or input
					if (Clock_Timer<8'b0000_1111)     //  15
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b0001_1001)   //25    the 1st clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b0010_1000)	//25*1+15
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b0011_0010)	//25*2   the 2nd clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b0100_0001)	//25*2+15  
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b0100_1011)	//25*3   the 3rd clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b0101_1010)	//25*3+15
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b0110_0100)	//25*4   the 4th clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b0111_0011)	//25*4+15
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b0111_1101)	//25*5   the 5th clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b1000_1100)	//25*5+15
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b1001_0110)	//25*6   the 6th clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b1010_0101)	//25*6+15
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b1010_1111)	//25*7   the 7th clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b1011_1110)	//25*7+15
						I2C_SCL_tmp<=1'b0;
					else if (Clock_Timer<8'b1100_1000)	//25*8   the 8th clock finished
						I2C_SCL_tmp<=1'b1;
					else if (Clock_Timer<8'b1101_0111)	//25*8+15
						I2C_SCL_tmp<=1'b0;
					else                             	//25*9   the 9th clock finished
						I2C_SCL_tmp<=1'b1;
					// data output preparation
					// the output data can be updated very clock cycle.
					if (i_Current_State==`Chip_Addr_Send)   // if i2C current addr is not the input addr, and read mode now, write 0 is required first.
						begin
							if (i_R_W==`Wrt_Enabled)
								Data_out_temp<={i_Chip_Addr, i_R_W};          
							else if (o_Read_Setting_Flag==`Read_Setting_NotDone)
								Data_out_temp<={i_Chip_Addr, `Wrt_Enabled};
							else
								Data_out_temp<={i_Chip_Addr, i_R_W}; 
						end
					else if (i_Current_State==`Reg_Addr_Send)
						Data_out_temp<=i_Start_Addr;
					else if (i_Current_State==`Data_Send)
						Data_out_temp<=i_Data_WR;
					else
						Data_out_temp<=8'b1111_1111;   // read data means the bus is controlled by E2PROM, master output should be z.
						
					// data output : send out chip address, reg address, data, then last data is Z. To read data, SDA should be Z.
					if (Clock_Timer<8'b0000_0101)     //  5
						begin
							if(i_Current_State==`Chip_Addr_Send)
								I2C_SDA_tmp<=1'b0;
							else
								I2C_SDA_tmp<=ACK_value;  //1'b1 or just use a flip flop
						end
					else if (Clock_Timer<8'b0001_1110)   //25+5=30     
						I2C_SDA_tmp<=Data_out_temp[7]; 	 //           the 1st data finished
					else if (Clock_Timer<8'b0011_0111)	 //25*2+5=55
						I2C_SDA_tmp<=Data_out_temp[6];    //           the 2nd data finished
					else if (Clock_Timer<8'b0101_0000)	 //25*3+5= 80
						I2C_SDA_tmp<=Data_out_temp[5];    //           the 3rd data finished
					else if (Clock_Timer<8'b0110_1001)	 //25*4+5=105
						I2C_SDA_tmp<=Data_out_temp[4];    //           the 4th data finished
					else if (Clock_Timer<8'b1000_0010)	 //25*5+5=130
						I2C_SDA_tmp<=Data_out_temp[3];    //           the 5th data finished
					else if (Clock_Timer<8'b1001_1011)	 //25*6+5=155
						I2C_SDA_tmp<=Data_out_temp[2];    //           the 6th data finished
					else if (Clock_Timer<8'b1011_0100)	 //25*7+5=180
						I2C_SDA_tmp<=Data_out_temp[1];    //           the 7th data finished
					else if (Clock_Timer<8'b1100_1101)	 //25*8+5=205
						I2C_SDA_tmp<=Data_out_temp[0];    //           the 8th data finished
					else
						begin 
						if ((i_Current_State==`Data_Rcv) & (o_Num_Remain==`Data_RS_NotDone))   //  
							I2C_SDA_tmp<=1'b0;					 //           when read the last data, master should send no ack (1'bz), otherwise, 1'b0
						else
							I2C_SDA_tmp<=1'b1;
						end
					// receive data from SDA bus
					if (Clock_Timer==8'b0001_0101)     //  21
						o_Data_Rcv[7]<=io_I2C_SDA;
					if (Clock_Timer==8'b0010_1110)   //25+21=46    
						o_Data_Rcv[6]<=io_I2C_SDA; 	 //           the 1st data finished
					if (Clock_Timer==8'b0100_0111)	 //25*2+21=71
						o_Data_Rcv[5]<=io_I2C_SDA;    //           the 2nd data finished
					if (Clock_Timer==8'b0110_0000)	 //25*3+21= 96
						o_Data_Rcv[4]<=io_I2C_SDA;    //           the 3rd data finished
					if (Clock_Timer==8'b0111_1001)	 //25*4+21=121
						o_Data_Rcv[3]<=io_I2C_SDA;    //           the 4th data finished
					if (Clock_Timer==8'b1001_0010)	 //25*5+21=146
						o_Data_Rcv[2]<=io_I2C_SDA;    //           the 5th data finished
					if (Clock_Timer==8'b1010_1011)	 //25*6+21=171
						o_Data_Rcv[1]<=io_I2C_SDA;    //           the 6th data finished
					if (Clock_Timer==8'b1100_0100)	 //25*7+21=196
						o_Data_Rcv[0]<=io_I2C_SDA;    //           the 7th data finished
					if (Clock_Timer==8'b1101_1101)	 //25*8+21=221
						ACK_value<=io_I2C_SDA;    //           the 8th data finished
									
				end
				 
				 
			// this is the beginning of the stop mode 
			else if (i_Current_State==`Stop)
				 begin
					if (Clock_Timer<`Stop_Timer_Ph1)
						begin
							I2C_SCL_tmp<=1'b0;
							I2C_SDA_tmp<=1'b0;
						end
					else if (Clock_Timer<`Stop_Timer_Ph2)
						begin
							I2C_SCL_tmp<=1'b1;
							I2C_SDA_tmp<=1'b0;
						end
					else
						begin
							I2C_SCL_tmp<=1'b1;
							I2C_SDA_tmp<=1'b1;
						end
				 end
			// this is the default state, the same as idle state.
			else
				begin
					I2C_SCL_tmp<=1'b1;
					I2C_SDA_tmp<=1'b1;
					Err_Cnt<=2'b00;
				end
	end
	
	assign io_I2C_SCL = I2C_SCL_tmp? 1'bz:1'b0;
	assign io_I2C_SDA = I2C_SDA_tmp? 1'bz:1'b0;
	
	// the following block is to calculate the received or send data bytes
	always @(posedge i_clk10MHz or negedge i_RST_n)
	begin
		if(!i_RST_n)
			Data_RS_Num<=8'b0000_0000;
		else
			begin
				if ((i_Current_State==`Idle)|(i_Current_State==`Start)|(i_Current_State==`Stop)|(i_Current_State==`Chip_Addr_Send)|(i_Current_State==`Reg_Addr_Send))
					Data_RS_Num<=8'b0000_0000;
				else if((i_Current_State==`Data_Send)|(i_Current_State==`Data_Rcv))
					begin
						if (Clock_Timer==8'b0001_0101)
							Data_RS_Num<=Data_RS_Num+1'b1;
						if(Data_RS_Num==i_Data_Num)
							o_Num_Remain<=`Data_RS_Done;
						else
							o_Num_Remain<=`Data_RS_NotDone;
					end
				else
					Data_RS_Num<=8'b0000_0000;
			end
		
	end
endmodule