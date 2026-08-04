# FPGA UART Dual-FIFO Communication Pipeline

A complete UART communication pipeline designed in **SystemVerilog**, verified in **ModelSim Intel FPGA Edition**, synthesized and timing-closed in **Intel Quartus Prime**, and successfully validated on the **Terasic DE10-Lite development board**.

The system uses separate transmit and receive FIFOs to buffer data around the UART communication path. An 8-bit value entered through the DE10-Lite switches is written into the TX FIFO, serialized by the UART transmitter, received through an internal serial loopback connection, stored in the RX FIFO, and displayed on the board LEDs.

---

## Project Overview

This project implements an end-to-end FPGA UART data path using a modular dual-FIFO architecture. It integrates a UART transmitter, UART receiver, two synchronous FIFOs, pipeline control state machines, a board-level wrapper, individual module testbenches, assertion-based verification, manual functional coverage, timing constraints, and physical FPGA validation.

The design operates from the DE10-Lite’s **50 MHz system clock** and supports **115200-baud, 8-N-1 UART communication**. Timing closure was achieved with **+14.621 ns worst-case setup slack**, **+0.347 ns worst-case hold slack**, and **zero reported setup or hold violations**.

---

## Key Achievements

* Designed a complete **8-bit UART TX/RX communication pipeline** in SystemVerilog.
* Integrated **two 8-entry synchronous FIFO buffers**:

  * TX FIFO for buffering outgoing bytes.
  * RX FIFO for buffering received bytes.
* Implemented separate finite-state-machine-based control for:

  * UART transmission.
  * UART reception.
  * TX FIFO read and transmitter start sequencing.
  * RX FIFO read sequencing.
* Implemented configurable `CLKS_PER_BIT` parameters:

  * `434` for 115200-baud hardware operation at 50 MHz.
  * `4` for accelerated ModelSim verification.
* Developed individual testbenches for:

  * UART transmitter.
  * UART receiver.
  * Synchronous FIFO.
  * Integrated UART pipeline.
* Added assertion-based checks for pulse widths, FIFO safety, UART control behavior, and handshake correctness.
* Implemented manual functional coverage with **7 coverage categories**.
* Achieved **7/7 coverage bins hit**, corresponding to **100.0% of the defined manual coverage model**.
* Used directed patterns including:

  * `0x00`
  * `0xFF`
  * `0xAA`
  * `0x55`
* Added randomized byte testing to exercise low-, mid-, and high-value data ranges.
* Achieved complete TimeQuest timing closure:

  * Worst-case setup slack: **+14.621 ns**
  * Worst-case hold slack: **+0.347 ns**
  * Timing violations: **0**
* Successfully validated the full pipeline on an **Intel MAX 10 FPGA** using DE10-Lite switches, pushbutton input, and LEDs.

---

## System Architecture

![FPGA UART pipeline architecture](docs/architecture.png)

The complete data path is:

```text
DE10-Lite SW[7:0]
        │
        ▼
  +-------------+
  |   TX FIFO   |
  +-------------+
        │
        ▼
  +-------------+
  |   UART TX   |
  +-------------+
        │
        │ Serial loopback
        ▼
  +-------------+
  |   UART RX   |
  +-------------+
        │
        ▼
  +-------------+
  |   RX FIFO   |
  +-------------+
        │
        ▼
DE10-Lite LEDR[7:0]
```

### Data-flow sequence

1. The user selects an 8-bit value using `SW[7:0]`.
2. Pressing `KEY[0]` generates a one-clock-cycle write request.
3. The selected byte is written into the TX FIFO.
4. The pipeline controller reads the byte from the TX FIFO.
5. The UART transmitter creates an 8-N-1 serial frame.
6. The serial output is internally connected to the UART receiver.
7. The UART receiver reconstructs the original parallel byte.
8. `rx_done` writes the received byte into the RX FIFO.
9. The RX controller reads the byte from the RX FIFO.
10. The recovered value appears on `LEDR[7:0]`.

---

## UART Configuration

