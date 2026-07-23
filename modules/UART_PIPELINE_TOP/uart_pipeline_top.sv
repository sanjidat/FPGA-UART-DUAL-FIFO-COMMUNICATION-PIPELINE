`timescale 1ns/1ps

module uart_pipeline_top #(
    parameter integer CLKS_PER_BIT = 434
)(
	input logic clk,
	input logic rst,
	
	input logic tx_wr_en,
	
	input logic [7:0] data_in,
	
	output logic [7:0] data_out

	);
	
logic tx_rd_en;
logic tx_start;

logic rx_rd_en;
logic rx_wr_en;

logic tx_full;
logic tx_empty;

logic rx_full;
logic rx_empty;

logic [7:0] data_out_fifo_tx;
logic [7:0] data_in_fifo_rx;

logic tx_busy;
logic serial_out;

logic rx_done;

typedef enum logic [1:0] {
	WAIT,
	READ,
	START
	} ctrl_state_t;
	
	ctrl_state_t ctrl_state;
	ctrl_state_t next_ctrl_state;
	
// CONTROL STATE REGISTER

	always_ff @(posedge clk) begin
		if (rst) begin
			ctrl_state <= WAIT;
		end
	
		else begin
			ctrl_state <= next_ctrl_state;
		end
	end

// NEXT STATE LOGIC (FSM BRAIN)

	always_comb begin 
		next_ctrl_state = ctrl_state;
		
		case (ctrl_state)
		
			WAIT: begin
				if (!tx_empty && !tx_busy)
					next_ctrl_state = READ;
				end
			
			READ: begin
					next_ctrl_state = START;
			end
			
			START: begin
					next_ctrl_state = WAIT;
			end
		endcase
	end
	
// OUTPUT LOGIC
	
	always_comb begin
		tx_rd_en = 0;
		tx_start = 0;
		
		case (ctrl_state)
			WAIT: begin
				// DO Nothing
			end
			
			READ: begin
				tx_rd_en = 1;
				tx_start = 0;
			end
			
			START: begin
				tx_rd_en = 0;
				tx_start = 1;
			end
				
		endcase
	
	end


	
fifo fifo_tx(
	.clk(clk),
	.rst(rst),
	.rd_en(tx_rd_en),
	.wr_en(tx_wr_en),
	.data_in(data_in),
	.data_out(data_out_fifo_tx),
	.full(tx_full), 
	.empty(tx_empty)
);

uart_tx #(
	.CLKS_PER_BIT(CLKS_PER_BIT)
) u_tx(
	.clk(clk),
	.rst(rst),
	.tx_start(tx_start),
	.data_in(data_out_fifo_tx),
	.tx_busy(tx_busy),
	.serial_tx_out(serial_out)
);

uart_rx #(
	.CLKS_PER_BIT(CLKS_PER_BIT)
) u_rx(
	.clk(clk),
	.rst(rst),
	.serial_rx_in(serial_out),
	.rx_done(rx_done),
	.uart_rx_out(data_in_fifo_rx)
);



assign rx_wr_en = rx_done;

typedef enum logic [1:0] {
	WAIT_RX,
	READ_RX
	
	} ctrl_state_r;
	
	ctrl_state_r ctrl_state_rx;
	ctrl_state_r next_ctrl_state_rx;
	
// CONTROL STATE REGISTER
	always_ff @(posedge clk) begin
		if (rst) begin
			ctrl_state_rx <= WAIT_RX;
		end
	
		else begin
			ctrl_state_rx <= next_ctrl_state_rx;
		end
	end

// NEXT STATE LOGIC (FSM BRAIN)

	always_comb begin 
		next_ctrl_state_rx = ctrl_state_rx;
		
		case (ctrl_state_rx)
		
			WAIT_RX: begin
				if (!rx_empty)
					next_ctrl_state_rx = READ_RX;
				end
			
			READ_RX: begin
					next_ctrl_state_rx = WAIT_RX;
			end
			
		endcase
	end
	
// OUTPUT LOGIC
	
	always_comb begin
		rx_rd_en = 0;
		
		case (ctrl_state_rx)
			WAIT_RX: begin
				// DO Nothing
			end
			
			READ_RX: begin
				rx_rd_en = 1;
			end
				
		endcase
	
	end
	
fifo fifo_rx(
	.clk(clk),
	.rst(rst),
	.rd_en(rx_rd_en),
	.wr_en(rx_wr_en),
	.data_in(data_in_fifo_rx),
	.data_out(data_out),
	.full(rx_full), 
	.empty(rx_empty)
);

endmodule