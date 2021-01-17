`define NANO 

module msgpu_nano(
    input clock,
    input mcu_bus_clock,
    inout [7:0] mcu_bus,
    input mcu_bus_command_data,
    output hsync,
    output vsync,
    output [3:0] vga_red,
    output [3:0] vga_green,
    output [3:0] vga_blue,
    output led,
    output psram_ce_n,
    output psram_clk,
    inout wire[3:0] psram_sio
);

msgpu msgpu(
    .clock(clock),
    .mcu_bus_clock(mcu_bus_clock),
    .mcu_bus(mcu_bus),
    .mcu_bus_command_data(mcu_bus_command_data),
    .hsync(hsync),
    .vsync(vsync),
    .vga_red(vga_red),
    .vga_green(vga_green),
    .vga_blue(vga_blue),
    .led(led),
    .psram_ce_n(psram_ce_n),
    .psram_clk(psram_clk),
    .psram_sio(psram_sio)
);

endmodule 

