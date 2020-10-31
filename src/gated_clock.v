module gated_clock(
    input clock,
    input enable,
    output reg clock_output
);

assign clock_output = enable ? clock : 1'b0;

endmodule
