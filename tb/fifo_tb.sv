`timescale 1ns/1ps

module fifo_tb;
	
logic clk;
logic rst;
logic rd_en;
logic wr_en;
logic [7:0] data_in;
logic [7:0] data_out;
logic full;
logic empty;

// DUT
fifo dut(
.clk(clk), 
.rst(rst), 
.rd_en(rd_en), 
.wr_en(wr_en), 
.data_in(data_in), 
.data_out(data_out), 
.full(full),
.empty(empty));

// 50 MHz clock			 
always #10 clk=~clk;

//-------------------------------------------------- 
// Initialization 
//--------------------------------------------------

initial begin
	clk = 0;
	rst = 1;
	data_in = 8'd0;
	rd_en = 0;
	wr_en = 0;


//-------------------------------------------------- 
// RESET TEST 
//--------------------------------------------------	


@(posedge clk); 


if (dut.wr_ptr != 0)
	$error("Reset Failed: wr_ptr");

if (dut.rd_ptr != 0)
	$error("Reset Failed: rd_ptr");

if (dut.count != 0)
	$error("Reset Failed: count");

if (dut.full != 0)
	$error("Reset Failed: full");

if (dut.empty != 1)
	$error("Reset Failed: empty");

$display("PASS: Reset TEST");

	repeat(2) @(posedge clk);
	rst = 0;

//----------------------------------------
// Write A, B, C into FIFO
//----------------------------------------
   
	data_in = 8'h41;   // 'A'
	wr_en = 1;
	@(posedge clk);
	
	data_in = 8'h42;   // 'B'
	@(posedge clk);
	
	data_in = 8'h43;   // 'C'
	@(posedge clk);
	
	wr_en = 0;


//----------------------------------------
// Read and verify A
//----------------------------------------	

	rd_en = 1;
	
	@(posedge clk);
	#20;
	if (data_out != 8'h41) 
		$error("Expected A (0x41), got %h", data_out);
	else 
		$display("PASS: Received A");
	

//----------------------------------------
// Read and verify B
//----------------------------------------	
	
	rd_en = 1;
	
	@(posedge clk);
	#20;
	if (data_out != 8'h42) 
		$error("Expected B (0x42), got %h", data_out);
	else 
		$display("PASS: Received B");
		
//----------------------------------------
// Read and verify C
//----------------------------------------	

	rd_en = 1;
	
	@(posedge clk);
	#20;
	if (data_out != 8'h43) 
		$error("Expected C (0x43), got %h", data_out);
	else 
		$display("PASS: Received C");
	
	rd_en <= 0;
	
//-------------------------------------------------- 
// FILL FIFO 
//--------------------------------------------------	

	wr_en = 1;

	repeat(8) begin
		@(posedge clk);
		data_in = data_in +1;
	end

	wr_en = 0;

	@(posedge clk);

	if (full != 1)
		$error("FIFO should be FULL");
	else 
		$display("PASS:FIFO FULL");
	

//-------------------------------------------------- 
// EMPTY FIFO 
//--------------------------------------------------	

	rd_en = 1;

	repeat(8) 
		@(posedge clk);

	rd_en = 0;
	@(posedge clk);

	if (empty != 1)
		$error("FIFO should be EMPTY");
	else 
		$display("PASS: FIFO EMPTY");
	
//-------------------------------------------------- 
// SIMULTANEOUS READ/WRITE 
//--------------------------------------------------

	data_in = 8'h61;
	wr_en = 1;
	@(posedge clk);

	rd_en = 1;
	@(posedge clk);

	if (dut.count != 1)
		$display("Check Simultaneous Read/Write Behavior");

	wr_en = 0;
	rd_en = 0;
	
	
//----------------------------------------
// Finish simulation
//----------------------------------------


    #50;
	 $display("--------------------------------");
    $display("FIFO Test Completed");
	 $display("--------------------------------");
	 #20;
	 $stop;
	 
end

endmodule