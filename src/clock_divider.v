module clock_divider(
    input clkin,
    input[7:0] div,
    output reg clkout
);

reg[7:0] counter = 8'h0;

always @(posedge clkin or negedge clkin) begin
    if (clkin) begin
        if (counter + 8'h1 >= div) begin
            if (clkout == 1'b0) begin
                clkout <= 1'b1;
            end
        end
    end
    else begin
        if (counter + 8'h1 >= div) begin
            if (clkout == 1'b1) begin
                clkout <= 1'b0;
            end
        end
    end

    if (!clkin) begin
        counter <= counter + 8'h1;
    end
end

endmodule
