`timescale 1ns/1ps
module uart_tx_tb;
	logic  clk,rst;
	logic  tx_start;
	logic  [7:0] data_in;
	
	logic  tx_busy;
	logic  serial_tx_out;
	
	uart_tx dut (.clk(clk), .rst(rst), .tx_start(tx_start), .data_in(data_in),
				 .tx_busy(tx_busy), .serial_tx_out(serial_tx_out)
	);
	
	always #10 clk = ~clk;
	initial begin
		clk = 0;
		rst = 1;
		tx_start = 0;
		data_in = 8'b10110010;
		
		#50;
		rst = 0;
		
		#50;
		tx_start = 1;
		
		#20;
		tx_start = 0;
		
		wait(tx_busy == 1);
		wait(tx_busy == 0);

      #20;
		$stop;
	end


endmodule