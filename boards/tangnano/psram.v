`include "psram/read.v"
`include "psram/commands.v"
`include "psram/globals.v"
`include "psram/write.v"
`include "psram/read_eid.v"
`include "psram/spi_interface.sv"
`include "psram/spi.sv"
`include "psram/reset.v"

module psram(
    input reset,
    input sysclk,
    SpiBus bus,
    output reg debug_led,
    input enable,
    // input reg[23:0] address,
    input rw,
    output reg next_byte_needed,

    // control
    input set_address,
    input write_data,
    input[23:0] address,
    input[7:0] data
);

// assign bus.signal_output = spi_out;

/* driveable system_clock */
assign psram_sclk_enable = spi_enable_clock;

gated_clock gated_clk(
    .clock(sysclk),
    .clock_output(bus.sclk),
    .enable(psram_sclk_enable)
);

// assign psram_sclk_enable = enable_spi_clock;


// /* reading from SPI */
// reg[7:0]
// always @(posedge psram_sclk) begin
//     $display("Send data");
// end


// assign rx = spi_rx;

// reg[31:0] tick_counter;

// task PSRAM_FAST_READ;
// input[3:0] next_state;
// input[23:0] size;
// begin
//     case (state)
//         8'd0: _SPI_1LINE_READWRITE_8(8'd1, `IPS6404L_SQ_READ_ID);
//     //     // 24 bytes of dummy address
//         8'd1: _SPI_1LINE_READWRITE_8(8'd2, 8'hff);
//         8'd2: _SPI_1LINE_READWRITE_8(8'd3, 8'hff);
//         8'd3: _SPI_1LINE_READWRITE_8(8'd4, 8'hff);
//         8'd4: _SPI_1LINE_READWRITE_8(8'd5, 8'h00);
//         8'd5: begin
//             mfid <= spi_rx;
//             state <= 8'd6;
//         end
//         8'd6: _SPI_1LINE_READWRITE_8(8'd7, 8'h00);
//         8'd7: begin
//             kdg <= spi_rx;
//             state <= 8'd8;
//         end
//         8'd8: _SPI_1LINE_READWRITE_8(8'd9, 8'h00);
//         8'd9: begin
//             eid_type <= spi_rx[7:5];
//             eid[44:40] <= spi_rx[4:0];
//             state <= 8'd10;
//         end
//         8'd10: _SPI_1LINE_READWRITE_8(8'd11, 8'h00);
//         8'd11: begin
//             eid[40:33] <= spi_rx;
//             state <= 8'd12;
//         end
//         8'd12: _SPI_1LINE_READWRITE_8(8'd13, 8'h00);
//         8'd13: begin
//             eid[32:25] <= spi_rx;
//             state <= 8'd14;
//         end
//         8'd14: _SPI_1LINE_READWRITE_8(8'd15, 8'h00);
//         8'd15: begin
//             eid[24:17] <= spi_rx;
//             state <= 8'd16;
//         end
//         8'd16: _SPI_1LINE_READWRITE_8(8'd17, 8'h00);
//         8'd17: begin
//             eid[16:9] <= spi_rx;
//             state <= 8'd18;
//         end
//         8'd18: _SPI_1LINE_READWRITE_8(8'd19, 8'h00);
//         8'd19: begin
//             eid[7:0] <= spi_rx;
//             state <= 8'd20;
//         end
//         8'd20: _PSRAM_CS(8'hff, 8'd0, `IPS6404L_SQ_CE_LOW);
//         8'hff: begin
//             state <= 8'h0;
//             driver_state <= next_state;
//         end
//         default: state <= 8'h0;
//     endcase
// end
// endtask


reg[7:0] memory_buffer_read[1024];

typedef enum {FINISHED, WORKING} RoutineStatus;

/*********** DELAY ****************/
int delay_counter;

function RoutineStatus delay(int ticks);
    if (delay_counter < ticks) begin 
        delay_counter <= delay_counter + 1;
    end else begin 
        delay_counter <= 0;
        return FINISHED;
    end
    return WORKING;
endfunction

/*********** RESET ****************/

