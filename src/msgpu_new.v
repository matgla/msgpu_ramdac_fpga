module msgpu #(
    parameter VGA_RED_BITS = 3, 
    parameter VGA_GREEN_BITS = 3, 
    parameter VGA_BLUE_BITS = 3,
    parameter LED_BITS = 1
)(
    input system_clock,
    
    output reg[LED_BITS - 1:0] led,
    /* ---- VGA ---- */ 
    input vga_clock,
    output vga_hsync,
    output vga_vsync,
    output [VGA_RED_BITS - 1:0] vga_red,
    output [VGA_GREEN_BITS - 1:0] vga_green, 
    output [VGA_BLUE_BITS - 1:0] vga_blue,
    /* -END-VGA-END- */
    /* -- MCU BUS -- */ 
    input wire mcu_bus_clock,
    input wire [7:0] mcu_bus, 
    input wire mcu_bus_command_data 
    /* ---- END ---- */
);

// assign led = LED_BITS;

reg reset_vga;
reg enable_vga;

wire[21:0] read_address;

always @(posedge system_clock) begin 
    enable_vga = 1;
end

vga #(
    .RED_BITS(VGA_RED_BITS), 
    .GREEN_BITS(VGA_GREEN_BITS), 
    .BLUE_BITS(VGA_BLUE_BITS)
)
vga_instance (
    .reset(reset_vga),
    .clock(vga_clock),
    .enable(enable_vga),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .red(vga_red),
    .green(vga_green),
    .blue(vga_blue),
    .buffer_clock(system_clock),
    .read_address(read_address),
    .pixel_data(pixel_data)
);

wire mcu_command_clock;
wire mcu_data_clock; 
wire [7:0] mcu_data;

mcu_bus mcu(
    .sysclk(system_clock),
    .busclk(mcu_bus_clock),
    .bus_in(mcu_bus[7:0]),
    .bus_out(mcu_bus[7:0]),
    .dataclk(mcu_data_clock),
    .cmdclk(mcu_command_clock),
    .address(mcu_address),
    .command_data(mcu_bus_command_data),
    .data_out(mcu_data)
    // .led(led)
);

reg [22:0] counter;

reg [63:0] buffer;

always @(posedge mcu_data_clock) begin 
    //..led <= mcu_data == 8'h12 ? 0 : 1;
    //if (mcu_data == 8'h0f) led = ~led;
    //if (mcu_data == 0) led = 1;
    //if (mcu_data == 8'h00) led = 1;
    //else if (mcu_data == 8'hf0) led = 0;
    //led <= ~led;
    buffer <= { buffer[31:0], mcu_data };
    //if (buffer == 16'h0ff0) led <= ~led;
    if (buffer == 32'h0ff0ab12) led <= ~led;
end

//always @(posedge system_clock) begin 
//    led <= 1;
//end

//reg[22:0] counter;

//reg [1:0] bus_buffer;
//always @(posedge system_clock) bus_buffer <= {bus_buffer[0], mcu_bus_clock};
//wire risingedge = (bus_buffer == 2'b01);

//always @(posedge system_clock) begin 
//    if (risingedge) begin 
//        counter <= counter + 1;
//        //led <= 1;
//        if (counter == 100000) begin 
//            if (led == 1) led <= 0; else led <= 1;
//            counter <= 0;
//        end
//    end
//end

endmodule 
