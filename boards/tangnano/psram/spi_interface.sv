import spi_types::*;


interface SpiBus(input system_clock, output sclk);
    //logic sclk;
    logic ce;
    logic[3:0] signal_input;
    logic[3:0] signal_output;
    logic[3:0] signal_direction;
    reg[7:0] spi_rx;
    reg spi_enable_clock;
    
    task ce_low;
        ce <= 0;
    endtask

    task ce_high;
        ce <= 1;
    endtask


    SpiMode current_spi_mode;
    
    gated_clock gated_clk(
        .clock(system_clock),
        .clock_output(sclk),
        .enable(spi_enable_clock)
    );


    ReadWriteByteState spi_read_state;
    function operation_status spi_read_write_u8(byte data);
        case (spi_read_state)
            READ_WRITE_INIT: begin 
                current_spi_mode <= SPI_MODE_1;
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
                spi_read_state <= READ_WRITE_INIT;
                spi_enable_clock <= 0;
                return SPI_OPERATION_FINISHED;
            end
        endcase
        return SPI_OPERATION_WORKING;
    endfunction

    QspiWriteState qspi_write_state;
    function operation_status qspi_write_u8(byte data);
        case (qspi_write_state) 
            QSPI_WRITE_ENABLE_CLOCK: begin 
                current_spi_mode <= SPI_MODE_4_OUTPUTS;
                spi_enable_clock <= 1;
                signal_output <= data[7:4];
                qspi_write_state <= QSPI_WRITE_PART_1;
            end
            QSPI_WRITE_PART_1: begin 
                signal_output <= data[3:0];
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

   
    QspiReadState qspi_read_state;

    function operation_status qspi_read_u8(); 
        case (qspi_read_state)
            QSPI_READ_ENABLE_CLOCK: begin 
                current_spi_mode <= SPI_MODE_4_INPUTS;
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

    task spi_init;
    begin
       // spi_read_state = READ_WRITE_INIT;
       // qspi_write_state = QSPI_WRITE_ENABLE_CLOCK;
       // qspi_read_state = QSPI_READ_ENABLE_CLOCK;
    end
    endtask 

    always @(posedge sclk) begin
        case (current_spi_mode)
            SPI_MODE_1: begin
                spi_rx <= {spi_rx[6:0], signal_input[1]};
            end
            SPI_MODE_4_INPUTS: begin
                spi_rx <= {spi_rx[3:0], signal_input};
            end
            default: begin end
        endcase
    end

    always @(current_spi_mode) begin
        case (current_spi_mode)
            SPI_MODE_1: signal_direction = 4'b0001;
            SPI_MODE_4_INPUTS: signal_direction = 4'b0000;
            SPI_MODE_4_OUTPUTS: signal_direction = 4'b1111;
            SPI_MODE_WAIT: signal_direction = 4'b0000;
        endcase
    end

endinterface 
