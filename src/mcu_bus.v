module mcu_bus (
    input sysclk,
    input busclk,
    inout [7:0] bus,
    input enable,
    input command_data,
    output reg [7:0] data_out,
    output reg [1:0] led
);

reg [2:0] SCKr;
always @(posedge sysclk) SCKr <= {SCKr[1:0], busclk};
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges
wire sck_on = (SCKr[2:1]==2'b11);  // and falling edges
wire sck_off = (SCKr[2:1]==2'b00);  // and falling edges

always @(posedge sysclk) begin
    led <= 2'b11;
    if (enable) begin
        led <= 2'b01;
        if (SCK_risingedge) begin
            if (bus == 8'hff) begin
                led <= 2'b00;
            end
            else begin
                led <= 2'b10;
            end
        end
    end
    // if (SCK_risingedge) begin
    //     led <= 2'b00;
    //     // if (bus[1] == 1'b1) begin
    //     // end
    //     // if (bus[1] == 1'b0) begin
    //     //     led <= 2'b01;
    //     // end
    // end

    // if (sck_off) led <= 2'b00;

    // data_out <= bus;
end

endmodule
