`timescale 1ns/1ps

module uart_pipeline_assertions(

	input logic clk, 
	input logic rst,
	
	input logic tx_start,
	input logic tx_busy,
	
	input logic serial_tx_out,
	
	input logic tx_rd_en,
	input logic tx_wr_en,
	
	input logic rx_done,
	
	input logic rx_rd_en,
	input logic rx_wr_en,
	
	input logic tx_fifo_full,
	input logic tx_fifo_empty,
	input logic rx_fifo_full,
	input logic rx_fifo_empty,
	
	input logic [0:1] tx_state
);

logic tx_start_prev;
logic tx_rd_en_prev;

logic rx_done_prev;
logic rx_rd_en_prev;


integer assertion_fail_count = 0;

always @(posedge clk) begin
	if(rst) begin 
	
		tx_start_prev   <= 0;
		tx_rd_en_prev   <= 0;
		rx_done_prev    <= 0;
		rx_rd_en_prev   <= 0;
		
	end
	
	else begin
	
		// PULSE WIDTH ASSERTIONS

		if (tx_start && tx_start_prev) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: tx_start is more than clock pulse");
		
		end
		
		if (tx_rd_en && tx_rd_en_prev) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: tx_rd_en is more than clock pulse");
		
		end

		
		if (rx_done && rx_done_prev) begin
		
			assertion_fail_count++;
			
			$error("ASSERT FAIL: rx_done is more than one clock pulse");
			
		end
			
		if (rx_rd_en && rx_rd_en_prev) begin
		
			assertion_fail_count++;
			
			$error("ASSERT FAIL: rx_rd_en is more than one clock pulse");
		
		end
		
		// FIFO ASSERTIONS
		
		
		if (tx_fifo_empty && tx_rd_en) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: TX FIFO read while EMPTY");
		
		end
		
		if (rx_fifo_empty && rx_rd_en) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: RX FIFO read while EMPTY");
		
		end
		
		if (tx_fifo_full && tx_wr_en) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: TX FIFO WRITE while FULL");
		
		end
		
		if (rx_fifo_full && rx_wr_en) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: RX FIFO WRITE while FULL");
		
		end
		
		// CONTROLLER ASSERTIONS 
		
		if (tx_start && tx_busy) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: tx_start asserted while UART is busy");
		
		end
		
		
		if (rx_done ^ rx_wr_en) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: rx_wr_en must follow rx_done");
		
		end
		
		
		if (tx_start_prev && !tx_busy) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: tx_busy did not assert after tx_start");
		
		end
		
		
		if (rx_done && rx_fifo_full) begin
			
			assertion_fail_count++;
			
			$error("ASSERT FAIL: rx_fifo can not be full at the time when rx_done asserts");
		
		end
		
		
		
		
			
		tx_start_prev  <= tx_start;
		
		tx_rd_en_prev  <= tx_rd_en;
				
		rx_done_prev   <= rx_done;
		
		rx_rd_en_prev  <= rx_rd_en;
		
		
		// UART Protocol Assertions
		
		if (!tx_busy) begin
			
			assert (serial_tx_out == 1'b1)
			
				else begin
					
					assertion_fail_count++;
			
					$error("ASSERT FAIL: UART TX line is not HIGH while IDLE");
		
				end
		
		end
		
		
		if (tx_start_prev) begin
			
			assert (serial_tx_out == 1'b0)
			
				else begin
					
					assertion_fail_count++;
			
					$error("ASSERT FAIL: UART TX line is not LOW while START");
		
				end
		
		end
		
		
		
		if (tx_state == 2'b11) begin
			
			assert (serial_tx_out == 1'b1)
			
				else begin
					
					assertion_fail_count++;
			
					$error("ASSERT FAIL: UART TX line is not HIGH while STOP");
		
				end
		
		end
			
		
	end
end

final begin

	if (assertion_fail_count == 0)
		$display("ASSERTION PASS: ALL PULSE WIDTH CHECKS PASSED");
	else 
		$display("ASSERTION FAIL COUNT = %0d", assertion_fail_count);
end

endmodule