| Parameter                 |       Value |
| ------------------------- | ----------: |
| System clock              |      50 MHz |
| Hardware baud rate        | 115200 baud |
| Hardware clocks per bit   |         434 |
| Simulation clocks per bit |           4 |
| Data width                |      8 bits |
| Parity                    |        None |
| Stop bits                 |           1 |
| Frame format              |       8-N-1 |
| Transmission order        |   LSB first |
| FIFO depth                |     8 bytes |
| Number of FIFOs           |           2 |

The hardware baud setting is derived from:

```text
50,000,000 / 115,200 ≈ 434 clocks per UART bit
```

Using a parameterized design allows the same RTL to run at the real hardware rate while using a smaller value during simulation to reduce execution time.

---

## RTL Modules

### UART Transmitter — `uart_tx.sv`

The UART transmitter converts an 8-bit parallel byte into an 8-N-1 serial frame.

The transmitted frame contains:

```text
Idle → Start bit → D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7 → Stop bit
```

The transmitter sends the least-significant bit first and asserts `tx_busy` while a frame is being transmitted.

Main responsibilities:

* Latching the input byte.
* Generating the start bit.
* Sending eight data bits LSB first.
* Generating the stop bit.
* Providing transmitter busy status.
* Generating baud timing from `CLKS_PER_BIT`.

![UART TX FSM](modules/uart_tx/fsm.png)

![UART TX waveform](modules/uart_tx/waveform.png)

---

### UART Receiver — `uart_rx.sv`

The UART receiver detects the start bit, samples the incoming serial data, reconstructs the parallel byte, checks the stop-bit interval, and generates a one-clock-cycle `rx_done` pulse.

Received bits are accumulated using a right-shifting register:

```systemverilog
rx_shift_reg <= {serial_rx_in, rx_shift_reg[7:1]};
```

This correctly reconstructs the original byte because UART data arrives LSB first.

Main responsibilities:

* Start-bit detection.
* Baud-timed data sampling.
* LSB-first serial-to-parallel conversion.
* Received-bit counting.
* Stop-state handling.
* One-cycle receive-complete pulse generation.

![UART RX FSM](modules/uart_rx/fsm.png)

![UART RX waveform](modules/uart_rx/waveform.png)

---

### Synchronous FIFO — `fifo.sv`

The FIFO is an 8-bit-wide, 8-entry synchronous buffer used on both sides of the UART connection.

Two instances are used:

* **TX FIFO:** Buffers parallel input data before transmission.
* **RX FIFO:** Buffers completed receiver data before presentation at the output.

The FIFO contains:

* 8 × 8-bit memory array.
* 3-bit write pointer.
* 3-bit read pointer.
* 4-bit occupancy counter.
* `full` and `empty` status flags.
* Synchronous write and read operations.

The module-level FIFO testbench verifies:

* Reset behavior.
* Write operations.
* Read operations.
* First-in, first-out ordering.
* Full-flag behavior.
* Empty-flag behavior.
* Simultaneous read/write behavior.

![FIFO waveform](modules/fifo/waveform.png)

---

### Pipeline Top — `uart_pipeline_top.sv`

The pipeline top integrates:

* TX FIFO.
* UART transmitter.
* Internal serial loopback.
* UART receiver.
* RX FIFO.
* TX control FSM.
* RX control FSM.

The TX controller performs the sequence:

```text
WAIT → READ → START → WAIT
```

* `WAIT`: Wait for data in the TX FIFO and for the UART transmitter to become available.
* `READ`: Read one byte from the TX FIFO.
* `START`: Generate the UART transmit-start pulse.

The RX controller performs:

```text
WAIT_RX → READ_RX → WAIT_RX
```

* `WAIT_RX`: Wait until the RX FIFO contains a received byte.
* `READ_RX`: Read the received byte and update the pipeline output.

![Complete pipeline waveform](modules/pipeline/waveform.png)

---

### DE10-Lite Wrapper — `uart_pipeline_de10_lite.sv`

This is the board-specific top-level module.

It connects the reusable UART pipeline to the DE10-Lite peripherals:

