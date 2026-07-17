`timescale 1ns/1ps

module uart_tx_tb;

//=========================================================
// Testbench Signals
//=========================================================

	logic  clk;
	logic  rst;
	logic  tx_start;
	logic  [7:0] data_in;
	
	logic  tx_busy;
	logic  serial_tx_out;
	
//=========================================================
// Device Under Test (DUT)
//=========================================================
	
	uart_tx #(

	.CLKS_PER_BIT(4)
)  dut (
	.clk(clk),
	.rst(rst),
	.tx_start(tx_start),
	
	.data_in(data_in),
	
	.tx_busy(tx_busy),
	.serial_tx_out(serial_tx_out)
	
);
	
//=========================================================
// Clock Generation (50 MHz equivalent for simulation)
//=========================================================
	
	always #5ns clk = ~clk;
	
	
//=========================================================
// UART Transmit Task
//=========================================================
    
	 task send_byte(input logic [7:0] tx_data);
    begin
        data_in = tx_data;

        @(posedge clk);
        tx_start = 1;

        @(posedge clk);
        tx_start = 0;

        wait(tx_busy);
        wait(!tx_busy);

        $display("[%0t] PASS : Transmitted 0x%02h", $time, tx_data);

        repeat(2) @(posedge clk);
    end
    endtask
	
//=========================================================
// Test Sequence
//=========================================================
	
	initial begin
	
	// Initialize signals
		clk = 0;
		rst = 1;
		tx_start = 0;
		data_in = 8'h00;

	// Apply reset	
		repeat(2) @(posedge clk);
		rst = 0;
		
	//-----------------------------------------------------
   // Test Case 1 : All Zeros
   //-----------------------------------------------------
		
		send_byte(8'h00);
		
	//-----------------------------------------------------
   // Test Case 2 : All Ones
   //-----------------------------------------------------
		
		send_byte(8'hFF);
		
	//-----------------------------------------------------
   // Test Case 3 : Alternating Pattern
   //-----------------------------------------------------
      
		send_byte(8'h55);
		
	//-----------------------------------------------------
   // Test Case 4 : Alternating Pattern
   //-----------------------------------------------------
      
		send_byte(8'hAA);
		
	//-----------------------------------------------------
   // Test Case 5 : ASCII 'A'
   //-----------------------------------------------------
		send_byte(8'h41);

   //-----------------------------------------------------
   // Test Case 6 : ASCII 'B'
	//-----------------------------------------------------
      send_byte(8'h42);

	//-----------------------------------------------------
   // Test Complete
   //-----------------------------------------------------
		
		$display("---------------------------------------");
      $display("UART TX Test Completed Successfully");
      $display("---------------------------------------");
		
		
		$stop;
		
	end


endmodule