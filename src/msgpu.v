`include "commands.v"
`include "vga_commands.v"
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
    inout wire[3:0] psram_sio
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
    .div(4),
    .clkout(vga_clock)
);

assign system_clock = clock;

`endif


/********************************/
/********************************/
/**          MCU BUS           **/
/********************************/
/********************************/

/* DATA PATH */ 
// MCU -> FRAMEBUFFER_MEMORY -> FIFO -> VGA 
// bus clock   system clock        vga clock 

wire message_pixel_clock;
wire message_command_clock;
wire[7:0] pixel_data;

message_broker broker(
    .system_clock(system_clock),
    .mcu_bus_clock(mcu_bus_clock),
    .mcu_bus(mcu_bus),
    .mcu_bus_command_data(mcu_bus_command_data),
    .mcu_pixel_clock(message_pixel_clock),
    .mcu_command_clock(message_command_clock),
    .pixel_data(pixel_data)
);

wire[21:0] framebuffer_read_pointer;

wire[11:0] read_data;


pixel_memory pixel_memory(
    .system_clock(system_clock),
    .pixel_data(pixel_data),
    .pixel_clock(message_pixel_clock),
    .framebuffer_read_pointer(framebuffer_read_pointer),
    .read_data(read_data)
);

/********************************/
/********************************/
/**         VGA SECTION        **/
/********************************/
/********************************/
reg vga_enable;
reg vga_reset; 

wire vga_reset_sig = vga_reset;

vga vga_instance(
    /* verilator lint_off IMPLICIT */
    .reset(vga_reset_sig),
    .clock(vga_clock),
    .enable(vga_enable),
    .hsync(hsync),
    .vsync(vsync),
    .red(vga_red),
    .green(vga_green),
    .blue(vga_blue),
    .buffer_clock(system_clock),
    .read_address(framebuffer_read_pointer),
    .pixel_data(read_data)
);

localparam STATE_INITIALIZATION = 0;
localparam STATE_WAITING_FOR_INITIALIZATION = 1;
localparam STATE_START_FIFO_SYNC = 2;
localparam STATE_WAITING_FOR_START_VGA = 3;
localparam STATE_ENABLE_VGA = 4;
localparam STATE_RESET_VSYNC = 5;

reg [4:0] counter;
reg [3:0] state;

always @(posedge system_clock) begin
    case (state)
        STATE_INITIALIZATION: begin 
            $display("Initialization");
            counter <= 0;
            vga_reset <= 0;
            state <= STATE_WAITING_FOR_INITIALIZATION;
        end
        STATE_WAITING_FOR_INITIALIZATION: begin 
           // if (message_command_clock) begin 
                $display("Command: %d", mcu_bus);
                //if (mcu_bus == 8'd2) begin 
                    $display("Waiting for VGA start");
                    counter <= 0;
                    state <= STATE_START_FIFO_SYNC;
                    vga_reset <= 1;
               // end
            //end
        end
        STATE_START_FIFO_SYNC: begin 
            state <= STATE_WAITING_FOR_START_VGA;
            vga_reset <= 0;
        end
        STATE_WAITING_FOR_START_VGA: begin 
            if (counter == 7) begin 
                counter <= 0;
                state <= STATE_ENABLE_VGA;
            end 
            counter <= counter + 1;
        end
        STATE_ENABLE_VGA: begin 
            vga_enable <= 1;
        end
        STATE_RESET_VSYNC: begin 
        end
        default: begin 
            state <= STATE_INITIALIZATION;
        end
    endcase
end

assign led = 1'b0;
always @(posedge psram_clock) begin 
end

assign psram_ce_n = 1'b0;
assign psram_clk = 1'b0;

endmodule

`resetall
