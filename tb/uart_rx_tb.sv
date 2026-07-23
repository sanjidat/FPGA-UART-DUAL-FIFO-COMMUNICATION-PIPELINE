`timescale 1ns/1ps

module uart_rx_tb;

    localparam integer CLKS_PER_BIT = 4;
    localparam integer CLK_PERIOD   = 20;

    logic       clk;
    logic       rst;
    logic       serial_rx_in;

    logic       rx_done;
    logic [7:0] uart_rx_out;

    integer i;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .serial_rx_in (serial_rx_in),
        .rx_done      (rx_done),
        .uart_rx_out  (uart_rx_out)
    );

    initial clk = 1'b0;

    always #(CLK_PERIOD / 2) clk = ~clk;

    task send_byte(input logic [7:0] data);
    begin
        // Align with the RX baud counter
        @(posedge dut.baud_tick);
        @(negedge clk);

        // Start bit
        serial_rx_in = 1'b0;
        repeat (CLKS_PER_BIT) @(negedge clk);

        // Send 8 data bits, LSB first
        for (i = 0; i < 8; i = i + 1) begin
            serial_rx_in = data[i];
            repeat (CLKS_PER_BIT) @(negedge clk);
        end

        // Stop bit
        serial_rx_in = 1'b1;
        repeat (CLKS_PER_BIT) @(negedge clk);

        // Idle
        serial_rx_in = 1'b1;
    end
    endtask

    initial begin
        rst          = 1'b1;
        serial_rx_in = 1'b1;

        repeat (5) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        repeat (3) @(posedge clk);

        send_byte(8'b1010_1011);

        repeat (5) @(posedge clk);

        $display("uart_rx_out = %b", uart_rx_out);

        $finish;
    end

endmodule