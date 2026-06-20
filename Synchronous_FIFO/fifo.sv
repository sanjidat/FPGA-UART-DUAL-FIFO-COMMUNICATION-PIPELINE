`timescale 1ns/1ps
module fifo(
	input logic clk,
	input logic rst,
	input logic rd_en,
	input logic wr_en,
	input logic [7:0] data_in,
	output logic [7:0] data_out,
	output logic full, 
	output logic empty

);

logic [7:0] memory [0:7];
logic [2:0] wr_ptr, rd_ptr;
logic [3:0] count;

integer i;

always_ff @(posedge clk) begin
	if (rst) begin
		wr_ptr   <= 0;
		rd_ptr   <= 0;
		count    <= 0;
		data_out <= 0;	
		
		for (i= 0; i<8 ; i++)
			memory[i] <= 0;
	end
	
	else begin
		if (wr_en && count<8) begin
			memory[wr_ptr] <= data_in;
			wr_ptr <= wr_ptr + 1;
			count <= count +1;
		end 
	
		if (rd_en && count>0) begin
			data_out <= memory[rd_ptr];
			rd_ptr <= rd_ptr + 1;
			count <= count -1;
		end
	
	end	
end

assign empty = (count == 0);
assign full  = (count == 8);

endmodule