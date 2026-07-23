`timescale 1ns/1ps

module uart_pipeline_de10_lite(
	input logic	     MAX10_CLK1_50,
	input logic	     [9:0]		SW,
	input logic	     [1:0]		KEY,
	output logic	  [9:0]		LEDR

);

logic clk;
logic rst;
logic tx_wr_en;
logic [7:0] data_in;
logic [7:0] data_out;

logic KEY0_meta;
logic KEY0_sync;
logic KEY0_prev;

assign clk       		= MAX10_CLK1_50;
assign data_in		   = SW[7:0];
assign rst       		= SW[9];
assign LEDR[7:0] 		= data_out;
assign LEDR[8]   		= tx_wr_en;
assign LEDR[9]   		= rst;

uart_pipeline_top #(

	.CLKS_PER_BIT(434)

)	u_pipeline(

	.clk(clk),
	.rst(rst),
	.tx_wr_en(tx_wr_en),
	.data_in(data_in),
	.data_out(data_out)

);

/* Synchronize KEY[0] and detect its falling edge */
always_ff @(posedge clk) begin

	if (rst) begin
		
		KEY0_meta   <= 1'b1;
		KEY0_sync   <= 1'b1;
		KEY0_prev   <= 1'b1;
		
		tx_wr_en    <= 1'b0;
		
	end
	
	else begin
			
			KEY0_meta  <= KEY[0];
			KEY0_sync  <= KEY0_meta;
			
			tx_wr_en  <= KEY0_prev && !KEY0_sync;
			KEY0_prev <= KEY0_sync;
	
	end
	
end

endmodule