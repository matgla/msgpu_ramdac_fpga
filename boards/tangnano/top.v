module top(
    input clock, 
    output wire led,
    /* VGA */ 
    output wire hsync,
    output wire vsync,
    output wire[3:0] vga_red,
    output wire[3:0] vga_green,
    output wire[3:0] vga_blue,
    /* VGA END */
    /* MCU BUS */
    input wire mcu_bus_clock,
    input wire [7:0] mcu_bus,
    input wire mcu_bus_command_data,
    /* MCU BUS END */
    output psram_sclk, 
    output psram_ce_n, 
    inout[3:0] psram_sio
);

wire system_clock; // 201.6 MHz 
wire vga_clock; // 25.175 MHz 
wire psram_clock; //67.3 MHz 

pll pll_instance(
    .clkout(system_clock),
    .clkoutd(vga_clock),
    .clkin(clock)
);

reg psram_reset;

clock_divider divider(
    .clkin(system_clock),
    .div(3),
    .clkout(psram_clock)
);

wire[3:0] psram_sio_out;
wire[3:0] psram_sio_in;
wire[3:0] psram_sio_dir;
assign psram_sio_in = psram_sio;
genvar i;
generate
    for (i = 0; i < 4; i=i+1) begin 
        assign psram_sio[i] = psram_sio_dir[i] ? psram_sio_out[i] : 1;
    end
endgenerate

reg psram_enable;
reg psram_rw;
wire next_byte_needed;
reg psram_set_address;
reg psram_write_data;
reg psram_address;
reg[7:0] psram_byte;
psram psram(
    .reset(psram_reset),
    .sysclk(psram_clock),
    .psram_sclk(psram_sclk),
    .psram_ce_n(psram_ce_n),
    .psram_sio_in(psram_sio_in),
    .psram_sio_out(psram_sio_out),
    .debug_led(led),
    .enable(psram_enable),
    .rw(psram_rw),
    .next_byte_needed(next_byte_needed),
    .set_address(psram_set_address),
    .write_data(psram_write_data),
    .address(psram_address),
    .data(psram_byte)
);

msgpu #(.VGA_RED_BITS(4),
    .VGA_GREEN_BITS(4),
    .VGA_BLUE_BITS(4),
    .LED_BITS(1)
)
msgpu_instance(
    .system_clock(system_clock),
    .vga_clock(vga_clock),
    // .led(led),
    .vga_vsync(vsync),
    .vga_hsync(hsync),
    .vga_red(vga_red),
    .vga_green(vga_green),
    .vga_blue(vga_blue),
    .mcu_bus_clock(mcu_bus_clock),
    .mcu_bus(mcu_bus),
    .mcu_bus_command_data(mcu_bus_command_data)
);

endmodule
