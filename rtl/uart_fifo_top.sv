`timescale 1us/1ns

module uart_fifo_top(
	input logic clk,
	input logic rst,
	input logic wr_en,
	input logic [7:0] data_in,
	output logic data_out

);

logic [7:0] data_out_fifo;
logic [7:0] uart_tx_reg;
logic full, empty;
logic rd_en;
logic tx_start;
logic tx_busy;

fifo u_fifo(
.clk(clk), 
.rst(rst), 
.rd_en(rd_en), 
.wr_en(wr_en), 
.data_in(data_in), 
.data_out(data_out_fifo), 
.full(full),
.empty(empty));

uart_tx u_uart_tx(
	.clk(clk), .rst(rst),
	.tx_start(tx_start),
	.data_in(uart_tx_reg),
	.tx_busy(tx_busy),
	.serial_tx_out(data_out)
);

always_ff @(posedge clk) begin
	if (rst) begin
		
		tx_start <= 0;
		rd_en <= 0;
		
	end
	else begin
		//--------------------------------------------------
      // Start request
      //--------------------------------------------------
		if (!empty && !tx_busy) begin
			uart_tx_reg <= data_out_fifo;
			tx_start <= 1;
			rd_en <= 1;
		end
		
		// Start transfer when FIFO has data
      // and UART is idle0
		
		else begin
			tx_start <= 0;
			rd_en <= 0;
		end
	end

end

endmodule