vlib work
vmap work work
vlog fifo.sv
vlog uart_tx.sv
vlog uart_rx.sv
vlog uart_pipeline_top.sv
vlog uart_pipeline_assertions.sv
vlog uart_pipeline_coverage.sv
vlog uart_pipeline_top_tb.sv

vsim  work.uart_pipeline_top_tb

add wave -r *

run -all

