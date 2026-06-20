# FPGA-UART-Data-Streaming-System-Ongoing-Project-
This project implements a UART-based data streaming system on FPGA to transmit structured data to a PC via a USB-to-UART bridge (CP2102). The design is currently under active development and serves as a foundation for a larger FPGA-based data acquisition and processing pipeline.

## Current Implementation
### Implemented Features
- UART Transmitter module (SystemVerilog)

- Periodic data generation on FPGA

- FPGA → CP2102 serial communication

- PC-side reception using terminal tools (PuTTY / Tera Term)

### Working Demonstration
- FPGA successfully transmits continuous data stream

- PC receives live serial data via UART at 115200 baud

- System verified on hardware (DE10-Lite FPGA board)

### Hardware Setup
- FPGA Board: DE10-Lite (Intel MAX 10)

- UART Bridge: CP2102 USB-to-UART

- Baud Rate: 115200

- Communication: FPGA TX → CP2102 RX, shared GND

### Project Status (Ongoing Development)

This project is actively being extended with:

- FIFO-based buffering system for reliable streaming

- Python-based real-time data visualization

- UART receive path for bidirectional communication

- Formal verification using testbenches and simulation

### Next Steps
- Integrate FIFO between data generator and UART transmitter

- Replace terminal output with Python serial interface

- Implement data packet structure and checksum validation

- Add simulation-based verification environment

### Key Learning Outcomes
- UART protocol implementation in FPGA (SystemVerilog)

- Clock-driven data generation and timing control

- FPGA-to-PC serial communication pipeline

- Hardware debugging using real-time serial monitoring
