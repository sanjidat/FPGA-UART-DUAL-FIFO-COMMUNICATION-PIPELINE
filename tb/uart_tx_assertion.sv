`timescale 1ns/1ps
module uart_tx_assertion(
	input logic clk, rst,
	input logic [3:0] bit_count,
	input logic baud_tick
);

always @(posedge clk) begin
	if (!rst) begin
		assert (bit_count <= 7)
	else 
		$error("!bit_count exceeded 7!");
	end
end
//assert property (
//	disable iff (rst)
	//bit_count <= 7
//);

//assert property (
	//disable iff (rst)
	//baud_tick |-> ##1 !baud_tick
//);
endmodule