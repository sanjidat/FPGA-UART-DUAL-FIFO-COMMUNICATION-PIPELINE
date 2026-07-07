`timescale 1us/1ns

// Module Interface
module uart_tx(
	input logic  clk,rst,
	input logic  tx_start,
	input logic  [7:0] data_in,
	output logic tx_busy,
	output logic serial_tx_out
);

// Internal Signals
	logic [7:0] tx_shift_reg;
	logic [3:0] bit_count;
	logic [3:0] baud_counter;
	logic baud_tick;

// FSM States
typedef enum logic [1:0]  {
	IDLE, START, DATA, STOP	
	} state_t;
	state_t state, next_state;

// Baud Generator
	always_ff @(posedge clk) begin
		if (rst) begin
			baud_counter <= 0;
			baud_tick    <= 0;
		end 
		else begin
			if (baud_counter == 3) begin
				baud_counter <= 0;
				baud_tick    <= 1;
			end 
			else begin
				baud_counter <= baud_counter + 1;
				baud_tick    <= 0;
			end
		end
	end

// FSM State Register	
	always_ff @(posedge clk) begin
		if (rst) begin
			state <= IDLE;
		end
		else begin
			state <= next_state;
		end
	end

// Next State Logic (FSM Brain)	
	always_comb begin
		next_state = state;
		
		case (state)
			IDLE : begin
				if (tx_start && baud_tick)
					next_state = START;
				end
			
			START: begin
				if (baud_tick)
					next_state = DATA;
				end
				
			DATA : begin
				if (baud_tick && bit_count == 7)
					next_state = STOP;
				end
			
			STOP: begin
				if (baud_tick)
					next_state = IDLE;
				end
			
		endcase 
	end
	
// Datapath (Shift Register + Counter)
	always_ff @(posedge clk) begin
		if (rst) begin
			tx_shift_reg <= 0;
			bit_count    <= 0;
		end
		else begin 
			case (state) 
				IDLE: begin
					bit_count <= 0;
					if (tx_start && baud_tick) 
						tx_shift_reg <= data_in;
				end
				
				DATA: begin
					if (baud_tick) begin
						tx_shift_reg <= tx_shift_reg >> 1;
						
						if (bit_count < 7)
							bit_count <= bit_count +1;
					end
				end
			endcase
		end
	end

// Output Logic	
	always_comb begin
		tx_busy = 0;
		serial_tx_out = 1;
		
		case(state)
		
			IDLE : begin
					tx_busy = 0;
					serial_tx_out = 1;
			end	
			
			START: begin
					tx_busy = 1;
					serial_tx_out = 0;
			end	
			
			DATA : begin
					tx_busy = 1;
					serial_tx_out = tx_shift_reg[0];
			end	
			
			STOP: begin
					tx_busy = 1;
					serial_tx_out = 1;
			end	
		endcase
	end

uart_tx_assertion u_assert (
	.clk(clk), .rst(rst), .bit_count(bit_count), .baud_tick(baud_tick)
);	
	
endmodule 













