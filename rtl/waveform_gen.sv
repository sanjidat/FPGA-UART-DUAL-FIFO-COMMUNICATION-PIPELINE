
module waveform_gen (
	input logic clk,
	input logic rst,
	output logic [7:0] sample 
	
);

logic [25:0] slow_counter;

always_ff @(posedge clk) begin
	
	if (rst) begin
		slow_counter <= 26'd0;
		sample       <= 8'd0;
	end 
	
	else begin
		slow_counter <= slow_counter + 1'b1;
		
		if (slow_counter == 26'd50000000) begin
			slow_counter <= 26'd0;
			sample <= sample + 1'b1;
		end
	end
end
	
endmodule
	
	