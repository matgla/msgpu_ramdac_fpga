`include "commands.v"

module msgpu (
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
    inout reg[3:0] psram_sio
);

`ifdef NANO
pll vga_pll(
    /* verilator lint_off IMPLICIT */
   .clkout(CLOCK_SYS),  // It's 201.6 MHz,
    /* verilator lint_off IMPLICIT */
   .clkoutd(CLOCK_PIXEL), // It's 25.175 MHz
   .clkin(clock)
);
`endif

reg[11:0] vga_data;

vga vga_instance(
    /* verilator lint_off IMPLICIT */
    .clock(CLOCK_PIXEL),
    .data(vga_data),
    .hsync(hsync),
    .vsync(vsync),
    .visible_area(visible_area),
    .red(vga_red),
    .green(vga_green),
    .blue(vga_blue)
);

reg write;
reg clock_to_psram;

psram framebuffer(
    .reset(reset),
    .sysclk(CLOCK_PIXEL),
    .psram_sclk(psram_clk),
    .psram_ce_n(psram_ce_n),
    .psram_sio_in(psram_sio),
    .psram_sio_out(psram_sio),
    .debug_led(led),
    .enable(enable),
    .address(psram_address),
    .rw(rw),
    .data(data_to_psram),
    .next_byte_needed(next_byte),
    .write(write),
    .clock(clock_to_psram)
);

always @(posedge CLOCK_PIXEL) begin
    if (visible_area) begin

    end
end

reg[7:0] data;
reg dataclk;
reg cmdclk;
reg[31:0] address;

mcu_bus mcu(
    .sysclk(clock),
    .busclk(mcu_bus_clock),
    .bus_in(mcu_bus[7:0]),
    .bus_out(mcu_bus[7:0]),
    .dataclk(dataclk),
    .cmdclk(cmdclk),
    .address(address),
    .command_data(mcu_bus_command_data),
    .data_out(data),
    .led(led)
);

reg reset;
reg enable;
reg rw;
reg[7:0] data_to_psram;
reg next_byte;
reg[23:0] psram_address;



always @(posedge clock) begin
    if (dataclk) begin
        $display("data received: %x", data);
    end
    if (cmdclk) begin
        case (data)
            `SET_ADDRESS: begin
                $display("address received: %x", address);
            end
            default: begin end
        endcase

    end
end

reg write_enable = 1'b0;

// psram frame_buffer(
//     .enable(write_enable)
// );

// assign led[2:0] = (data == 8'hffffffff)? 3b'110 : 3b'101;
// assign led = (data == 8'hff)? 2'b10 : 2'b01;

// assign vga_red = (visible_area)? 4'b1111 : 4'b0000;
// assign vga_blue = (visible_area)? 4'b1111 : 4'b0000;
// assign vga_green = (visible_area)? 4'b1111 : 4'b0000;

endmodule
