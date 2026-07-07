`timescale 1ns/1ps
 
module uart_rx_tb;
 
logic clk; 
logic rst; 
logic serial_rx_in; 
logic [7:0] uart_rx_out; 
logic rx_done; 

// DUT 
uart_rx u_rx ( 
	.clk(clk), 
	.rst(rst), 
	.serial_rx_in(serial_rx_in), 
	.rx_done(rx_done), 
	.uart_rx_out(uart_rx_out) ); 
	
// 50MHz Clock 
always #10 clk = ~clk; 

// Monitor received byte 

always @(posedge rx_done) begin 
	$display("Received Byte = %h", uart_rx_out); 
end 

initial begin 
	clk = 0; 
	rst = 1; 
	serial_rx_in = 1; 
	
	// Reset repeat(3) 
	@(posedge clk); 
	rst = 0; 
	// ========================= 
	// UART FRAME TRANSMISSION 
	// Sending 8'h55 
	// Binary = 01010101 
	// UART sends LSB first 
	// ========================= 
	// START bit 
	
	serial_rx_in = 0; 
	#80; 
	
	// bit0 = 1 
	serial_rx_in = 1; 
	#80; 
	
	// bit1 = 0 
	serial_rx_in = 0; 
	#80; 
	
	// bit2 = 1 
	serial_rx_in = 1; 
	#80; 
	
	// bit3 = 0 
	serial_rx_in = 0; 
	#80; 
	
	// bit4 = 1 
	serial_rx_in = 1; 
	#80; 
	
	// bit5 = 0 
	serial_rx_in = 0; 
	#80; 
	
	// bit6 = 1 
	serial_rx_in = 1; 
	#80; 
	
	// bit7 = 0 
	serial_rx_in = 0; 
	#80; 
	
	// STOP bit 
	serial_rx_in = 1; 
	#80; 
	
	// Wait a little 
	#200; 
	$stop; 
	end 
	
endmodule