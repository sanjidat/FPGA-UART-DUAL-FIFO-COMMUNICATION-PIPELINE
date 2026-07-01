`timescale 1us/1ns

module uart_fifo_top_tb;

logic clk;
logic rst;
logic wr_en;
logic [7:0] data_in;
logic data_out;


//DUT
uart_fifo_top dut(
	.clk(clk),
	.rst(rst),
	.wr_en(wr_en),
	.data_in(data_in),
	.data_out(data_out)
); 

//50MHz CLOCK
always #10 clk=~clk;

//-------------------------------------------------- 
// TASK : WRITE BYTE INTO FIFO 
//--------------------------------------------------

task write_fifo(input [7:0] tx_data);

begin
	@(posedge clk);
	
	data_in <= tx_data;
	wr_en <= 1;
	
	@(posedge clk);
	
	wr_en <= 0;

end
endtask

//-------------------------------------------------- 
// TEST 
//--------------------------------------------------

initial begin 

	//-------------------------------------------------- 
	// INITIALIZATION 
	//--------------------------------------------------
	
	clk = 0;
	rst = 1;
	
	wr_en = 0;
	data_in = 0;
	
	//-------------------------------------------------- 
	// RESET 
	//--------------------------------------------------
	
	repeat(3) @(posedge clk);
	rst = 0;
	
	//-------------------------------------------------- 
	// WRITE DATA INTO FIFO 
	//--------------------------------------------------
	
	write_fifo(8'h41);    // A
	write_fifo(8'h42);    // B
	write_fifo(8'h43);    // C
	write_fifo(8'h44);    // D
	write_fifo(8'h45);    // E
	
	//-------------------------------------------------- 
	// WAIT FOR UART TRANSMISSIONS 
	//--------------------------------------------------
	
	repeat(300) @(posedge clk);
	
	//-------------------------------------------------- 
	// FINISH 
	//--------------------------------------------------
	
	$display("SIMULATION COMPLETED");
	
	$stop;
end

endmodule

