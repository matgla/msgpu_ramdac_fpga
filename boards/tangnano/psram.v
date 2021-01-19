module psram(
    input reset,
    input sysclk,
    output wire psram_sclk,
    output reg psram_ce_n,
    input[3:0] psram_sio_in,
    output reg[3:0] psram_sio_out,
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

/* SPI modes */
`define SPI_MODE_1 2'b00
`define SPI_MODE_4_INPUTS 2'b01
`define SPI_MODE_4_OUTPUTS 2'b10
`define SPI_MODE_WAIT 2'b11

/* IPS6404L-SQ commands */
`define IPS6404L_SQ_READ 8'h03
`define IPS6404L_SQ_FAST_READ 8'h0b
`define IPS6404L_SQ_FAST_READ_QUAD 8'heb
`define IPS6404L_SQ_WRITE 8'h02
`define IPS6404L_SQ_WRITE_QUAD 8'h38
`define IPS6404L_SQ_ENTER_QUAD_MODE 8'h35
`define IPS6404L_SQ_EXIT_QUAD_MODE 8'hf5
`define IPS6404L_SQ_RESET_ENABLE 8'h66
`define IPS6404L_SQ_RESET 8'h99
`define IPS6404L_SQ_BURST_MODE_TOGGLE 8'hc0
`define IPS6404L_SQ_READ_ID 8'h9f

`define WAIT_CYCLE 8'd6
`define IPS6404L_SQ_CE_LOW 1'b1
`define IPS6404L_SQ_CE_HIGH 1'b0

reg psram_sclk_enable;
reg[3:0] psram_sio_dir;
/* driveable system_clock */
gated_clock gated_clk(
    .clock(sysclk),
    .clock_output(psram_sclk),
    .enable(psram_sclk_enable)
);

reg[1:0] current_spi_mode;
reg[7:0] state;

always @(current_spi_mode) begin
    case (current_spi_mode)
        `SPI_MODE_1: psram_sio_dir = 4'b0001;
        `SPI_MODE_4_INPUTS: psram_sio_dir = 4'b0000;
        `SPI_MODE_4_OUTPUTS: psram_sio_dir = 4'b1111;
        `SPI_MODE_WAIT: psram_sio_dir = 4'b0000;
    endcase
end

// /* reading from SPI */
// reg[7:0]
// always @(posedge psram_sclk) begin
//     $display("Send data");
// end

reg[7:0] rx_buffer_low;
reg[7:0] rx_buffer_high;

always @(posedge psram_sclk or posedge reset) begin
    if (reset) begin
        rx_buffer_low <= 8'hff;
        rx_buffer_high <= 8'hff;
    end
    else begin

        if (psram_sclk) begin
            case (current_spi_mode)
                `SPI_MODE_1: begin
                    rx_buffer_low <= {rx_buffer_low[6:0], psram_sio_in[1]};
                    rx_buffer_high <= {rx_buffer_low[6:0], rx_buffer_low[7]};
                end
                `SPI_MODE_4_INPUTS: begin
                    rx_buffer_low <= {rx_buffer_low[3:0], psram_sio_in};
                    rx_buffer_high <= {rx_buffer_high[3:0], rx_buffer_low[7:4]};
                end
                default: begin end
            endcase
        end
    end
end

reg[7:0] temp;

reg[3:0] driver_state;

task _SPI_1LINE_READWRITE_8;
input[7:0] next_state;
input[7:0] output_data;
begin
    current_spi_mode <= `SPI_MODE_1;
    case (temp)
        8'd0: begin
            psram_sio_out[0] <= output_data[7];
            psram_sclk_enable <= 1'b1;
            temp <= 8'd1;
        end
        8'd1: begin temp <= 8'd2; psram_sio_out[0] <= output_data[6]; end
        8'd2: begin temp <= 8'd3; psram_sio_out[0] <= output_data[5]; end
        8'd3: begin temp <= 8'd4; psram_sio_out[0] <= output_data[4]; end
        8'd4: begin temp <= 8'd5; psram_sio_out[0] <= output_data[3]; end
        8'd5: begin temp <= 8'd6; psram_sio_out[0] <= output_data[2]; end
        8'd6: begin temp <= 8'd7; psram_sio_out[0] <= output_data[1]; end
        8'd7: begin
            temp <= 8'd8;
            psram_sio_out[0] <= output_data[0];
        end
        8'd8: begin
            psram_sclk_enable <= 1'b0;
            state <= next_state;
            temp <= 8'h0;
        end
        default: temp <= 8'h0;
    endcase
end
endtask

// reg[3:0] counter;
// task _SPI_1LINE_READ_8;
// input[7:0] next_state;
// begin
//     current_spi_mode <= `SPI_MODE_1;
//     case (temp)
//         8'd0: begin
//             counter <= 4'b0;
//             temp <= 8'd1;
//             psram_sclk_enable <= 1'b1;
//             $display("Reading start");
//         end
//         8'd1: begin
//             if (counter < 4'd7) begin $display("Wait"); counter <= counter + 1; end
//             else begin
//                 $display("readed: %x", rx_buffer_low);
//                 psram_sclk_enable <= 1'b0;
//                 temp <= 8'd0;
//                 state <= next_state;
//             end
//         end
//         default: temp <= 8'h0;
//     endcase
// end
// endtask

reg[7:0] cs_delay;
task _PSRAM_CS;
input[7:0] next_state;
input[7:0] delay;
input cs_n;
begin
    psram_ce_n <= cs_n;
    if (cs_delay < delay) begin
        cs_delay <= cs_delay + 1;
    end
    else begin
        state <= next_state;
        cs_delay <= 8'd0;
    end
end
endtask


reg[15:0] tick_counter;


task PSRAM_RESET;
input [3:0] next_state;
begin
    case (state)
        8'd0: _PSRAM_CS(8'd1, 8'd0, `IPS6404L_SQ_CE_LOW);
        8'd1: _SPI_1LINE_READWRITE_8(8'd2, `IPS6404L_SQ_RESET_ENABLE);
        8'd2: _PSRAM_CS(8'd3, 8'd0, `IPS6404L_SQ_CE_HIGH);
        8'd3: _PSRAM_CS(8'd4, 8'd0, `IPS6404L_SQ_CE_LOW);
        8'd4: _SPI_1LINE_READWRITE_8(8'd5, `IPS6404L_SQ_RESET);
        8'd5: _PSRAM_CS(8'd6, 8'd0, `IPS6404L_SQ_CE_HIGH);
        8'd6: _PSRAM_CS(8'hff, 8'd0, `IPS6404L_SQ_CE_LOW);
        8'hff: begin
            driver_state <= next_state;
            state <= 8'h0;
        end
        default: state <= 8'h0;
    endcase
