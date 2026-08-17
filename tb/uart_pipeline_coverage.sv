module uart_pipeline_coverage (
	input logic clk,
	input logic rst,
	
	input logic tx_wr_en,
	input logic tx_fifo_full,
	
	input logic [7:0] data_in

);


integer zero_count;
integer ff_count;
integer aa_count;
integer fiftyfive_count;

integer low_count;
integer mid_count;
integer high_count;

integer bins_hit;

real coverage_percentage;

/*covergroup uart_cov;
		
	coverpoint data_in {
		
		bins zero 		  = {8'h00};
		bins FF   		  = {8'hFF};
		bins AA          = {8'hAA};
		bins fiftyfive   = {8'h55};
		bins other       = default;
		
	}
		
endgroup


uart_cov cov;

initial begin
	
	cov = new();
	
end

always @(posedge clk) begin
    if (!rst && tx_wr_en && !tx_fifo_full)
        cov.sample();
end*/

always @(posedge clk)

	if (rst) begin
		zero_count      = 0;
		ff_count        = 0;
		aa_count        = 0;
		fiftyfive_count = 0;
		low_count       = 0;
		mid_count       = 0;
		high_count      = 0;
		
		bins_hit = 0;
	
	end
	
	else if (tx_wr_en && !tx_fifo_full) begin
		if (data_in == 8'h00) begin
			zero_count = zero_count + 1;
		end
		
		else if (data_in == 8'hFF) begin
			ff_count = ff_count + 1;
		end
		
		else if (data_in == 8'hAA) begin
			aa_count = aa_count + 1;
		end
		
		else if (data_in == 8'h55) begin
			fiftyfive_count = fiftyfive_count + 1;
		end
		
		else if (data_in >= 8'h01 && data_in <= 8'h3F) begin
			low_count = low_count + 1;
		end
		
		else if (data_in >= 8'h40 && data_in <= 8'h7F) begin
			mid_count = mid_count + 1;
		end
		
		else begin
			high_count = high_count + 1;
		end
	end
	
	
	
	
final begin

	bins_hit = 0;
	
	if (zero_count > 0)
		bins_hit = bins_hit + 1;
		
	if (ff_count > 0)
		bins_hit = bins_hit + 1;
		
	if (aa_count > 0)
		bins_hit = bins_hit + 1;
	
	if (fiftyfive_count > 0)
		bins_hit = bins_hit + 1;
		
	if (low_count > 0)
		bins_hit = bins_hit + 1;
		
	if (mid_count > 0)
		bins_hit = bins_hit + 1;
		
	if (high_count > 0)
		bins_hit = bins_hit + 1;
	
	coverage_percentage = (bins_hit / 7.0) * 100.0;

	$display("==================================");
	$display("FUNCTIONAL COVERAGE REPORT");

	$display("0X00  	   : %0d", zero_count);
	$display("0XFF  	   : %0d", ff_count);
	$display("0XAA  	   : %0d", aa_count);
	$display("0X55  	   : %0d", fiftyfive_count);
	$display("LOW COUNT  : %0d", low_count);
	$display("MID COUNT  : %0d", mid_count);
	$display("HIGH COUNT : %0d", high_count);
	
	$display("BINS HIT   : %0d / 7", bins_hit);
	$display("COVERAGE   : %0.1f%%", coverage_percentage);
	
	$display("==================================");
		
end
	
endmodule