| Board resource  | Function             |
| --------------- | -------------------- |
| `MAX10_CLK1_50` | 50 MHz system clock  |
| `SW[7:0]`       | Parallel input byte  |
| `SW[9]`         | Active-high reset    |
| `KEY[0]`        | Send command         |
| `LEDR[7:0]`     | Received output byte |
| `LEDR[9]`       | Reset indication     |

Because the DE10-Lite pushbuttons are active-low and asynchronous to the FPGA clock, `KEY[0]` passes through a two-flip-flop synchronizer before falling-edge detection.

```text
KEY[0]
   │
   ▼
Metastability stage
   │
   ▼
Synchronized stage
   │
   ▼
Falling-edge detector
   │
   ▼
One-clock tx_wr_en pulse
```

---

## Verification Methodology

The project follows a hierarchical verification approach:

```text
Module-level simulation
        │
        ▼
UART TX + UART RX + FIFO verification
        │
        ▼
Pipeline integration testbench
        │
        ▼
Directed and randomized test vectors
        │
        ▼
Assertion-based checks
        │
        ▼
Manual functional coverage
        │
        ▼
Quartus timing analysis
        │
        ▼
DE10-Lite hardware validation
```

Each major RTL module was tested independently before integration. This reduced debugging complexity and provided confidence in the behavior of individual building blocks before the complete pipeline was simulated.

---

## Testbenches

| RTL module             | Testbench                 | Verification focus                                               |
| ---------------------- | ------------------------- | ---------------------------------------------------------------- |
| `uart_tx.sv`           | `uart_tx_tb.sv`           | Frame generation, baud timing, bit order, busy behavior          |
| `uart_rx.sv`           | `uart_rx_tb.sv`           | Start detection, serial sampling, byte reconstruction, `rx_done` |
| `fifo.sv`              | `fifo_tb.sv`              | Reset, write, read, order, full, empty                           |
| `uart_pipeline_top.sv` | `uart_pipeline_top_tb.sv` | Complete end-to-end data flow                                    |

Representative directed patterns include:

| Pattern      | Purpose                       |
| ------------ | ----------------------------- |
| `0x00`       | All-zero boundary condition   |
| `0xFF`       | All-one boundary condition    |
| `0x55`       | Alternating `0101` pattern    |
| `0xAA`       | Alternating `1010` pattern    |
| Random bytes | Wider input-space exploration |

---

## Assertion-Based Verification

The integrated testbench instantiates a separate assertion and protocol-checking module:

```text
tb/uart_pipeline_assertions.sv
```

The verification logic checks behavior such as:

* One-clock pulse widths.
* TX FIFO write protection when full.
* TX FIFO read protection when empty.
* RX FIFO write protection when full.
* RX FIFO read protection when empty.
* UART start-bit behavior.
* Transmitter start/busy interaction.
* Receive-complete and FIFO-control sequencing.

The final assertion status reported:

```text
ASSERTION PASS: ALL PULSE WIDTH CHECKS PASSED
```

The complete assertion report is available here:

[View assertion report](modules/pipeline/assertion_report.txt)

---

## Manual Functional Coverage

The installed ModelSim Intel FPGA Edition does not provide the licensed covergroup functionality available in full Questa environments. Therefore, functional coverage was implemented using explicit counters and coverage bins.

The coverage model includes seven categories:

| Coverage bin | Description                 |
| ------------ | --------------------------- |
| `0x00`       | All zeros                   |
| `0xFF`       | All ones                    |
| `0xAA`       | Alternating pattern         |
| `0x55`       | Inverse alternating pattern |
| Low range    | `0x01`–`0x3F`               |
| Mid range    | `0x40`–`0x7F`               |
| High range   | Remaining high-value inputs |

Final result:

```text
BINS HIT : 7 / 7
COVERAGE : 100.0%
```

This value represents **100% of the explicitly defined manual functional coverage bins**, not exhaustive coverage of all possible UART states and input combinations.

The complete report is available here:

[View manual coverage report](modules/pipeline/manual_coverage_report.txt)

---

## Timing Constraints

The design includes an SDC timing-constraint file:

```text
constraints/uart_pipeline.sdc
```

The primary clock constraint is:

```tcl
create_clock -name MAX10_CLK1_50 -period 20.000 \
    [get_ports {MAX10_CLK1_50}]
```

