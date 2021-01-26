`ifndef PSRAM_SPI_INTERFACE
`define PSRAM_SPI_INTERFACE

typedef enum {SPI_OPERATION_FINISHED, SPI_OPERATION_WORKING} operation_status;

typedef enum 
{
    READ_WRITE_ENABLE_CLOCK,
    READ_WRITE_0_BIT,
    READ_WRITE_1_BIT,
    READ_WRITE_2_BIT,
    READ_WRITE_3_BIT,
    READ_WRITE_4_BIT,
    READ_WRITE_5_BIT,
    READ_WRITE_6_BIT,
    READ_WRITE_7_BIT
} ReadWriteByteState;

ReadWriteByteState spi_read_state;

reg spi_enable_clock;

/* SPI modes */
`define SPI_MODE_1 2'b00
`define SPI_MODE_4_INPUTS 2'b01
`define SPI_MODE_4_OUTPUTS 2'b10
`define SPI_MODE_WAIT 2'b11

reg[1:0] current_spi_mode;

reg[7:0] spi_rx;
reg[7:0] rx_buffer_high;

interface SpiBus();
    logic reset;
    logic sclk;
    logic ce;
    logic[3:0] signal_input;
    logic[3:0] signal_output;
    logic[3:0] signal_direction;

    function void ce_low();
        ce <= 0;
    endfunction

    function void ce_high();
        ce <= 1;
    endfunction

    function operation_status spi_read_write_u8(byte data);
        case (spi_read_state)
            READ_WRITE_ENABLE_CLOCK: begin 
                current_spi_mode <= `SPI_MODE_1;
                spi_enable_clock <= 1;
                signal_output[0] <= data[7];
                spi_read_state <= READ_WRITE_7_BIT;
            end
            READ_WRITE_7_BIT: begin 
                spi_read_state <= READ_WRITE_6_BIT;
                signal_output[0] <= data[6];
            end
            READ_WRITE_6_BIT: begin 
                spi_read_state <= READ_WRITE_5_BIT;
                signal_output[0] <= data[5];
            end
            READ_WRITE_5_BIT: begin 
                spi_read_state <= READ_WRITE_4_BIT;
                signal_output[0] <= data[4];
            end
            READ_WRITE_4_BIT: begin 
                spi_read_state <= READ_WRITE_3_BIT;
                signal_output[0] <= data[3];
            end
            READ_WRITE_3_BIT: begin 
                spi_read_state <= READ_WRITE_2_BIT;
                signal_output[0] <= data[2];
            end
            READ_WRITE_2_BIT: begin 
                spi_read_state <= READ_WRITE_1_BIT;
                signal_output[0] <= data[1];
            end
            READ_WRITE_1_BIT: begin 
                spi_read_state <= READ_WRITE_0_BIT;
                signal_output[0] <= data[0];
            end
            READ_WRITE_0_BIT: begin 
                spi_read_state <= READ_WRITE_ENABLE_CLOCK;
                spi_enable_clock <= 0;
                return SPI_OPERATION_FINISHED;
            end
        endcase
        return SPI_OPERATION_WORKING;
    endfunction

    typedef enum {
        QSPI_WRITE_ENABLE_CLOCK,
        QSPI_WRITE_PART_1,
        QSPI_WRITE_PART_2
    } QspiWriteState;

    QspiWriteState qspi_write_state;

    function operation_status qspi_write_u8(byte data);
        case (qspi_write_state) 
            QSPI_WRITE_ENABLE_CLOCK: begin 
                current_spi_mode <= `SPI_MODE_4_OUTPUTS;
                spi_enable_clock <= 1;
                signal_output[3:0] <= data[7:4];
                qspi_write_state <= QSPI_WRITE_PART_1;
            end
            QSPI_WRITE_PART_1: begin 
                signal_output[3:0] <= data[3:0];
                qspi_write_state <= QSPI_WRITE_PART_2;
            end
            QSPI_WRITE_PART_2: begin 
                spi_enable_clock <= 0;
                qspi_write_state <= QSPI_WRITE_ENABLE_CLOCK;
                return SPI_OPERATION_FINISHED;
            end
        endcase 
        return SPI_OPERATION_WORKING;
    endfunction

    typedef enum {
        QSPI_READ_ENABLE_CLOCK, 
        QSPI_READ_PART_1,
        QSPI_READ_PART_2
    } QspiReadState;
    
    QspiReadState qspi_read_state;

    function operation_status qspi_read_u8(); 
        case (qspi_read_state)
            QSPI_READ_ENABLE_CLOCK: begin 
                current_spi_mode <= `SPI_MODE_4_INPUTS;
                spi_enable_clock <= 1;
                qspi_read_state <= QSPI_READ_PART_1;
            end
            QSPI_READ_PART_1: begin 
                qspi_read_state <= QSPI_READ_PART_2;
            end
            QSPI_READ_PART_2: begin 
                spi_enable_clock <= 0;
                qspi_read_state <= QSPI_READ_ENABLE_CLOCK;
                return SPI_OPERATION_FINISHED;
            end
        endcase 
        return SPI_OPERATION_WORKING;
    endfunction

    function void spi_init();
        spi_read_state <= READ_WRITE_ENABLE_CLOCK;
        qspi_write_state <= QSPI_WRITE_ENABLE_CLOCK;
        qspi_read_state <= QSPI_READ_ENABLE_CLOCK;
    endfunction

    always @(posedge sclk) begin
        case (current_spi_mode)
            `SPI_MODE_1: begin
                spi_rx <= {spi_rx[6:0], signal_input[1]};
                rx_buffer_high <= {spi_rx[6:0], spi_rx[7]};
            end
            `SPI_MODE_4_INPUTS: begin
                spi_rx <= {spi_rx[3:0], signal_input};
                rx_buffer_high <= {rx_buffer_high[3:0], spi_rx[7:4]};
            end
            default: begin end
        endcase
    end

    always @(current_spi_mode) begin
        case (current_spi_mode)
            `SPI_MODE_1: signal_direction = 4'b0001;
            `SPI_MODE_4_INPUTS: signal_direction = 4'b0000;
            `SPI_MODE_4_OUTPUTS: signal_direction = 4'b1111;
            `SPI_MODE_WAIT: signal_direction = 4'b0000;
        endcase
    end

endinterface 

`endif
