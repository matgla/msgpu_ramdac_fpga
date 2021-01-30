module clock_divider(
    input clkin,
    int div,
    output reg clkout
);

int counter = 32'h0;

always @(posedge clkin) begin
    counter <= counter + 1'b1;
    if (counter >= div - 1) begin 
        counter <= 0;
    end

    clkout <= (counter < div / 2) ? 1 : 0;
end

endmodule
