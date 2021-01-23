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

/************** SPI READ ******************/

typedef enum {
    SPI_READ_PREPARE_FOR_COMMAND,
    SPI_READ_SEND_COMMAND,
    SPI_READ_SEND_ADDRESS,
    SPI_READ_PERFORM_READ,
    SPI_READ_PROCESS_READ,
    SPI_READ_FINISH
} SpiReadState; 

SpiReadState spi_read_state;

int read_bytes_counter;
reg[7:0] memory_buffer_read[1024];

function RoutineStatus spi_read(bit[23:0] address, int bytes_to_read);
    case (spi_read_state) 
        SPI_READ_PREPARE_FOR_COMMAND: begin 
            read_bytes_counter <= 0; 
            bus.ce_low(); 
            spi_read_state <= SPI_READ_SEND_COMMAND;
        end
        SPI_READ_SEND_COMMAND: begin 
            if (bus.spi_read_write_u8(`IPS6404L_SQ_READ) 
                == SPI_OPERATION_FINISHED) begin 
                spi_read_state <= SPI_READ_SEND_ADDRESS;
            end 
        end
        SPI_READ_SEND_ADDRESS: begin 
            if (write_address(address) == FINISHED) begin 
                spi_read_state <= SPI_READ_PERFORM_READ;
            end
        end
        SPI_READ_PERFORM_READ: begin 
            if (bus.spi_read_write_u8(8'h00) == FINISHED) begin 
                spi_read_state <= SPI_READ_PROCESS_READ;
                memory_buffer_read[read_bytes_counter] <= spi_rx;
            end
        end
        SPI_READ_PROCESS_READ: begin 
            if (read_bytes_counter < bytes_to_read - 1) begin 
                read_bytes_counter <= read_bytes_counter + 1;
                spi_read_state <= SPI_READ_PERFORM_READ;
            end else begin
                spi_read_state <= SPI_READ_FINISH;
            end
        end
        SPI_READ_FINISH: begin 
            bus.ce_high(); 
            spi_read_state <= SPI_READ_PREPARE_FOR_COMMAND;
            return FINISHED;
        end
    endcase
    return WORKING;
endfunction

/************* SPI WRITE ***************/ 

typedef enum {
    SPI_WRITE_PREPARE_FOR_COMMAND,
    SPI_WRITE_SEND_COMMAND,
    SPI_WRITE_SEND_ADDRESS,
    SPI_WRITE_SEND_BYTE,
    SPI_WRITE_PEREPARE_NEXT_BYTE,
    SPI_WRITE_FINISH
} SpiWriteState;

int write_bytes_counter;
reg[7:0] memory_buffer_write[1024];

SpiWriteState spi_write_state;

function RoutineStatus spi_write(bit[23:0] address, int data_size);
    case (spi_write_state) 
        SPI_WRITE_PREPARE_FOR_COMMAND: begin 
            bus.ce_low();
            write_bytes_counter <= 0;
            spi_write_state <= SPI_WRITE_SEND_COMMAND;
        end
        SPI_WRITE_SEND_COMMAND: begin 
            if (bus.spi_read_write_u8(`IPS6404L_SQ_WRITE) 
                == SPI_OPERATION_FINISHED) begin 
                spi_write_state <= SPI_WRITE_SEND_ADDRESS;     
            end
        end 
        SPI_WRITE_SEND_ADDRESS: begin 
            if (write_address(address) == FINISHED) begin 
                spi_write_state <= SPI_WRITE_SEND_BYTE;
            end
        end
        SPI_WRITE_SEND_BYTE: begin 
            if (bus.spi_read_write_u8(memory_buffer_write[write_bytes_counter]) 
                == SPI_OPERATION_FINISHED) begin 
                spi_write_state <= SPI_WRITE_PEREPARE_NEXT_BYTE;
            end
        end
        SPI_WRITE_PEREPARE_NEXT_BYTE: begin 
            write_bytes_counter <= write_bytes_counter + 1;
            if (write_bytes_counter < data_size - 1) begin 
                spi_write_state <= SPI_WRITE_SEND_BYTE;
            end
            else begin 
                spi_write_state <= SPI_WRITE_FINISH;
                bus.ce_high();
            end
        end
        SPI_WRITE_FINISH: begin 
            spi_write_state <= SPI_WRITE_PREPARE_FOR_COMMAND;
            return FINISHED;
        end
    endcase
    return WORKING;
endfunction

/******* SPI WRITE READ TEST ********/ 

typedef enum {
    ONGOING,
    PASSED, 
    FAILED
} TestStatus;

typedef enum {
    SPI_TEST_INIT, 
    SPI_TEST_WRITE_FIRST_PART,
    SPI_TEST_WRITE_SECOND_PART, 
    SPI_TEST_PREPARE_SECOND_PART,
    SPI_TEST_READ_FIRST_PART, 
    SPI_TEST_READ_SECOND_PART,
    SPI_TEST_VERIFY_FIRST_PART, 
    SPI_TEST_VERIFY_SECOND_PART
} SpiTestState; 

SpiTestState spi_test_state; 

