`include "psram/commands.v"
`include "psram/spi_interface.sv"

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
            address_counter <= 0;
            read_eid_state <= SEND_READ_EID_COMMAND;
            eid_bytes_received <= 0;
        end 
        SEND_READ_EID_COMMAND: begin
            if (bus.spi_read_write_u8(`IPS6404L_SQ_READ_ID) == SPI_OPERATION_FINISHED) begin 
                read_eid_state <= READ_EID_SEND_ADDRESS;
            end
        end
        READ_EID_SEND_ADDRESS: begin 
            if (address_counter < 3) begin 
                if (bus.spi_read_write_u8(8'hff) == FINISHED) begin 
                    address_counter <= address_counter + 1;
                end
            end else begin 
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

/****** QSPI VARIABLES **************/ 

byte memory_buffer_write[1024];
byte memory_buffer_read[1024];
int address_counter;
//int write_address; 

/****** QSPI WRITE ADDRESS **********/

typedef enum { 
    QSPI_WRITE_ADDRESS_BYTE1,
    QSPI_WRITE_ADDRESS_BYTE2,
    QSPI_WRITE_ADDRESS_BYTE3
} QspiWriteAddressState;

QspiWriteAddressState qspi_write_address_state;

function RoutineStatus qspi_write_address(bit[23:0] address); 
    case (qspi_write_address_state) 
        QSPI_WRITE_ADDRESS_BYTE1: begin 
        if (bus.qspi_write_u8(address[23:16]) == SPI_OPERATION_FINISHED) begin 
                qspi_write_address_state <= QSPI_WRITE_ADDRESS_BYTE2;
                bus.qspi_write_u8(address[15:8]); 
            end
        end 
        QSPI_WRITE_ADDRESS_BYTE2: begin 
        if (bus.qspi_write_u8(address[15:8]) == SPI_OPERATION_FINISHED) begin
                qspi_write_address_state <= QSPI_WRITE_ADDRESS_BYTE3;
                bus.qspi_write_u8(address[7:0]); 
            end
        end
        QSPI_WRITE_ADDRESS_BYTE3: begin 
            if (bus.qspi_write_u8(address[7:0]) == SPI_OPERATION_FINISHED) begin
                qspi_write_address_state <= QSPI_WRITE_ADDRESS_BYTE1;
                return FINISHED;
            end
        end
    endcase
    return WORKING;
endfunction

/********** QSPI WRITE **************/

typedef enum {
    QSPI_WRITE_INIT, 
    QSPI_WRITE_SEND_COMMAND,
    QSPI_WRITE_SEND_ADDRESS,
    QSPI_WRITE_SEND_BYTE,
    QSPI_WRITE_PREPARE_NEXT_BYTE,
    QSPI_WRITE_FINISH,
    QSPI_WRITE_DELAY
} PsramQspiWriteState;

PsramQspiWriteState psram_qspi_write_state;
int qspi_write_bytes_counter;
int qspi_write_delay;
function RoutineStatus psram_qspi_write(bit[23:0] address, int size);
    case (psram_qspi_write_state) 
        QSPI_WRITE_INIT: begin 
            bus.ce_low();
            qspi_write_delay <= 0;
            qspi_write_bytes_counter <= 0;
            psram_qspi_write_state <= QSPI_WRITE_SEND_COMMAND;
        end
        QSPI_WRITE_SEND_COMMAND: begin 
            if (bus.spi_read_write_u8(`IPS6404L_SQ_WRITE_QUAD) == SPI_OPERATION_FINISHED) begin 
                psram_qspi_write_state <= QSPI_WRITE_SEND_ADDRESS;
            end
        end
        QSPI_WRITE_SEND_ADDRESS: begin 
            if (qspi_write_address(address) == FINISHED) begin 
                psram_qspi_write_state <= QSPI_WRITE_SEND_BYTE;
            end
        end
        QSPI_WRITE_SEND_BYTE: begin 
            if (bus.qspi_write_u8(memory_buffer_write[qspi_write_bytes_counter])
                == SPI_OPERATION_FINISHED) begin 
                if (qspi_write_bytes_counter >= size - 1) begin 
                    psram_qspi_write_state <= QSPI_WRITE_DELAY;
                    bus.ce_high();
                end
                qspi_write_bytes_counter <= qspi_write_bytes_counter + 1;
            end
        end
        QSPI_WRITE_DELAY: begin 
            if (qspi_write_delay < 16) qspi_write_delay <= qspi_write_delay + 1;
            else psram_qspi_write_state <= QSPI_WRITE_FINISH;
        end
        QSPI_WRITE_FINISH: begin 
            psram_qspi_write_state <= QSPI_WRITE_INIT;
            return FINISHED;
        end
    endcase
    return WORKING;
endfunction

/******* WAIT CYCLES ***************/ 

