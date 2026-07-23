`timescale 1ns/1ps

module uart_pipeline_top_tb;

//localparam integer CLKS_PER_BIT = 4;

logic clk;
logic rst;

logic tx_wr_en;

logic [7:0] data_in;
logic [7:0] data_out;

integer pass_count;
integer fail_count;

logic [7:0] random_byte;

// DUT

uart_pipeline_top #(

	.CLKS_PER_BIT(4)
	
)	dut(
	.clk(clk),
	.rst(rst),
	.tx_wr_en(tx_wr_en),
	.data_in(data_in),
	.data_out(data_out)
	
);

// ASSERTIONS

uart_pipeline_assertions u_assertions(

	.clk(clk), 
	.rst(rst),
	
	.tx_start(dut.tx_start),
	.tx_busy(dut.tx_busy),
	.tx_wr_en(dut.tx_wr_en),
	.tx_rd_en(dut.tx_rd_en),
	.serial_tx_out(dut.serial_out),
	
	.rx_done(dut.rx_done),
	.rx_rd_en(dut.rx_rd_en),
	.rx_wr_en(dut.rx_wr_en),
	
	.tx_fifo_empty(dut.tx_empty),
	.rx_fifo_empty(dut.rx_empty),
	
	.tx_fifo_full(dut.tx_full),
	.rx_fifo_full(dut.rx_full),
	
	.tx_state(dut.u_tx.state)
);

// COVERAGE

uart_pipeline_coverage u_coverage(

	.clk(clk),
	.rst(rst),
	
	.tx_wr_en(tx_wr_en),
	.tx_fifo_full(dut.tx_full),
	
	.data_in(data_in)

);

// 50MHz clock

always #10 clk = ~clk;


// Task to Write Data into TX FIFO

task send_byte(input logic [7:0] data_in_fifo);

	begin
	
		@(posedge clk);
		
		data_in  <= data_in_fifo;
		tx_wr_en <= 1;
		
		@(posedge clk);
		
		tx_wr_en <= 0;
	end
endtask

// Task to CHECK Received Byte

task check_byte(input logic [7:0] expected);
	
	begin
		wait(dut.rx_empty == 1'b0);
		wait(dut.rx_rd_en == 1'b1);
		repeat(2) @(posedge clk);
		
		//@(posedge dut.rx_rd_en);     // wait until RX FIFO is read
      //repeat(2) @(posedge clk);
		if (data_out == expected) begin
			pass_count = pass_count + 1;
			$display("[%0t]  PASS: Received %h", $time, data_out);
		end
		
		else begin
			fail_count = fail_count + 1;
			$display("[%0t] FAIL: Expected=%h Got=%h", $time, expected, data_out);
			
		end
		
		wait(dut.rx_rd_en == 1'b0);
			
	end	
endtask

initial begin 
	
	pass_count = 0;
	fail_count = 0;
	
	clk = 0;
	 
   rst = 1;

   tx_wr_en = 0;
   data_in  = 8'h00;


   // Reset

   repeat(5) @(posedge clk);

   rst = 0;
	 
	$display("UART PIPELINE TEST START");


	// Send bytes && Check bytes
	 
	send_byte(8'h00);
	wait(dut.tx_busy);
	wait(!dut.tx_busy);
	
	check_byte(8'h00);
	
	send_byte(8'hFF);
	wait(dut.tx_busy);
	wait(!dut.tx_busy);
	
	check_byte(8'hFF);
	
	send_byte(8'hAA);
	wait(dut.tx_busy);
	wait(!dut.tx_busy);
	
	check_byte(8'hAA);
	
	send_byte(8'h55);
	wait(dut.tx_busy);
	wait(!dut.tx_busy);
	
	check_byte(8'h55);
	
	send_byte(8'h41);
	wait(dut.tx_busy);
	wait(!dut.tx_busy);
	
	check_byte(8'h41);
	
	
	repeat (20) begin
		random_byte = $urandom;

		send_byte(random_byte);
		check_byte(random_byte);
		
end

	$display("-------------------------------");
	$display("PASS COUNT = %0d", pass_count);
	$display("FAIL COUNT = %0d", fail_count);
	$display("-------------------------------");

    #1000;


    $finish;

end


endmodule