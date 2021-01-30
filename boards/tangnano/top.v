
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
    inout wire [7:0] mcu_bus,
    inout wire mcu_bus_command_data,
    /* MCU BUS END */
    output wire psram_sclk, 
    output psram_ce_n, 
    inout[3:0] psram_sio,
    input sys_reset_n
);

wire system_clock; // 201.6 MHz 
wire vga_clock; // 25.175 MHz 
wire psram_clock; //67.3 MHz 
wire clock_out;

pll pll_instance(
    .clkout(clock_out),
    .clkoutd(vga_clock),
    .clkin(clock)
);

//assign psram_sclk = clock;

reg[7:0] counter;

reg[31:0] led_counter;

wire osc_clock;

OSCH osc( 
    .OSCOUT(system_clock)
);

defparam osc.FREQ_DIV = 2;

clock_divider divider(
    .clkin(system_clock),
    .div(3),
    .clkout(psram_clock)
);


wire[3:0] psram_sio_in;
wire[3:0] psram_sio_dir;
assign psram_sio_in = psram_sio;
genvar i;
generate
    for (i = 0; i < 4; i=i+1) begin : psram_sio_direction_assignment
        assign psram_sio[i] = psram_sio_dir[i] ? bus.signal_output[i] : 1'bz;
    end
endgenerate

SpiBus bus(psram_clock, psram_sclk);

//assign psram_sclk = bus.sclk;
assign psram_ce_n = bus.ce;
assign bus.signal_input = psram_sio_in;
assign psram_sio_dir = bus.signal_direction;

MemoryInterface memory();

psram psram(
    .sysclk(psram_clock),
    .bus(bus),
    .memory(memory)
);

wire[7:0] mcu_bus_output;
wire[7:0] mcu_bus_input;
wire mcu_bus_direction;
wire mcu_bus_command_data_output_signal;

generate 
    for (i = 0; i < 8; i = i + 1) begin : mcu_bus_direction_assignment
        assign mcu_bus[i] = mcu_bus_direction ? mcu_bus_output[i] : 1'b1z;
    end
endgenerate 

assign mcu_bus_command_data = mcu_bus_direction ? mcu_bus_command_data_output_signal : 1'bz;

wire mcu_bus_system_clock = system_clock;
McuBusExternalInterface mcu_bus_interface(
    .system_clock(system_clock)
); 

assign mcu_bus_output = mcu_bus_interface.signal_output;
assign mcu_bus_direction = mcu_bus_interface.signal_direction; 
assign mcu_bus_interface.signal_input = mcu_bus; 
assign mcu_bus_interface.bus_clock = mcu_bus_clock; 
assign mcu_bus_interface.signal_command_data_input = mcu_bus_command_data;
assign mcu_bus_command_data_output_signal = mcu_bus_interface.signal_command_data_output;

msgpu #(.VGA_RED_BITS(4),
    .VGA_GREEN_BITS(4),
    .VGA_BLUE_BITS(4),
    .LED_BITS(1)
)
msgpu_instance(
    .system_clock(system_clock),
    .vga_clock(vga_clock),
    .led(led),
    .vga_vsync(vsync),
    .vga_hsync(hsync),
    .vga_red(vga_red),
    .vga_green(vga_green),
    .vga_blue(vga_blue),
    .mcu_bus(mcu_bus_interface),
    .memory(memory)
);

endmodule
