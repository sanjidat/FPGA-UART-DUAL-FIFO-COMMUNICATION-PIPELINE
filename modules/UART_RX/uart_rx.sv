`timescale 1ns/1ps

module uart_rx #(

	parameter integer CLKS_PER_BIT = 434
)(
	input logic clk,
	input logic rst,
	
	input logic serial_rx_in,
	
	output logic rx_done,
	output logic [7:0] uart_rx_out
);

// Internal Signals

	logic [7:0] rx_shift_reg;
	
	logic [3:0] bit_count;
	logic [8:0] baud_counter;
	
	logic baud_tick;
	
// FSM States

typedef enum logic [2:0] {
	IDLE, START, DATA, STOP, DONE
}	state_t;
	
	state_t state, next_state;
	
// Baud Generator
 
	always_ff @(posedge clk) begin
	
		if (rst) begin
			baud_counter <= 0;
			baud_tick    <= 0;
		end
		
		else begin
		
			if (baud_counter == CLKS_PER_BIT - 1) begin
				baud_counter <= 0;
				baud_tick    <= 1;
			end 
			
			else begin
				baud_counter <= baud_counter + 1;
				baud_tick <= 0;
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
	
		case (state )
		
			IDLE: begin
				if(!serial_rx_in) begin
					next_state = START;
				end
			end
			
			START: begin
				if (baud_tick) begin
					next_state = DATA;
				end
			end
			
			DATA: begin
				if (baud_tick && bit_count == 7) begin
					next_state = STOP;
				end
			end
			
			STOP: begin 
				if (baud_tick) begin
					next_state = DONE;
				end
			end
		
			DONE: begin 
				if (baud_tick) begin
					next_state = IDLE;
				end
			end
		endcase 
	
	end
	

// Datapath (Shift Register + Counter)

		always_ff @(posedge clk) begin
			
			if (rst) begin
			
				rx_shift_reg <= 8'd0;
				bit_count    <= 4'd0;
				
			end
			
			else begin
			
				case (state)
				
					IDLE : begin
						
						if(!serial_rx_in) begin
						
							bit_count <= 4'd0;
						end
						
					end
					
					DATA : begin
						
						if (baud_tick) begin
							rx_shift_reg <= {serial_rx_in, rx_shift_reg[7:1]};
							//rx_shift_reg <= {rx_shift_reg[6:0],serial_rx_in};
							if (bit_count < 7) begin
								bit_count <= bit_count +1;
							end
								
						end
					end
				endcase
			end	
		end


// Output Logic
	
	always_ff @(posedge clk)begin
	
		if (rst) begin
			rx_done <= 0;
			uart_rx_out <= 8'd0;
		end
		
		else begin
			
			rx_done <= 0;
			if (state == STOP && baud_tick) begin
				uart_rx_out <= rx_shift_reg;
				rx_done <= 1;
			end
			
		end
	end

endmodule