end
endtask

reg[2:0] eid_type;
reg[44:0] eid;
reg[7:0] mfid;
reg[7:0] kdg;

task PSRAM_READ_EID;
input[3:0] next_state;
begin
    case (state)
        8'd0: _SPI_1LINE_READWRITE_8(8'd1, `IPS6404L_SQ_READ_ID);
    //     // 24 bytes of dummy address
        8'd1: _SPI_1LINE_READWRITE_8(8'd2, 8'hff);
        8'd2: _SPI_1LINE_READWRITE_8(8'd3, 8'hff);
        8'd3: _SPI_1LINE_READWRITE_8(8'd4, 8'hff);
        8'd4: _SPI_1LINE_READWRITE_8(8'd5, 8'h00);
        8'd5: begin
            mfid <= rx_buffer_low;
            state <= 8'd6;
        end
        8'd6: _SPI_1LINE_READWRITE_8(8'd7, 8'h00);
        8'd7: begin
            kdg <= rx_buffer_low;
            state <= 8'd8;
        end
        8'd8: _SPI_1LINE_READWRITE_8(8'd9, 8'h00);
        8'd9: begin
            eid_type <= rx_buffer_low[7:5];
            eid[44:40] <= rx_buffer_low[4:0];
            state <= 8'd10;
        end
        8'd10: _SPI_1LINE_READWRITE_8(8'd11, 8'h00);
        8'd11: begin
            eid[40:33] <= rx_buffer_low;
            state <= 8'd12;
        end
        8'd12: _SPI_1LINE_READWRITE_8(8'd13, 8'h00);
        8'd13: begin
            eid[32:25] <= rx_buffer_low;
            state <= 8'd14;
        end
        8'd14: _SPI_1LINE_READWRITE_8(8'd15, 8'h00);
        8'd15: begin
            eid[24:17] <= rx_buffer_low;
            state <= 8'd16;
        end
        8'd16: _SPI_1LINE_READWRITE_8(8'd17, 8'h00);
        8'd17: begin
            eid[16:9] <= rx_buffer_low;
            state <= 8'd18;
        end
        8'd18: _SPI_1LINE_READWRITE_8(8'd19, 8'h00);
        8'd19: begin
            eid[7:0] <= rx_buffer_low;
            state <= 8'd20;
        end
        8'd20: _PSRAM_CS(8'hff, 8'd0, `IPS6404L_SQ_CE_LOW);
        8'hff: begin
            state <= 8'h0;
            driver_state <= next_state;
        end
        default: state <= 8'h0;
    endcase
