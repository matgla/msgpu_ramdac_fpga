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

/* DATA PATH */ 
// MCU -> FRAMEBUFFER_MEMORY -> FIFO -> VGA 
// bus clock   system clock        vga clock 

wire message_pixel_clock;
wire message_command_clock;
wire[7:0] command_data;
reg[11:0] pixel_data;

message_broker broker(
    .system_clock(system_clock),
    .mcu_bus_clock(mcu_bus_clock),
    .mcu_bus(mcu_bus),
    .mcu_bus_command_data(mcu_bus_command_data),
    .mcu_pixel_clock(message_pixel_clock),
    .mcu_command_clock(message_command_clock),
    .command_data(command_data),
    .pixel_data(pixel_data)
);

reg[21:0] framebuffer_read_pointer;
reg[21:0] framebuffer_write_pointer;
reg framebuffer_write_enable;
reg bus_fifo_write_enable;


reg [1:0] receiver_state;
reg pixel_received_flag;
reg [2:0] pixel_received;

reg [12:0] line_read_pointer;
reg [12:0] line_write_pointer;
reg line_write_enable;
reg [11:0] line_data;
reg [11:0] read_data;
dual_port_ram #(.DATA_WIDTH(12), .ADDRESS_SIZE(13))
line_buffer(
    .data(read_data),
    .read_address(line_read_pointer),
    .write_address(line_write_pointer),
    .write_enable(line_write_enable),
    .write_clock(system_clock),
    .read_clock(system_clock),
    .output_data(line_data)
);

reg set_write_address;

pixel_memory pixel_memory(
    .system_clock(system_clock),
    .pixel_data(pixel_data),
    .pixel_clock(message_pixel_clock),
    .framebuffer_read_pointer(framebuffer_read_pointer),
    .write_address(framebuffer_write_pointer),
    .set_write_address(set_write_address),
    .read_data(read_data)
);

/********************************/
/********************************/
/**         VGA SECTION        **/
/********************************/
/********************************/
wire visible_area;
wire almost_visible_area;
reg vga_enable;

wire line_finished;

vga vga_instance(
    /* verilator lint_off IMPLICIT */
    .enable(vga_enable),
    .clock(vga_clock),
    .address(line_read_pointer),
    .data(line_data),
    .hsync(hsync),
    .vsync(vsync),
    .visible_area(visible_area),
    .red(vga_red),
    .green(vga_green),
    .blue(vga_blue),
    .almost_visible_area(almost_visible_area),
    .line_finished(line_finished)
);

reg vga_prepare;
reg initialize;

reg [2:0] vga_state;

reg [31:0] line_display_counter;
reg [31:0] pixel_display_counter;

reg [11:0] line_counter;

reg [2:0] line_finished_buffer;
always @(posedge system_clock) line_finished_buffer <= {line_finished_buffer[1:0], line_finished};
wire line_end_posedge = line_finished_buffer[1:0] == 2'b01;

reg[11:0] copied;
reg second_line;

reg reset_sync;

always @(posedge system_clock or posedge reset_sync) begin 
    if (reset_sync) begin
        line_write_pointer <= 0;
        framebuffer_read_pointer <= 0;
        copied <= 0;
    end
    if (copied < 640) begin
        if (!line_write_enable) begin 
            framebuffer_read_pointer <= framebuffer_read_pointer + 1;
            line_write_enable <= 1;
        end else begin 
            line_write_pointer <= line_write_pointer + 1;
            framebuffer_read_pointer <= framebuffer_read_pointer + 1;
            copied <= copied + 1;
        end
    end else begin 
        line_write_enable <= 0;
    end

    if (line_end_posedge) begin 
        copied <= 0;
        line_write_enable <= 0;
        framebuffer_read_pointer <= framebuffer_read_pointer - 1;
        if (second_line) begin 
            line_write_pointer <= 0;
            second_line <= 0;
        end else begin 
            second_line <= 1;
        end
    end
end

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
            state <= STATE_WAITING_FOR_INITIALIZATION;
        end
        STATE_WAITING_FOR_INITIALIZATION: begin 
            if (message_command_clock) begin 
                $display("Command: %d", mcu_bus);
                if (mcu_bus == 8'd2) begin 
                    $display("Waiting for VGA start");
                    counter <= 0;
                    state <= STATE_START_FIFO_SYNC;
                end
            end
        end
        STATE_START_FIFO_SYNC: begin 
            reset_sync <= 1; 
            state <= STATE_WAITING_FOR_START_VGA;
        end
        STATE_WAITING_FOR_START_VGA: begin 
            reset_sync <= 0;
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

endmodule

`resetall
