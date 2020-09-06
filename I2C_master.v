// State definition
`define Idle 3'b000
`define Start 3'b001
`define Chip_Addr_Send 3'b010
`define Reg_Addr_Send 3'b011
`define Data_Send 3'b100
`define Data_Rcv 3'b101
`define Stop 3'b110

// flag definition 
// whether I2C module is enabled or not: 
`define I2C_disabled 1'b0
`define I2C_Enabled 1'b1
//I2C module read or write enabled :i_R_W
`define Read_Enabled 1'b1
`define Wrt_Enabled 1'b0
// The receiving or sending data is finished or not : 
`define Data_RS_Done 1'b0
`define Data_RS_NotDone 1'b1
// The E2PROM current addr is the required addr
`define Read_Setting_Done 1'b1
`define Read_Setting_NotDone 1'b0
// The clock time reached the preset value, the current action is done
`define Time_Expired  1'b0
`define Time_NotExpired  1'b1
// whether fault occurs during current state:
`define Err_Yes 1'b1
`define Err_No  1'b0

// timer expiraion value definition
`define Start_Timer 8'b0010_1000
`define Start_Timer_Ph1 8'b0000_1111
`define Start_Timer_Ph2 8'b0001_1001

`define RS_Data_Timer 8'b1110_0001

`define Stop_Timer 8'b0010_1000
`define Stop_Timer_Ph1 8'b0000_1111
`define Stop_Timer_Ph2 8'b0001_1001

// define data used in the demon
`define Data_Num 8'b0000_0001
`define Chip_Addr 7'b1010_000
`define Start_Addr 8'b1000_0000


module I2C_master(input wire i_RST_n,
						input wire i_clk50MHz, 
						input wire i_I2C_Enable_Flag,			  // I2C enbbled by CPU
						input wire i_R_W,
						//input wire [6:0] i_Chip_Addr,
						//input wire [7:0] i_Start_Addr,
					   //input wire [7:0] i_Data_WR,
					   //input wire [7:0] i_Data_Num,
						
						inout wire io_I2C_SCL,
						inout wire io_I2C_SDA,
						
						output wire [7:0] o_Data_Rcv,
						output wire o_Err_Flagx,
					   output wire [7:0] Current_Addr
					  );
	wire o_clk10MHz;
	wire [2:0] Current_State;
	wire [7:0] Clock_Timer;
	wire Read_Setting_Flag;
	//wire Timer_Flag;
	wire Num_Remain;
	wire o_I2C_Enable_Flag;
	wire o_Err_Flag1;
	wire i_ACK;
	reg o_I2C_Enable_Flag1;
	wire o_I2C_Enable_Flag2;
	wire  [7:0] Input_Addr;
	
	always @(posedge o_clk10MHz or negedge i_RST_n)
	begin
		if (!i_RST_n)
			begin
				o_I2C_Enable_Flag1<=1'b0;
			end
		else if (o_I2C_Enable_Flag==1'b1)
			o_I2C_Enable_Flag1<=1'b1;
		else
			o_I2C_Enable_Flag1<=o_I2C_Enable_Flag1;
	end
	assign Input_Addr=(Current_Addr>`Start_Addr)? Current_Addr:`Start_Addr;
	assign o_I2C_Enable_Flag2= (o_I2C_Enable_Flag1 & (Input_Addr<8'b1001_0000));
	
	
	Button_Debounce Button_Debounce_U1(.i_Btn(i_I2C_Enable_Flag),
												  .i_Rst_n(i_RST_n),
												  .i_Clock10MHz(o_clk10MHz),
												  .o_High_Pulse(o_I2C_Enable_Flag));
												  
	
	I2C_Reg_Addr_Calc I2C_Reg_Addr_Calc_U1(.i_RST_n(i_RST_n),  
														.i_clk10MHz(o_clk10MHz), 
														.i_Current_State(Current_State), 
														.Clock_Timer(Clock_Timer), 
														.i_Start_Addr(Input_Addr),   
														.o_Current_Addr(Current_Addr), 
														.o_Read_Setting_Flag(Read_Setting_Flag));
														
														
	I2C_Clock_Timer I2C_Clock_Timer_U1(.i_RST_n(i_RST_n), 
												  .i_clk10MHz(o_clk10MHz), 
												  .i_Current_State(Current_State), 
												  .Clock_Timer(Clock_Timer),
												  .o_Timer_Flag(o_Err_Flagx));
												  
												  
	Data_Processing Data_Processing_U1(.i_RST_n(i_RST_n),     
												  .i_clk10MHz(o_clk10MHz), 
												  .i_Current_State(Current_State), 
												  .i_Chip_Addr(`Chip_Addr),
												  .i_R_W(i_R_W),
												  .i_Start_Addr(Input_Addr),         
												  .i_Data_WR(8'b10101010),             /////////////////////////////////////
												  .i_Data_Num(`Data_Num),
												  .Clock_Timer(Clock_Timer),
												  .o_Read_Setting_Flag(Read_Setting_Flag),
												  .io_I2C_SCL(io_I2C_SCL),
												  .io_I2C_SDA(io_I2C_SDA),
												  .o_Data_Rcv(o_Data_Rcv),
												  .o_Err_Flag(o_Err_Flag1),
												  .o_Num_Remain(Num_Remain),
												  .ACK_value(i_ACK));
												  
												  
	State_Transfer State_Transfer_U1(.i_RST_n(i_RST_n),   
												.i_clk10MHz(o_clk10MHz), 
												.i_I2C_Enable_Flag(o_I2C_Enable_Flag2),  
												.i_R_W(i_R_W),
												.i_Num_Remain(Num_Remain),
												.i_Read_Setting_Flag(Read_Setting_Flag),
												.i_Timer_Flag(o_Err_Flagx),
												.i_Err_Flag(o_Err_Flag1),
												.Current_State(Current_State),
												.i_ACK(i_ACK));
												
	// PLL module
	I2C_PLL	I2C_PLL_inst (	.inclk0 ( i_clk50MHz ),	.c0 ( o_clk10MHz )	);

endmodule