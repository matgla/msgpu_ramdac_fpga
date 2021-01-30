`include "psram/commands.v"

import spi_types::*;

module psram(
    input sysclk,
    SpiBus bus,
    MemoryInterface memory
);

// assign bus.signal_output = spi_out;

/* driveable system_clock */


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
    WAIT_FOR_DEVICE,
    RESET_DELAY
} PsramResetState;
PsramResetState psram_reset_state;

function RoutineStatus psram_reset();
    case (psram_reset_state)
        PULL_DOWN_CE_AND_WAIT: begin 
            bus.current_spi_mode <= SPI_MODE_4_OUTPUTS;
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
            if (bus.spi_read_write_u8(IPS6404L_SQ_RESET) == SPI_OPERATION_FINISHED) begin 
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

/****** QSPI VARIABLES **************/ 

byte memory_buffer_write[1024];
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
            end
        end 
        QSPI_WRITE_ADDRESS_BYTE2: begin 
            if (bus.qspi_write_u8(address[15:8]) == SPI_OPERATION_FINISHED) begin
                qspi_write_address_state <= QSPI_WRITE_ADDRESS_BYTE3;
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
                memory.input_clock <= 1;
            end
        end
        QSPI_WRITE_SEND_BYTE: begin 
            if (bus.qspi_write_u8(memory.input_data)
                == SPI_OPERATION_FINISHED) begin 
                if (qspi_write_bytes_counter >= size - 1) begin 
                    psram_qspi_write_state <= QSPI_WRITE_DELAY;
                    bus.ce_high();
                    memory.input_clock <= 0;
                end else begin 
                    memory.input_clock <= 1;
                end
                qspi_write_bytes_counter <= qspi_write_bytes_counter + 1;
            end else begin 
                memory.input_clock <= 0;
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
    bus.current_spi_mode <= SPI_MODE_4_INPUTS;
    if (wait_cycles_counter < required) begin 
        bus.spi_enable_clock <= 1;
        wait_cycles_counter <= wait_cycles_counter + 1;
    end
    else begin 
        bus.spi_enable_clock <= 0;
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
            end
        end
        QSPI_FAST_READ_WAIT_CYCLES: begin 
            if (qspi_wait_cycles(6) == FINISHED) begin 
                qspi_fast_read_state <= QSPI_FAST_READ_GET_BYTE;
            end
        end
        QSPI_FAST_READ_GET_BYTE: begin 
            memory.output_clock <= 0;
            if (bus.qspi_read_u8() == SPI_OPERATION_FINISHED) begin 
                memory.output_data <= bus.spi_rx;
                qspi_read_counter <= qspi_read_counter + 1;
                memory.output_clock <= 1;
                if (qspi_read_counter >= size - 1) begin 
                    qspi_fast_read_state <= QSPI_FAST_READ_PROCCESS_BYTE;
                end
            end
        end
        QSPI_FAST_READ_PROCCESS_BYTE: begin 
            memory.output_clock <= 0;
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
        default: begin 
            qspi_fast_read_state <= QSPI_FAST_READ_INIT;
        end
    endcase
    return WORKING;
endfunction

/************** INIT*****************/ 

task init;
begin
    delay_counter <= 0;
    psram_reset_state <= PULL_DOWN_CE_AND_WAIT;
    address_counter <= 0; 
    qspi_write_address_state <= QSPI_WRITE_ADDRESS_BYTE1;
    psram_qspi_write_state <= QSPI_WRITE_INIT;
    qspi_fast_read_state <= QSPI_FAST_READ_INIT;
    wait_cycles_counter <= 0;
end 
endtask 

typedef enum {
    PSRAM_STATE_INIT,
    PSRAM_STATE_RESET,
    PSRAM_STATE_FAILED, 
    PSRAM_STATE_IDLE,
    PSRAM_READ,
    PSRAM_WRITE
} PsramDriverState; 

PsramDriverState driver_state;

int to_be_readed;
reg[23:0] to_be_written;
int write_pointer;
int address_to_write;
int address_to_read;
always @(negedge sysclk) begin
    // bus.ce <= sp.ce;
    case (driver_state)
        PSRAM_STATE_INIT: begin
            bus.spi_init();
            init();
            driver_state <= PSRAM_STATE_RESET;
        end
        PSRAM_STATE_RESET: begin
            if (psram_reset() == FINISHED) 
                driver_state <= PSRAM_STATE_IDLE;
        end
        PSRAM_STATE_IDLE: begin 
            if (memory.output_size != 0) begin 
                to_be_readed <= memory.output_size;
                address_to_read <= memory.output_address;
                driver_state <= PSRAM_READ;
            end
            if (memory.input_size != 0) begin 
                to_be_written <= memory.input_size;
                address_to_write <= memory.input_address;
                driver_state <= PSRAM_WRITE;
            end
        end
        PSRAM_READ: begin 
            if (qspi_fast_read(address_to_read, to_be_readed) == FINISHED) begin 
                memory.busy <= 0;
                driver_state <= PSRAM_STATE_IDLE; 
            end else begin 
                memory.busy <= 1;
            end
        end
        PSRAM_WRITE: begin 
            if (psram_qspi_write(address_to_write, to_be_written) == FINISHED) begin 
                memory.busy <= 0;
                driver_state <= PSRAM_STATE_IDLE;
            end else begin 
                memory.busy <= 1; 
            end
        end
        PSRAM_STATE_FAILED: begin 
        end
        default: begin
            driver_state <= PSRAM_STATE_INIT;
        end
    endcase
end

endmodule

`resetall
