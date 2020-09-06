// button jitter debounce 
module Button_Debounce(input wire i_Btn,
							  input wire i_Rst_n,
							  input wire i_Clock10MHz,
							  output wire o_High_Pulse);
							  
	reg [17:0] Counter_clk;
	reg in_q1, in_q2, in_q3;
	reg out_q1, out_q2;
	wire IN_Rising, IN_Falling;
	wire OUT_Rising;
	
	always @(posedge i_Clock10MHz or negedge i_Rst_n)
	begin
		if (!i_Rst_n)
			begin
				in_q1<=1'b1;
				in_q2<=1'b1;
				in_q3<=1'b1;
			end
		else
			begin
				in_q1<=i_Btn;
				in_q2<=in_q1;
				in_q3<=in_q2;
			end
	end
	assign	IN_Rising= ((!in_q3) & in_q2);
	assign	IN_Falling=(in_q3 & (!in_q2));

	always @(posedge i_Clock10MHz or negedge i_Rst_n)
	begin
		if(!i_Rst_n)
			begin
				Counter_clk<=18'b00_0000_0000_0000_0000;
			end
		else
			begin
				if(IN_Rising|IN_Falling)
					Counter_clk<=18'b00_0000_0000_0000_0000;
				else
					begin
						Counter_clk<=Counter_clk+1'b1;
						if (Counter_clk>18'b11_0000_1101_0100_0011)    //18'b11_0000_1101_0100_1111=200k+15
							Counter_clk<=18'b11_0000_1101_0100_0010; //18'b11_0000_1101_0100_0011=200k+3
					end
			end
	end
	
	always @(posedge i_Clock10MHz or negedge i_Rst_n)
	begin
		if (!i_Rst_n)
			begin
				out_q1<=1'b1;
				out_q2<=1'b1;
			end
		else
			begin
				if(Counter_clk>18'b11_0000_1101_0100_0000)
					begin
						out_q1<=in_q3;
						out_q2<=out_q1;
					end
			end
			
	end
	assign o_High_Pulse= ((!out_q2) & out_q1);
	
endmodule
							  