typedef enum {
    PULL_DOWN_CE_AND_WAIT,
    PREPARE_FOR_RESET_ENABLE,
    ENABLE_RESET,
    PREPARE_FOR_RESET,
    PERFORM_RESET, 
    WAIT_FOR_DEVICE 
} PsramResetState;
PsramResetState psram_reset_state;

function RoutineStatus psram_reset();
    case (psram_reset_state)
        PULL_DOWN_CE_AND_WAIT: begin 
            current_spi_mode <= `SPI_MODE_4_OUTPUTS;
            bus.ce_low();
            if (delay(20000) == FINISHED) begin 
                bus.ce_high();
                psram_reset_state <= PREPARE_FOR_RESET_ENABLE;
            end
        end
        PREPARE_FOR_RESET_ENABLE: begin 
            bus.ce_low();
            psram_reset_state <= ENABLE_RESET;
        end
        ENABLE_RESET: begin 
            if (bus.spi_read_write_u8(`IPS6404L_SQ_RESET_ENABLE) == SPI_OPERATION_FINISHED) begin 
                psram_reset_state <= PREPARE_FOR_RESET;
                bus.ce_high();
            end
        end
        PREPARE_FOR_RESET: begin 
            bus.ce_low();
            psram_reset_state <= PERFORM_RESET;
        end
        PERFORM_RESET: begin 
            if (bus.spi_read_write_u8(`IPS6404L_SQ_RESET) == SPI_OPERATION_FINISHED) begin 
                psram_reset_state <= WAIT_FOR_DEVICE;
                bus.ce_high();
            end
        end
        WAIT_FOR_DEVICE: begin 
            if (delay(20) == FINISHED) begin 
                psram_reset_state <= PULL_DOWN_CE_AND_WAIT;
                return FINISHED;
            end
        end
    endcase
    return WORKING;
endfunction

/************** WRITE ADDRESS ************/
bit[1:0] address_counter;

function RoutineStatus write_address(bit[23:0] address);
    case (address_counter)
        0: begin 
            if (bus.spi_read_write_u8(address[23:16]) == SPI_OPERATION_FINISHED) begin 
                address_counter <= 1;
            end
        end
        1: begin 
            if (bus.spi_read_write_u8(address[15:8]) == SPI_OPERATION_FINISHED) begin 
                address_counter <= 2;
            end
        end
        2: begin 
            if (bus.spi_read_write_u8(address[7:0]) == SPI_OPERATION_FINISHED) begin 
                address_counter <= 0;
                return FINISHED;
            end
        end
    endcase
    return WORKING;
endfunction

/************** READ EID *****************/

bit [2:0] eid_type;
bit [44:0] eid; 
bit [7:0] mfid;
bit [7:0] kdg;

typedef enum {
    PREPARE_FOR_READ_ID,
    SEND_READ_EID_COMMAND,
    READ_EID_SEND_ADDRESS,
    READ_MFID,
    PARSE_MFID,
    REQUEST_KDG,
    PARSE_KDG,
    REQUEST_EID,
    PARSE_EID,
    READ_EID_FINISH
} ReadEidState;

ReadEidState read_eid_state;
bit[3:0] eid_bytes_received;

function RoutineStatus read_eid();
    case (read_eid_state)
        PREPARE_FOR_READ_ID: begin 
            bus.ce_low();
            read_eid_state <= SEND_READ_EID_COMMAND;
            eid_bytes_received <= 0;
        end 
        SEND_READ_EID_COMMAND: begin
            if (bus.spi_read_write_u8(`IPS6404L_SQ_READ_ID) == SPI_OPERATION_FINISHED) begin 
                read_eid_state <= READ_EID_SEND_ADDRESS;
            end
        end
        READ_EID_SEND_ADDRESS: begin 
            if (write_address(24'hffffff) == FINISHED) begin 
                read_eid_state <= READ_MFID;
            end
        end
        READ_MFID: begin 
            if (bus.spi_read_write_u8(8'h00) == SPI_OPERATION_FINISHED) begin 
                read_eid_state <= PARSE_MFID;
            end
        end
        PARSE_MFID: begin 
            mfid <= spi_rx;
            read_eid_state <= REQUEST_KDG;
        end
        REQUEST_KDG: begin 
            if (bus.spi_read_write_u8(8'h00) == SPI_OPERATION_FINISHED) begin 
                read_eid_state <= PARSE_KDG;
            end
        end
        PARSE_KDG: begin 
            kdg <= spi_rx;
            read_eid_state <= REQUEST_EID;
        end
        REQUEST_EID: begin
            if (bus.spi_read_write_u8(8'h00) == SPI_OPERATION_FINISHED) begin 
                read_eid_state <= PARSE_EID;
            end
        end
        PARSE_EID: begin 
            case (eid_bytes_received)
                0: begin 
                    eid_type <= spi_rx[7:5];
                    eid[43:39] <= spi_rx[4:0];
                end
                1: begin 
                    eid[39:32] <= spi_rx;
                end
                2: begin 
                    eid[31:24] <= spi_rx;
                end
                3: begin 
                    eid[23:16] <= spi_rx;
                end
                4: begin 
                    eid[15:8] <= spi_rx;
                end
                5: begin 
                    eid[7:0] <= spi_rx;
                    read_eid_state <= READ_EID_FINISH;
                    return WORKING;
                end
            endcase
            read_eid_state <= REQUEST_EID;
            eid_bytes_received <= eid_bytes_received + 1;
        end
        READ_EID_FINISH: begin 
            bus.ce_high();
            read_eid_state <= PREPARE_FOR_READ_ID;
            return FINISHED;
        end
    endcase 

    return WORKING;
endfunction

`define STATE_INIT 4'd0
`define STATE_WAITING_FOR_DEVICE 4'd1
`define STATE_RESET 4'd2
`define STATE_READ_EID 4'd3
`define STATE_VERIFY 4'd4
`define PSRAM_STATE_IDLE 4'd5
`define PSRAM_STATE_FAILED 4'd6
`define PSRAM_STATE_VERIFY 4'd7
`define PSRAM_STATE_TEST_WRITE 4'd8
`define PSRAM_STATE_TEST_READ 4'd9

always @(negedge sysclk) begin
    // bus.ce <= sp.ce;
    case (driver_state)
        `STATE_INIT: begin
            address_counter <= 0;
            state <= 0;
            delay_counter <= 0;
            driver_state <= `STATE_RESET;
            // debug_led <= 0;
            temp <= 0;
            // spi.set_ce(CE_HIGH);
            // bus.set_ce(0);
            spi_read_state = READ_WRITE_ENABLE_CLOCK;
        end
        `STATE_RESET: begin
            if (psram_reset() == FINISHED) 
                driver_state <= `STATE_READ_EID;
        end
        `STATE_READ_EID: begin
            if (read_eid() == FINISHED)
                driver_state <= `PSRAM_STATE_VERIFY;
            // PSRAM_READ_EID(`PSRAM_STATE_VERIFY);
        end
        `PSRAM_STATE_VERIFY: begin
            // if (kdg != 8'h5d) driver_state <= `PSRAM_STATE_FAILED;
            // else begin
            //     memory_buffer_write[0] <= 8'hab; 
            //     memory_buffer_write[1] <= 8'hcd; 
            //     memory_buffer_write[2] <= 8'hef; 
            //     memory_buffer_write[3] <= 8'h11; 
            //     driver_state <= `PSRAM_STATE_TEST_WRITE;
            // end
        end
        `PSRAM_STATE_TEST_WRITE: begin 
            // PSRAM_WRITE(`PSRAM_STATE_TEST_READ, 24'h000000, 32'd4);
        end 
        `PSRAM_STATE_TEST_READ: begin 
            // PSRAM_READ(`PSRAM_STATE_IDLE, 24'h000000, 32'd4);
        end
        `PSRAM_STATE_IDLE: begin 
            // spi.cs(0);
        end
        default: begin
            //debug_led <= 1;
            driver_state <= `STATE_INIT;
        end
    endcase
end

endmodule

`resetall
