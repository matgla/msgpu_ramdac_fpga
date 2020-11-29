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

/*****************************/
/*****************************/
/**         CLOCKS          **/
/*****************************/
/*****************************/

wire vga_clock; // 201.6 MHz
wire system_clock; // 25.175 MHz
wire psram_clock; // 67.3 MHz

clock_divider clock_divider_for_psram(
    .clkin(system_clock),
    .div(3),
    .clkout(psram_clock)
);

`ifdef NANO
pll vga_pll(
    /* verilator lint_off IMPLICIT */
   .clkout(system_clock),  // It's 201.6 MHz,
    /* verilator lint_off IMPLICIT */
   .clkoutd(vga_clock), // It's 25.175 MHz
   .clkin(clock)
);
`else
// For simulation purposes //
clock_divider vga_clock_divider(
    .clkin(clock),
    .div(8),
    .clkout(vga_clock)
);

assign system_clock = clock;

`endif

/********************************/
/********************************/
/**          MCU BUS           **/
/********************************/
/********************************/

wire mcu_data_clock;
wire mcu_command_clock;
reg [31:0] mcu_address;
reg [7:0] mcu_data;

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
);

// data from bus goes directly to data fifo
reg reset_bus_fifo;
wire reset_bus_fifo_n;
assign reset_bus_fifo_n = !reset_bus_fifo;

wire is_bus_fifo_full;
wire is_bus_fifo_almost_full;
wire is_bus_fifo_empty;
wire is_bus_fifo_almost_empty;
reg fifo_write_enable;

// wire psram_write_clock = n

reg[11:0] pixel_data;
reg is_second_byte;

always @(posedge dataclk) begin
    if (!is_second_byte) begin
        pixel_data[11:4] = mcu_data;
        is_second_byte <= 1'b1;
    end else begin
        pixel_data[3:0] = mcu_data[3:0];
        is_second_byte <= 1'b0;
        fifo_write_enable <= 1'b1;
    end
end

always @(posedge dataclk) begin
    fifo_write_enable <= 1'b0;
end

async_fifo #(.DSIZE(640), .ASIZE(12), .FALLTHROUGH("FALSE"))
bus_fifo(
    .wclk(dataclk),
    .wrst_n(reset_bus_fifo),
    .winc(fifo_write_enable),
    .wdata(mcu_data),
    .wfull(is_bus_fifo_full),
    .awfull(is_bus_fifo_almost_full),
    .rclk()
);

// FIFO from MCU to PSRAM



/********************************/
/********************************/
/**         VGA SECTION        **/
/********************************/
/********************************/

// FIFO from PSRAM to VGA

// reg[11:0] vga_data;

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

// reg write;
// reg set_address;
// reg clock_to_psram;

// psram framebuffer(
//     .reset(reset),
//     .sysclk(clock),
//     .psram_sclk(psram_clk),
//     .psram_ce_n(psram_ce_n),
//     .psram_sio_in(psram_sio),
//     .psram_sio_out(psram_sio),
//     .debug_led(led),
//     .enable(enable),
//     .address(psram_address),
//     .rw(rw),
//     .data(data_to_psram),
//     .next_byte_needed(next_byte),
//     .set_address(set_address),
//     .write_data(clock_to_psram)
// );

// reg [7:0] from_data_fifo;

// wire is_data_fifo_empty;
// wire is_data_fifo_almost_empty;
// wire is_data_fifo_full;
// wire is_data_fifo_almost_full;
// reg reset_data_fifo;
// reg increment_fifo_write;
// reg increment_fifo_read;
// wire reset_data_n;
// assign reset_data_n = !reset_data_fifo;
// reg read_data_fifo;

// async_fifo #(.DSIZE(8), .ASIZE(8), .FALLTHROUGH("TRUE"))
// data_fifo (
//     .wclk(dataclk),
//     .wrst_n(reset_data_n),
//     .winc(dataclk),
//     .wdata(data),
//     .wfull(is_data_fifo_full),
//     .awfull(is_data_fifo_almost_full),
//     .rclk(CLOCK_PIXEL && visible_area),
//     .rrst_n(reset_data_n),
//     .rinc(increment_fifo_read),
//     .rdata(from_data_fifo),
//     .rempty(is_data_fifo_empty),
//     .arempty(is_data_fifo_almost_empty));

// always @(posedge CLOCK_PIXEL) begin
//     if (visible_area) begin
//         if (!is_data_fifo_empty) begin
//             increment_fifo_read = 1'b1;
//             $display("Data from fifo: %x", from_data_fifo);
//         end else begin
//             increment_fifo_read = 1'b0;
//             $display("Data from fifo: %x", 0);
//         end
//     end
// end

// reg[7:0] data;
// reg dataclk;
// reg cmdclk;
// reg[31:0] address;

// mcu_bus mcu(
//     .sysclk(clock),
//     .busclk(mcu_bus_clock),
//     .bus_in(mcu_bus[7:0]),
//     .bus_out(mcu_bus[7:0]),
//     .dataclk(dataclk),
//     .cmdclk(cmdclk),
//     .address(address),
//     .command_data(mcu_bus_command_data),
//     .data_out(data),
//     .led(led)
// );

// reg reset;
// reg enable;
// reg rw;
// reg[7:0] data_to_psram;
// reg next_byte;
// reg[23:0] psram_address;

// reg[23:0] video_address;

// reg address_set_correctly;

// reg [3:0] msgpu_state;
// reg [3:0] task_counter;

// task set_framebuffer_address;
// input [23:0] new_address;
// reg [3:0] next_state;
// begin
//     // case (task_counter)
//     $display("Sending address change to psram: %x", new_address);
//     psram_address <= new_address;
//     set_address <= 1'b1;

// end
// endtask

// // always @(posedge )
// reg was_initialized;

// always @(posedge clock) begin
//     if (!was_initialized) begin
//         reset_data_fifo <= 1'b1;
//         was_initialized <= 1'b1;
//     end
//     else begin
//         reset_data_fifo <= 1'b0;
//     end
//     if (cmdclk) begin
//         $display("Command received: %x", data);
//         case (data)
//             `SET_ADDRESS: begin
//                 $display("address received: %x", address[31:8]);
//                 set_framebuffer_address(address[31:8]);
//             end
//             default: begin end
//         endcase

//     end
// end

// reg write_enable = 1'b0;

// // psram frame_buffer(
// //     .enable(write_enable)
// // );

// // assign led[2:0] = (data == 8'hffffffff)? 3b'110 : 3b'101;
// // assign led = (data == 8'hff)? 2'b10 : 2'b01;

// // assign vga_red = (visible_area)? 4'b1111 : 4'b0000;
// // assign vga_blue = (visible_area)? 4'b1111 : 4'b0000;
// // assign vga_green = (visible_area)? 4'b1111 : 4'b0000;

endmodule

`resetall
