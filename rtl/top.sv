module top (
    input logic clk,
    input logic rst,
    output logic [9:0] LEDR,
	 output logic UART_tx
);

logic [25:0] counter;
logic        tx_start;
logic [7:0]  data_in;
logic        tx_busy;


uart_tx u_uart_tx(
	.clk(clk), .rst(!rst),
	.tx_start(tx_start),
	.data_in(data_in),
	.tx_busy(tx_busy),
	.serial_tx_out(UART_tx)
);

always_ff @(posedge clk) begin
	if (!rst) begin
		counter <= 26'd0;
		tx_start <= 0;
		data_in <= 8'h41;    // ASCII 'A'
	end
	
	else begin 
		if (counter == 26'd50000000) begin 
			counter <= 26'd0; 
			if (tx_busy == 0) begin
				tx_start <= 1'b1; 
				if (data_in == 8'h5A)  // ASCII 'Z'
					data_in <= 8'h41;   // ASCII 'A'
				else 
					data_in <= data_in + 8'd1; 
			end
			else begin 
				tx_start <= 1'b0;
			end
		end
		
		else begin 
			tx_start <= 1'b0; 
			counter <= counter + 26'd1; 
		end	
	end 
end

assign LEDR[0] = counter[25];
assign LEDR[1] = !rst;
assign LEDR[2] = tx_start;
assign LEDR[3] = tx_busy;
assign LEDR[4] = UART_tx;
assign LEDR[9:5] = 0;

endmodule