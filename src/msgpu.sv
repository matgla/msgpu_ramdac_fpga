`include "fifo.sv"

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
    McuBusExternalInterface mcu_bus,
    MemoryInterface memory 
);

// assign led = LED_BITS;

wire reset_vga = 0;
reg enable_vga = 1;
wire[21:0] read_address;
wire [11:0] pixel_data = 0; 

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

McuBusInternalInterfaceInput internal_bus_input();
McuBus mcu(
    .external_bus(mcu_bus),
    .internal_bus_in(internal_bus_input)
);

bit[23:0] write_ram_address = 0; 

typedef enum {
    MSGPU_STATE_INIT, 
    MSGPU_STATE_IDLE,
    MSGPU_WRITE_DATA_TO_RAM, 
    MSGPU_READ_LINE_FROM_RAM,
    MSGPU_WAIT_FOR_WRITE,
    MSGPU_WAIT_FOR_READ
} MsgpuState;

MsgpuState msgpu_state;

int write_line_counter = 0;
byte vga_buffer[2][640];
bit vga_current_line; 
bit vga_write_counter = 0; 
bit vga_last_stored_line = 0;

wire vga_line_needed = vga_current_line == vga_last_stored_line; 

int read_ram_address = 0;
int read_line_counter = 0;


always @(posedge system_clock) begin 
    case (msgpu_state)
        MSGPU_STATE_INIT: begin 
            init_variables();
            msgpu_state <= MSGPU_STATE_IDLE;
        end
        MSGPU_STATE_IDLE: begin 
            if (vga_line_needed) begin 
                msgpu_state <= MSGPU_READ_LINE_FROM_RAM;
            end
            if (!mcu_buffer_empty) begin 
                msgpu_state <= MSGPU_WRITE_DATA_TO_RAM; 
            end
        end
        MSGPU_WRITE_DATA_TO_RAM: begin 
            memory.input_size <= 640; 
            memory.input_address <= write_ram_address;
            if (memory.busy) begin 
                memory.input_size <= 0; 
                memory.input_address <= 0;
                msgpu_state <= MSGPU_WAIT_FOR_WRITE;
            end
        end
        MSGPU_WAIT_FOR_WRITE: begin 
            if (!memory.busy) begin 
                if (write_line_counter == 479) begin 
                    write_ram_address <= 0; 
                    write_line_counter <= 0;
                end else begin 
                    write_ram_address <= write_ram_address + 640;
                    write_line_counter <= write_line_counter + 1'b1;
                end
                msgpu_state <= MSGPU_STATE_IDLE;
            end
        end
        MSGPU_READ_LINE_FROM_RAM: begin 
            memory.output_size <= 640; 
            memory.output_address <= read_ram_address; 
            if (memory.busy) begin 
                memory.output_size <= 0; 
                memory.output_address <= 0;
                msgpu_state <= MSGPU_WAIT_FOR_READ;
            end
        end
        MSGPU_WAIT_FOR_READ: begin 
            if (!memory.busy) begin 
                if (read_line_counter == 479) begin 
                    read_ram_address <= 0; 
                    read_line_counter <= 0;
                end else begin 
                    read_ram_address <= read_ram_address + 640; 
                    read_line_counter <= read_line_counter + 1'b1;
                end
                msgpu_state <= MSGPU_STATE_IDLE;
            end
        end
    endcase
end

/* MSGPU - MCU BUS */ 
byte mcu_buffer[2][1024];
bit[1:0] mcu_buffer_usage = 2'b0;
int mcu_buffer_write_pointer = 0;
bit mcu_buffer_current_line = 0; 
bit mcu_buffer_last_line = 0; 

wire mcu_buffer_full = mcu_buffer_usage == 2'b11;
wire mcu_buffer_empty = mcu_buffer_usage == 2'b00;

always @(posedge internal_bus_input.data_clock) begin 
    if (!mcu_buffer_full) begin 
        mcu_buffer[mcu_buffer_current_line][mcu_buffer_write_pointer] 
            <= internal_bus_input.data; 
        if (mcu_buffer_write_pointer == 639) begin 
            mcu_buffer_write_pointer <= 0; 
            mcu_buffer_last_line <= mcu_buffer_current_line;
            mcu_buffer_usage[mcu_buffer_current_line] <= 1;
        end else begin 
            mcu_buffer_write_pointer <= mcu_buffer_write_pointer + 1'b1;
        end
    end
end

/* MSGPU - PSRAM */ 
always @(posedge memory.output_clock) begin 
    vga_buffer[vga_current_line][vga_write_counter] <= memory.output_data;  
    if (vga_write_counter < 640) begin 
        vga_write_counter <= vga_write_counter + 1'b1; 
    end else begin 
        vga_write_counter <= 0; 
        vga_last_stored_line <= vga_last_stored_line + 1'b1;
    end
end

int from_ram_counter = 0;
always @(posedge memory.input_clock) begin 
    memory.input_data <= mcu_buffer[mcu_buffer_current_line][from_ram_counter];
    if (from_ram_counter < 640) begin 
        from_ram_counter <= from_ram_counter + 1'b1; 
    end else begin 
        from_ram_counter <= 0;
        //mcu_buffer_usage[mcu_buffer_current_line] <= 0;
        mcu_buffer_current_line <= mcu_buffer_current_line + 1'b1;
    end
end

/* MSGPU - VGA */ 

function void init_variables(); 
    vga_current_line = 0;
endfunction

endmodule 
