module mcu_bus (
    input sysclk,
    input busclk,
    inout [7:0] bus,
    input command_data,
    output reg [7:0] data_out,
    output reg led
);

reg [3:0] SCKr;
always @(posedge sysclk) SCKr = {SCKr[2:0], busclk};
wire SCK_risingedge = (SCKr[3:1]==3'b011);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[3:1]==3'b110);  // and falling edges

reg [8:0] delay_counter;

//always @(posedge sysclk) begin
//    if (SCK_risingedge) begin
//        delay_counter = 3'd7;
//    end
//     if (SCK_risingedge) begin
//         led <= 2'b00;
         // if (bus[1] == 1'b1) begin
         // end
         // if (bus[1] == 1'b0) begin
         //     led <= 2'b01;
         // end
//     end

//     if (sck_off) led <= 2'b00;

//     data_out <= bus;
//end

always @(posedge sysclk) begin 
    if (delay_counter != 3'd0) begin
        delay_counter = delay_counter - 1;
    end

    if (SCK_risingedge) begin
        delay_counter = 3'd14;
    end

    if (delay_counter == 3'd1) begin 
        if (bus == 8'hff) begin 
            led = 1;
        end 
        if (bus == 8'h00) begin 
            led = 0;
        end 
    end 
    
end


endmodule
