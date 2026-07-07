`timescale 1ns/1ps

module uart_tx_rx_tb;

logic clk;
logic rst;

logic [7:0] data_in;
logic [7:0] data_out;

logic tx_start;
logic tx_busy;
logic rx_done;

logic uart_serial_line;
logic delayed_serial_line;

assign #1 delayed_serial_line = uart_serial_line;

// UART TX MODULE INSTANTIATION
uart_tx u_tx(
	.clk(clk),
	.rst(rst),
	.tx_start(tx_start),
	.data_in(data_in),
	.tx_busy(tx_busy),
	.serial_tx_out(uart_serial_line));


// UART RX MODULE INSTANTIATION	
uart_rx u_rx(
	.clk(clk),
	.rst(rst),
	.serial_rx_in(delayed_serial_line),
	.rx_done(rx_done),
	.uart_rx_out(data_out)
);



//50MHz CLOCK
always  #10 clk=~clk;

initial begin
	clk = 0;
	rst = 1;
	
	data_in = 8'h41;
	tx_start = 0;
	
	@(posedge clk);
	
	rst = 0;

	
	// Send 'A'
	repeat(4) @(posedge clk);
	//data_in <= 8'h42;
	tx_start <= 1;
	
	@(posedge clk);
	tx_start <= 0;
	
	// Wait for transmission to start 
	wait(tx_busy == 1);
	
	//Wait until transmission finishes
	wait(tx_busy == 0);
	
	// Send 'B'
	repeat(3) @(posedge clk);
	data_in <= 8'h42;
	tx_start <= 1;
	
	@(posedge clk);
	tx_start <= 0;
	
	// Wait for transmission to start 
	wait(tx_busy == 1);
	
	//Wait until transmission finishes
	wait(tx_busy == 0);
	
	// Send 'C'
	repeat(3) @(posedge clk);
	data_in <= 8'h43;
	tx_start <= 1;
	
	@(posedge clk);
	tx_start <= 0;
	
	// Wait for transmission to start 
	wait(tx_busy == 1);
	
	//Wait until transmission finishes
	wait(tx_busy == 0);
	
	#150;
	$stop;
end


endmodule