bit[7:0] spi_test_data[5];

integer i;

function TestStatus test_spi_write_read();
    case (spi_test_state)
        SPI_TEST_INIT: begin 
            spi_test_data[0] <= 8'h12;
            spi_test_data[1] <= 8'haa;
            spi_test_data[2] <= 8'h00;
            spi_test_data[3] <= 8'h18;
            spi_test_data[4] <= 8'hdd;
            for (i = 0; i < 5; i = i + 1) begin 
                memory_buffer_write[i] <= spi_test_data[i];
            end
            spi_test_state <= SPI_TEST_WRITE_FIRST_PART;
        end
        SPI_TEST_WRITE_FIRST_PART: begin 
            if (spi_write(24'h000000, 5) == FINISHED) begin 
                spi_test_state <= SPI_TEST_PREPARE_SECOND_PART;
            end
        end
        SPI_TEST_PREPARE_SECOND_PART: begin 
            memory_buffer_write[0] <= 8'hfa;
            memory_buffer_write[1] <= 8'hc9;
            spi_test_state <= SPI_TEST_WRITE_SECOND_PART;
        end
        SPI_TEST_WRITE_SECOND_PART: begin 
            if (spi_write(24'h0000ff, 2) == FINISHED) begin 
                spi_test_state <= SPI_TEST_READ_FIRST_PART;
            end
        end
        SPI_TEST_READ_FIRST_PART: begin 
            if (spi_read(24'h000000, 5) == FINISHED) begin 
                spi_test_state <= SPI_TEST_VERIFY_FIRST_PART;
            end
        end 
        SPI_TEST_VERIFY_FIRST_PART: begin 
            if (memory_buffer_read[0] != 8'h12
                || memory_buffer_read[1] != 8'haa
                || memory_buffer_read[2] != 8'h00 
                || memory_buffer_read[3] != 8'h18 
                || memory_buffer_read[4] != 8'hdd) begin 
                return FAILED;
            end else begin 
                spi_test_state <= SPI_TEST_READ_SECOND_PART;
            end
        end
        SPI_TEST_READ_SECOND_PART: begin 
            if (spi_read(24'h0000ff, 2) == FINISHED) begin 
                spi_test_state <= SPI_TEST_VERIFY_SECOND_PART;
            end
        end
        SPI_TEST_VERIFY_SECOND_PART: begin 
            spi_test_state <= SPI_TEST_INIT;
            if (memory_buffer_read[0] != 8'hfa) return FAILED;
            else if (memory_buffer_read[1] != 8'hc9) return FAILED; 
            else return PASSED;
        end
    endcase 
    return ONGOING;
endfunction

/************** INIT*****************/ 

function void init();
    delay_counter <= 0;
    psram_reset_state <= PULL_DOWN_CE_AND_WAIT;
    address_counter <= 0; 
    eid_type <= 0; 
    eid <= 0; 
    mfid <= 0; 
    kdg <= 0; 
    read_eid_state <= PREPARE_FOR_READ_ID;
    eid_bytes_received <= 0; 
    spi_read_state <= SPI_READ_PREPARE_FOR_COMMAND;
    spi_write_state <= SPI_WRITE_PREPARE_FOR_COMMAND;
    spi_test_state <= SPI_TEST_INIT;
endfunction

typedef enum {
    PSRAM_STATE_INIT,
    PSRAM_STATE_RESET,
    PSRAM_STATE_READ_EID,
    PSRAM_STATE_VERIFY_EID,
    PSRAM_STATE_TEST_SPI,
    PSRAM_STATE_FAILED, 
    PSRAM_STATE_IDLE
} PsramDriverState; 

PsramDriverState driver_state;

TestStatus status;

always @(negedge sysclk) begin
    // bus.ce <= sp.ce;
    case (driver_state)
        PSRAM_STATE_INIT: begin
            debug_led <= 1;
            init();
            driver_state <= PSRAM_STATE_RESET;
        end
        PSRAM_STATE_RESET: begin
            if (psram_reset() == FINISHED) 
                driver_state <= PSRAM_STATE_READ_EID;
        end
        PSRAM_STATE_READ_EID: begin
            if (read_eid() == FINISHED)
                driver_state <= PSRAM_STATE_VERIFY_EID;
            // PSRAM_READ_EID(`PSRAM_STATE_VERIFY);
        end
        PSRAM_STATE_VERIFY_EID: begin
            if (kdg != 8'h5d) driver_state <= PSRAM_STATE_FAILED;
            else driver_state <= PSRAM_STATE_TEST_SPI;
        end
        PSRAM_STATE_TEST_SPI: begin 
            status = test_spi_write_read(); 
            if (status == FAILED) driver_state <= PSRAM_STATE_FAILED;
            else if (status == PASSED) driver_state <= PSRAM_STATE_IDLE;
        end 
        PSRAM_STATE_IDLE: begin 
            debug_led <= 0;
        end
        PSRAM_STATE_FAILED: begin 

        end
        default: begin
            //debug_led <= 1;
            driver_state <= PSRAM_STATE_INIT;
        end
    endcase
end

endmodule

`resetall
