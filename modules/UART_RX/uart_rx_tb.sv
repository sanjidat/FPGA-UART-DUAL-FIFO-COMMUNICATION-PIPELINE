`timescale 1ns/1ps

module uart_rx_tb;

    // ------------------------------------------------------------
    // Testbench parameters
    // ------------------------------------------------------------

    localparam integer CLKS_PER_BIT = 4;
    localparam integer CLK_PERIOD   = 20;  // 50 MHz clock

    // ------------------------------------------------------------
    // Testbench signals
    // ------------------------------------------------------------

    logic       clk;
    logic       rst;
    logic       serial_rx_in;

    logic       rx_done;
    logic [7:0] uart_rx_out;

    integer pass_count;
    integer fail_count;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .serial_rx_in (serial_rx_in),
        .rx_done      (rx_done),
        .uart_rx_out  (uart_rx_out)
    );

    // ------------------------------------------------------------
    // 50 MHz clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
    end

    always #(CLK_PERIOD / 2) clk = ~clk;

    // ------------------------------------------------------------
    // UART send task
    //
    // UART sends:
    // start bit
    // data[0] first
    // ...
    // data[7] last
    // stop bit
    // ------------------------------------------------------------

    task automatic send_byte(input logic [7:0] data);
        integer i;

        begin
            $display("[%0t] Sending byte: %b (0x%02h)",
                     $time, data, data);

            // Begin each UART frame on a falling edge.
            // This avoids changing serial_rx_in on the same edge
            // where the receiver samples it.
            @(negedge clk);

            // Start bit
            serial_rx_in = 1'b0;
            repeat (CLKS_PER_BIT) @(negedge clk);

            // Eight data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                serial_rx_in = data[i];

                $display("[%0t] Sending data bit %0d = %b",
                         $time, i, data[i]);

                repeat (CLKS_PER_BIT) @(negedge clk);
            end

            // Stop bit
            serial_rx_in = 1'b1;
            repeat (CLKS_PER_BIT) @(negedge clk);

            // Keep UART line idle
            serial_rx_in = 1'b1;
        end
    endtask

    // ------------------------------------------------------------
    // Check received byte
    // ------------------------------------------------------------

    task automatic check_byte(input logic [7:0] expected);
        begin
            // Wait for receiver to indicate a complete byte
            @(posedge rx_done);

            // Wait a tiny simulation step so nonblocking assignments
            // have completed before checking uart_rx_out
            #1;

            if (uart_rx_out === expected) begin
                pass_count = pass_count + 1;

                $display("[%0t] PASS: Expected=%b, Received=%b",
                         $time, expected, uart_rx_out);
            end
            else begin
                fail_count = fail_count + 1;

                $display("[%0t] FAIL: Expected=%b, Received=%b",
                         $time, expected, uart_rx_out);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Send and check concurrently
    //
    // check_byte must already be waiting for rx_done while the
    // UART frame is being transmitted.
    // ------------------------------------------------------------

    task automatic run_test(input logic [7:0] test_data);
        begin
            fork
                send_byte(test_data);
                check_byte(test_data);
            join

            // Idle interval between UART frames
            repeat (3) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Optional monitoring
    // ------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst) begin
            if (dut.baud_tick) begin
                $display(
                    "[%0t] baud_tick: state=%s, bit_count=%0d, serial=%b, shift=%b",
                    $time,
                    dut.state.name(),
                    dut.bit_count,
                    serial_rx_in,
                    dut.rx_shift_reg
                );
            end
        end
    end

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------

    initial begin
        pass_count   = 0;
        fail_count   = 0;

        rst          = 1'b1;
        serial_rx_in = 1'b1;

        // Hold reset for several clock cycles
        repeat (5) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        // Allow receiver to settle in IDLE
        repeat (3) @(posedge clk);

        // Important non-symmetric test pattern
        run_test(8'b1010_1011);

        run_test(8'h00);
        run_test(8'hFF);
        run_test(8'h55);
        run_test(8'hAA);
        run_test(8'h96);
        run_test(8'h3C);

        $display("");
        $display("----------------------------------------");
        $display("UART RX TEST RESULTS");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("----------------------------------------");

        if (fail_count == 0)
            $display("ALL UART RX TESTS PASSED");
        else
            $display("UART RX TEST FAILED");

        repeat (5) @(posedge clk);
        $stop;
    end

    // ------------------------------------------------------------
    // Timeout protection
    // ------------------------------------------------------------

    initial begin
        #100000;

        $display("ERROR: Simulation timeout");
        $stop;
    end

endmodule