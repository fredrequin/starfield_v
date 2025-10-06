// Trace configuration
// -------------------
`verilator_config

tracing_off -file "../rtl/sp_ram_512x18b.v"
tracing_on  -file "../rtl/video_gen.v"
tracing_on  -file "../rtl/video_starfield.v"
tracing_on  -file "../rtl/video_top.v"

`verilog

`include "../rtl/sp_ram_512x18b.v"
`include "../rtl/video_gen.v"
`include "../rtl/video_starfield.v"
`include "../rtl/video_top.v"