A 20 ns period corresponds to the DE10-Lite’s 50 MHz clock.

The switches and pushbuttons are asynchronous mechanical inputs, while the LEDs are not sampled by another synchronous device. These board-level paths are handled appropriately in the timing constraints.

---

## Timing Analysis Results

TimeQuest analysis confirmed that the design meets the 50 MHz clock requirement.

| Timing metric           |            Result |
| ----------------------- | ----------------: |
| Clock frequency         |            50 MHz |
| Clock period            |         20.000 ns |
| Worst-case setup slack  |    **+14.621 ns** |
| Worst-case hold slack   |     **+0.347 ns** |
| Setup violations        |             **0** |
| Hold violations         |             **0** |
| Setup constraint status | Fully constrained |
| Hold constraint status  | Fully constrained |

Positive setup and hold slack confirm that the internal synchronous paths satisfy the required timing constraints.

![Timing analysis summary](docs/timing_summary.png)

---

## Hardware Validation

The synthesized design was programmed onto the Terasic DE10-Lite development board.

### Test procedure

1. Assert reset using `SW[9]`.
2. Set the input byte using `SW[7:0]`.
3. Release reset.
4. Press `KEY[0]` once.
5. Observe the recovered byte on `LEDR[7:0]`.

### Hardware test examples

| Switch input | Expected LED output       | Result |
| ------------ | ------------------------- | ------ |
| `0x00`       | All LEDs off              | Pass   |
| `0xFF`       | All LEDs on               | Pass   |
| `0x55`       | Alternating LEDs          | Pass   |
| `0xAA`       | Opposite alternating LEDs | Pass   |
| `0x01`       | `LEDR[0]` on              | Pass   |

The hardware test validates the complete path:

```text
Switches
   → TX FIFO
   → UART transmitter
   → Serial loopback
   → UART receiver
   → RX FIFO
   → LEDs
```

![DE10-Lite hardware validation](hardware/de10_lite_board.jpg)

The generated FPGA programming file is included in the `hardware/` directory for use with the same DE10-Lite hardware configuration.

---

## Repository Structure

```text
fpga-uart-dual-fifo-communication-pipeline/
│
├── constraints/
│   ├── DE10_LITE.qsf
│   ├── DE10_LITE.sdc
│   └── fpga_uart_pipeline.qsf
│
├── hardware/
│   └── fpga_uart_pipeline.sof
│
images/
│   ├── Waveforms/
│   │   ├── fifo_waveform.png
│   │   ├── uart_pipeline_top.png
│   │   ├── uart_rx_waveform.png
│   │   └── uart_tx_waveform.png
│
│   ├── de10_lite_board/
│   │   ├── data_in=00000000.png
│   │   ├── data_in=01000001.png
│   │   ├── data_in=01010101.png
│   │   ├── data_in=10101010.png
│   │   ├── data_in=11111111.png
│   │   └── reset=1.png
│
├── modules/
│   ├── UART_TX/
│   │   ├── uart_tx.sv
│   │   ├── uart_tx_tb.sv
│   │   └── uart_tx_waveform.png
│   │
│   ├── UART_RX/
│   │   ├── uart_rx.sv
│   │   ├── uart_rx_tb.sv
│   │   └── uart_rx_waveform.png
│   │
│   ├── FIFO/
│   │   ├── fifo.sv
│   │   ├── fifo_tb.sv
│   │   └── fifo_waveform.png
│   │
│   └── UART_PIPELINE_TOP/
│       ├── UART_Pipeline_Assertion_Report.txt
│       ├── manual_coverage_report.txt
│       ├── uart_pipeline_simulation_report.txt
│       ├── uart_pipeline_top.png
│       ├── uart_pipeline_top.sv
│       └── uart_pipeline_top_tb.sv
│
├── quartus_project/
│   ├── DE10_LITE.qsf
│   └── fpga_uart_pipeline.qpf
│
├── rtl/
│   ├── uart_tx.sv
│   ├── uart_rx.sv
│   ├── fifo.sv
│   ├── uart_pipeline_top.sv
│   └── uart_pipeline_de10_lite.sv
│ 
├── scripts/
│   ├── run_uart_tx.do
│   ├── run_uart_rx.do
│   ├── run_fifo.do
│   ├── run_uart.do
│   └── pipe_run_uart.do
│ 
├── tb/
│   ├── uart_tx_tb.sv
│   ├── uart_rx_tb.sv
│   ├── fifo_tb.sv
│   ├── uart_pipeline_top_tb.sv
│   ├── uart_pipeline_assertions.sv
│   └── uart_pipeline_coverage.sv
│
├── docs/
│   ├── architecture.png
│   └── timing_summary.png
│
├── README.md
├── LICENSE
├── .gitignore
│
└── 
```