end
endtask

task PSRAM_FAST_READ;
input[3:0] next_state;
input[23:0] size;
begin
    case (state)
        8'd0: _SPI_1LINE_READWRITE_8(8'd1, `IPS6404L_SQ_READ_ID);
    //     // 24 bytes of dummy address
        8'd1: _SPI_1LINE_READWRITE_8(8'd2, 8'hff);
        8'd2: _SPI_1LINE_READWRITE_8(8'd3, 8'hff);
        8'd3: _SPI_1LINE_READWRITE_8(8'd4, 8'hff);
        8'd4: _SPI_1LINE_READWRITE_8(8'd5, 8'h00);
        8'd5: begin
            mfid <= rx_buffer_low;
            state <= 8'd6;
        end
        8'd6: _SPI_1LINE_READWRITE_8(8'd7, 8'h00);
        8'd7: begin
            kdg <= rx_buffer_low;
            state <= 8'd8;
        end
        8'd8: _SPI_1LINE_READWRITE_8(8'd9, 8'h00);
        8'd9: begin
            eid_type <= rx_buffer_low[7:5];
            eid[44:40] <= rx_buffer_low[4:0];
            state <= 8'd10;
        end
        8'd10: _SPI_1LINE_READWRITE_8(8'd11, 8'h00);
        8'd11: begin
            eid[40:33] <= rx_buffer_low;
            state <= 8'd12;
        end
        8'd12: _SPI_1LINE_READWRITE_8(8'd13, 8'h00);
        8'd13: begin
            eid[32:25] <= rx_buffer_low;
            state <= 8'd14;
        end
        8'd14: _SPI_1LINE_READWRITE_8(8'd15, 8'h00);
        8'd15: begin
            eid[24:17] <= rx_buffer_low;
            state <= 8'd16;
        end
        8'd16: _SPI_1LINE_READWRITE_8(8'd17, 8'h00);
        8'd17: begin
            eid[16:9] <= rx_buffer_low;
            state <= 8'd18;
        end
        8'd18: _SPI_1LINE_READWRITE_8(8'd19, 8'h00);
        8'd19: begin
            eid[7:0] <= rx_buffer_low;
            state <= 8'd20;
        end
        8'd20: _PSRAM_CS(8'hff, 8'd0, `IPS6404L_SQ_CE_LOW);
        8'hff: begin
            state <= 8'h0;
            driver_state <= next_state;
        end
        default: state <= 8'h0;
    endcase
end
endtask

task DELAY;
input [3:0] next_state;
input [15:0] delay_time;
begin
    psram_sclk_enable <= 1'b0;
    if (tick_counter <= delay_time) begin
        psram_ce_n <= 1'b1;
        tick_counter <= tick_counter + 16'd1;
    end
    else begin
        tick_counter <= 16'd0;
        psram_ce_n <= 1'b0;
        driver_state <= next_state;
    end
end
endtask

`define STATE_INIT 4'd0
`define STATE_WAITING_FOR_DEVICE 4'd1
`define STATE_RESET 4'd2
`define STATE_READ_EID 4'd3
`define STATE_VERIFY 4'd4
`define PSRAM_STATE_IDLE 4'd5

reg is_first_byte;

always @(negedge sysclk or posedge reset) begin
    case (driver_state)
        `STATE_INIT: begin
            state <= 0;
            is_first_byte <= 1'b1;
            driver_state <= `STATE_WAITING_FOR_DEVICE;
            debug_led <= 1;
        end
        `STATE_WAITING_FOR_DEVICE: begin
            DELAY(`STATE_RESET, 2000); // TODO: calculate value
        end
        `STATE_RESET: begin
            PSRAM_RESET(`STATE_READ_EID);
        end
        `STATE_READ_EID: begin
            PSRAM_READ_EID(`PSRAM_STATE_IDLE);
            debug_led <= 0;
        end
        `PSRAM_STATE_IDLE: begin
            //if (kdg == 8'h5d) debug_led <= 1'b0;
            if (set_address) begin
                $display("write %x to psram at address: %x", data, address);
            end
            else begin
                is_first_byte <= 1'b1;
            end
        end
        default: begin
        end
    endcase
end

reg operation_is_waiting;
reg [7:0] buffer;

// always @(posedge clock) begin
//     if (write) begin
//         $display("write to psram at address: %x", address);
//         operation_is_waiting <= 1'b1;
//         buffer <= data;
//     end
//     else begin
//         $display("read from address: %x", address);
//     end
// end

endmodule

`resetall
