module fifo (
    input clockin,
    input [7:0] datain,
    output [7:0] dataout,
    input datain_enable,
    input dataout_enable,
    input reset,
    fifo_full,
    fifo_empty
)