---

## Running the Simulation

The `.do` files in the `scripts/` directory compile the required RTL and testbench files and start the corresponding simulation.

Example pipeline simulation:

```tcl
vlib work

vlog rtl/fifo.sv
vlog rtl/uart_tx.sv
vlog rtl/uart_rx.sv
vlog rtl/uart_pipeline_top.sv

vlog tb/uart_pipeline_assertions.sv
vlog tb/uart_pipeline_coverage.sv
vlog tb/uart_pipeline_top_tb.sv

vsim work.uart_pipeline_top_tb
add wave -r /*
run -all
```

The testbench overrides the hardware baud parameter:

```systemverilog
uart_pipeline_top #(
    .CLKS_PER_BIT(4)
) dut (
    // Connections
);
```

This shortens simulation time while preserving the same clock-cycle-based UART behavior.

---

## Programming the DE10-Lite

1. Open the Quartus project.
2. Compile the design.
3. Open **Tools → Programmer**.
4. Select **USB-Blaster**.
5. Select JTAG programming mode.
6. Add the generated `.sof` file.
7. Enable **Program/Configure**.
8. Click **Start**.
9. Confirm that programming reaches `100% Successful`.

The included `.sof` file can also be loaded directly when using the same board and device configuration.

---

## Engineering Lessons Demonstrated

This project demonstrates more than an isolated UART implementation. It covers a complete FPGA development workflow:

* Translating a serial protocol into synchronous RTL.
* Building finite state machines for protocol and pipeline control.
* Using FIFO buffering to decouple producer and consumer timing.
* Parameterizing timing-sensitive modules for simulation and hardware.
* Reconstructing LSB-first serial data correctly.
* Writing module-level and integration-level testbenches.
* Using assertions to detect invalid temporal behavior.
* Building a manual functional coverage model when simulator features are limited.
* Debugging differences between simulation and real hardware.
* Synchronizing asynchronous pushbutton inputs.
* Creating and interpreting SDC timing constraints.
* Achieving setup and hold timing closure.
* Programming and validating an FPGA implementation on physical hardware.

---

## Tools and Technologies

* **HDL:** SystemVerilog
* **Simulator:** ModelSim Intel FPGA Edition 10.5b
* **FPGA software:** Intel Quartus Prime Lite 16.1
* **Timing analysis:** Intel TimeQuest
* **Target board:** Terasic DE10-Lite
* **FPGA device:** Intel MAX 10
* **Clock frequency:** 50 MHz
* **Communication protocol:** UART, 8-N-1
* **Hardware baud rate:** 115200 baud

---

## Future Improvements

Possible future extensions include:

* Pushbutton debounce logic.
* External UART connection to a PC through a USB-to-UART adapter.
* Python-based serial monitoring and automated data checking.
* Configurable parity and stop-bit settings.
* Configurable FIFO depth and data width.
* UART framing-error detection.
* FIFO overflow and underflow status outputs.
* Continuous or burst-mode data transmission.
* Hardware SignalTap debugging.
* Integration with an ADC-based FPGA data-acquisition system.

---

## Project Status

**Completed**

* RTL design: Complete
* Module-level simulation: Complete
* Pipeline integration: Complete
* Assertion-based verification: Complete
* Manual functional coverage: Complete
* Timing constraints: Complete
* Timing closure: Complete
* DE10-Lite hardware validation: Complete

---

## Author

Developed as an FPGA RTL design, verification, timing-analysis, and hardware-integration portfolio project.