int wait_cycles_counter;
function RoutineStatus qspi_wait_cycles(int required);
    current_spi_mode <= `SPI_MODE_4_INPUTS;
    if (wait_cycles_counter < required) begin 
        spi_enable_clock <= 1;
        wait_cycles_counter <= wait_cycles_counter + 1;
    end
    else begin 
        spi_enable_clock <= 0;
        wait_cycles_counter <= 0;
        return FINISHED;
    end
    return WORKING;
endfunction

/*********** QSPI FAST READ *********/ 

typedef enum {
    QSPI_FAST_READ_INIT,
    QSPI_FAST_READ_SEND_COMMAND,
    QSPI_FAST_READ_SEND_ADDRESS,
    QSPI_FAST_READ_WAIT_CYCLES,
    QSPI_FAST_READ_CALCULATE_CYCLES,
    QSPI_FAST_READ_GET_BYTE,
    QSPI_FAST_READ_PROCCESS_BYTE,
    QSPI_FAST_READ_FINISH,
    QSPI_FAST_READ_DELAY
} QspiFastReadState;

QspiFastReadState qspi_fast_read_state; 

int qspi_read_counter; 
int fast_read_delay; 
byte cycles_counter; 

function RoutineStatus qspi_fast_read(bit[23:0] address, int size); 
    case (qspi_fast_read_state)
        QSPI_FAST_READ_INIT: begin 
            cycles_counter <= 0;
            qspi_read_counter <= 0;
            fast_read_delay <= 0;
            bus.ce_low();
            qspi_fast_read_state <= QSPI_FAST_READ_SEND_COMMAND;
        end
        QSPI_FAST_READ_SEND_COMMAND: begin 
            if (bus.spi_read_write_u8(`IPS6404L_SQ_FAST_READ_QUAD) == SPI_OPERATION_FINISHED) begin 
                qspi_fast_read_state <= QSPI_FAST_READ_SEND_ADDRESS;
            end
        end
        QSPI_FAST_READ_SEND_ADDRESS: begin 
            if (qspi_write_address(address) == FINISHED) begin 
                qspi_fast_read_state <= QSPI_FAST_READ_WAIT_CYCLES;
                qspi_wait_cycles(6);
            end
        end
        QSPI_FAST_READ_WAIT_CYCLES: begin 
        if (qspi_wait_cycles(6) == FINISHED) begin 
            qspi_fast_read_state <= QSPI_FAST_READ_GET_BYTE;
            bus.qspi_read_u8();
        end
        end
        QSPI_FAST_READ_GET_BYTE: begin 
            if (bus.qspi_read_u8() == SPI_OPERATION_FINISHED) begin 
                memory_buffer_read[qspi_read_counter] <= spi_rx;
                qspi_read_counter <= qspi_read_counter + 1;
                if (qspi_read_counter >= size - 1) begin 
                    qspi_fast_read_state <= QSPI_FAST_READ_PROCCESS_BYTE;
                end
                else begin 
                    bus.qspi_read_u8();
                end
            end
        end
        QSPI_FAST_READ_PROCCESS_BYTE: begin 
            qspi_fast_read_state <= QSPI_FAST_READ_DELAY; 
        end
        QSPI_FAST_READ_DELAY: begin 
            bus.ce_high();
            if (fast_read_delay < 6) fast_read_delay <= fast_read_delay + 1;
            else qspi_fast_read_state <= QSPI_FAST_READ_FINISH;
        end
        QSPI_FAST_READ_FINISH: begin 
            qspi_fast_read_state <= QSPI_FAST_READ_INIT;
            return FINISHED;
        end
    endcase
    return WORKING;
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
    qspi_write_address_state <= QSPI_WRITE_ADDRESS_BYTE1;
    psram_qspi_write_state <= QSPI_WRITE_INIT;
    qspi_fast_read_state <= QSPI_FAST_READ_INIT;
    wait_cycles_counter <= 0;
endfunction

typedef enum {
    PSRAM_STATE_INIT,
    PSRAM_STATE_RESET,
    PSRAM_STATE_READ_EID,
    PSRAM_STATE_VERIFY_EID,
    PSRAM_STATE_TEST_SPI,
    PSRAM_STATE_TEST_QSPI,
    PSRAM_STATE_ENABLE_QSPI,
    PSRAM_STATE_FAILED, 
    PSRAM_STATE_IDLE,
    PSRAM_EXIT_QSPI_AND_RESET
} PsramDriverState; 

PsramDriverState driver_state;

typedef enum {
    GOT_BAD_KDG,
    SPI_WRITE_FAILED, 
    QSPI_WRITE_FAILED,
    NOT_FAILED 
} FailureCodes; 

FailureCodes error_code;
byte recovery_counter; 

always @(negedge sysclk) begin
    // bus.ce <= sp.ce;
    case (driver_state)
        PSRAM_STATE_INIT: begin
            //debug_led <= 1;
            bus.spi_init();
            error_code <= NOT_FAILED;
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
        end
        PSRAM_STATE_VERIFY_EID: begin
            if (kdg != 8'h5d) begin 
                driver_state <= PSRAM_STATE_FAILED;
                error_code <= GOT_BAD_KDG;
            end
            else begin 
                recovery_counter <= 0;
                driver_state <= PSRAM_STATE_IDLE;
            end
        end
        PSRAM_STATE_IDLE: begin 
            debug_led <= 0;
        end
        PSRAM_STATE_FAILED: begin 
            if (error_code == GOT_BAD_KDG) begin 
                if (recovery_counter < 3) begin 
                    recovery_counter <= recovery_counter + 1;
                    driver_state <= PSRAM_EXIT_QSPI_AND_RESET;
                end
            end
        end
        PSRAM_EXIT_QSPI_AND_RESET: begin 
          //  if (psram_exit_qspi() == FINISHED) begin 
                driver_state <= PSRAM_STATE_INIT;
          //  end
        end
        default: begin
            //debug_led <= 1;
            driver_state <= PSRAM_STATE_INIT;
        end
    endcase
end

endmodule

`resetall
