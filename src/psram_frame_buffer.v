module psram_frame_buffer(
    input clock,
    input reset,
    output reg psram_ctrl,
    output reg psram_ce_n,
    output psram_sclk,
    output reg[3:0] psram_sio_out,
    input [3:0] psram_sio_in,
    output reg[3:0] psram_sio_dir,
    input
);

reg[7:0] state;
reg[7:0] task_state;
reg[7:0] task_x;
reg[15:0] tick_cnt;
reg[15:0] psram_eid;
reg[1:0] spi_mode;
reg[7:0] spi_buf_in;
reg[7:0] spi_buf_in_high;

`define SPI_MODE_1 2'b00
`define SPI_MODE_4_INPUTS 2'b01
`define SPI_MODE_4_OUTPUTS 2'b10
`define SPI_MODE_WAIT 2'b11

always @(spi_mode)
begin
    case (spi_mode)
    `SPI_MODE_1: psram_sio_dir = 4'b0001;
    `SPI_MODE_4_INPUTS: psram_sio_dir = 4'b0000;
    `SPI_MODE_4_OUTPUTS: psram_sio_dir = 4'b1111;
    `SPI_MODE_WAIT: psram_sio_dir = 4'b0000;
    endcase
end

/* Read from SPI */
always @(posedge psram_sclk or posedge reset) begin
    if (reset) begin
        spi_buf_in <= 8'hff;
        spi_buf_in_high <= 8'hff;
    end
    else begin
        case (spi_mode):
            `SPI_MODE_1: begin
                spi_buf_in <= {spi_buf_in[6:0], psram_sio_in[1]};
                spi_buf_in_high <= {spi_buf_in_high[6:0], spi_buf_in[7]};
            end
            `SPI_MODE_4_INPUTS: begin
                spi_buf_in <= {spi_buf_in[3:0], psram_sio_in};
                spi_buf_in_high <= {spi_buf_in_high[3:0], spi_buf_in[7:4]};
            end
            default: begin
            end
        endcase
    end
end

`define WAIT_CYCLE 8'd6;
`define PSRAM_CE_ON 1'b0;
`define PSRAM_CE_OFF 1'b1;
`define STATE_INIT 8'd0;

// this is SPI write procedure
task _SHIFT_INOUT_1:
input[7:0] next_state;
input[7:0] odata;
begin
    spi_mode <= `SPI_MODE_1;
    case (task_x)
        8'd0: begin
            psram_clk_out <= 1'b1;
            task_x <= 8'd1;
        end
        8'd1: begin
            psram_sio_out[0] <= odata[7];
            task_x <= 8'd2;
        end
        8'd2: begin
            psram_sio_out[0] <= odata[6];
            task_x <= 8'd3;
        end
        8'd3: begin
            psram_sio_out[0] <= odata[5];
            task_x <= 8'd4;
        end
        8'd4: begin
            psram_sio_out[0] <= odata[4];
            task_x <= 8'd5;
        end
        8'd5: begin
            psram_sio_out[0] <= odata[3];
            task_x <= 8'd6;
        end
        8'd6: begin
            psram_sio_out[0] <= odata[2];
            task_x <= 8'd7;
        end
        8'd7: begin
            psram_sio_out[0] <= odata[1];
            task_x <= 8'd8;
        end
        8'd8: begin
            psram_sio_out[0] <= odata[0];
            task_x <= 8'd9;
            psram_clk_out <= 1'b0;
        end
        8'd9: begin
            task_state <= next_state;
            task_x <= 16'd0;
        end
    endcase
end
endtask

task _SHIFT_OUT_4_24;
input [7:0] next_state;
input [23:0] out_data;
begin
    case (task_x)
        8'd0: begin
            spi_mode <= `SPI_MODE_4_OUTPUTS;
            psram_clk_out <= 1'b1;
            task_x <= 8'd1;
        end
        8'd1: begin
            task_x <= 8'd2;
            psram_sio_out <= out_data[23:20];
        end
        8'd2: begin
            task_x <= 8'd3;
            psram_sio_out <= out_data[19:16];
        end
        8'd3: begin
            task_x <= 8'd4;
            psram_sio_out <= out_data[15:12];
        end
        8'd4: begin
            task_x <= 8'd5;
            psram_sio_out <= out_data[11:8];
        end
        8'd5: begin
            task_x <= 8'd6;
            psram_sio_out <= out_data[7:4];
        end
        8'd6: begin
            task_x <= 8'd7;
            psram_sio_out <= out_data[3:0];
        end
        8'd7: begin
            task_x <= 8'd8;
        end
        8'd8: begin
            task_x <= 8'd0;
            task_state <= next_state;
        end
    endcase
end
endtask

task _SHIFT_IN_4_16_2;
input [7:0] next_state;
begin
    case (task_x)
        8'd0: begin
            lcd_fifo_wrreq <= 1'b0;
            psram_clk_out <= 1'b1;
            spi_mode <= `SPI_MODE_4_INPUTS;
            task_x <= 8'd1;
        end
        8'd1: begin
            task_x <= 8'd2;
        end
        8'd2: begin
            task_x <= 8'd3;
        end
        8'd3: begin
            task_x <= 8'd4;
        end
        8'd4: begin
            task_x <= 8'd5;
            psram_clk_out <= 1'b0;
        end
        8'd5: begin
            task_x <= 8'd6;
        end
        8'd6: begin
            task <= 8'd7;
        end
        8'd7: begin
            lcd_fifo_data <= {spi_buf_in_high, spi_buf_in};
            lcd_fifo_wrreq <= 1'b1;
            task <= 8'd0;
            task_state <= next_state;
        end
    endcase
end
endtask

task _PSRAM_CS;
input[7:0] next_state;
input[7:0] delay;
input cs_n;
begin
    psram_ce_n <= cs_n;
    if (task_x < delay) begin
        task_x <= task_x + 1;
    end
    else
        task_state <= next_state;
        task_x <= 8'd0;
    end
end
endtask

`define PSRAM_RESET_ENABLE_CODE 8'h66
`define PSRAM_RESET_CODE 8'h99

task PSRAM_RESET;
begin
    case (task_state)
        8'd0: begin
            psram_clk_out <= 1'b0;
            if (tick_cnt < 16'd2000)
            begin
                psram_ce_n < 1'b1;
                tick_cnt <= tick_cnt + 1'b1;
            end
            else begin
                tick_cnt <= 16'd0;
                task_x <= 8'd0;
                task_state <= 8'd1;
                psram_ce_n <= 1'b0;
            end
        end
        8'd1: _SHIFT_INOUT_1(8'd2, `PSRAM_RESET_ENABLE_CODE);
        8'd2: _PSRAM_CS(8'd3, 8'd0, `PSRAM_CE_OFF);
        8'd3: _PSRAM_CS(8'd4, 8'd0, `PSRAM_CE_ON);
        8'd4: _SHIFT_INOUT_1(8'd5, `PSRAM_RESET_CODE);
        8'd5: _PSRAM_CS(8'd6, 8'd10, `PSRAM_CE_OFF);
        8'd6: _PSRAM_CS(8'd7, 8'd0, `PSRAM_CE_ON);
        8'd7: _SHIFT_INOUT_1(8'd8, 8'h9f);
        8'd8: _SHIFT_INOUT_1(8'd9, 8'hff);
        8'd9: _SHIFT_INOUT_1(8'd10, 8'hff);
        8'd10: _SHIFT_INOUT_1(8'd11, 8'hff);
        8'd11: _SHIFT_INOUT_1(8'd12, 8'hff);
        8'd12: begin
            psram_eid[15:8] <= spi_buf_in;
            task_state <= 8'd13;
        end
        8'd13: _SHIFT_INOUT_1(8'd14, 8'hff);
        8'd14: begin
            psram_eid[7:0] <= spi_buf_in;
            task_state <= 8'd15;
        end
        8'd15: _PSRAM_CS(8'hff, 8'd0, `PSRAM_CE_OFF);
        8'hff: begin
        end
    endcase
end
endtask

task _PSRAM_WAIT:
input[7:0] next_state;
input[7:0] cycle;
begin
    spi_mode <= `SPI_MODE_WAIT;
    if (task_x < cycle) begin
        psram_clk_out <= 1'b1;
        task_x <= task_x + 1'b1;
    end
    else begin
        psram_clk_out <= 1'b0;
        if (~psram_clk_out) begin
            task_x <= 8'd0;
            task_state <= next_state;
        end
    end
end
endtask

`define PSRAM_WRITE_CODE 8'h38

task PSRAM_WRITE;
input[23:0] addr;
input[15:0] data;
begin
    case (task_state)
        8'd0: _PSRAM_CS(8'd1, 8'd0, `PSRAM_CE_ON);
        8'd1: _SHIFT_INOUT_1(8'd2, `PSRAM_WRITE_CODE);
        8'd2: _SHIFT_OUT_4_24(8'd5, addr);
        8'd5: _SHIFT_OUT_4_16(8'd6, data);
        8'd6: _SHIFT_OUT_4_16(8'd7, data);
        8'd7: _SHIFT_OUT_4_16(8'd8, data);
        8'd8: _SHIFT_OUT_4_16(8'd9, data);
        8'd9: _SHIFT_OUT_4_16(8'd10, data);
        8'd10: _SHIFT_OUT_4_16(8'd11, data);
        8'd11: _SHIFT_OUT_4_16(8'd12, data);
        8'd12: _SHIFT_OUT_4_16(8'd13, data);
        8'd13: _SHIFT_OUT_4_16(8'd14, data);
        8'd14: _SHIFT_OUT_4_16(8'd15, data);
        8'd15: _SHIFT_OUT_4_16(8'd16, data);
        8'd16: _SHIFT_OUT_4_16(8'd17, data);
        8'd17: _SHIFT_OUT_4_16(8'd18, data);
        8'd18: _SHIFT_OUT_4_16(8'd19, data);
        8'd19: _SHIFT_OUT_4_16(8'd20, data);
        8'd20: _SHIFT_OUT_4_16(8'd37, data);
        8'd37: _PSRAM_CS(8'hff, 8'd16, data);
        8'hff: begin
        end
    endcase
end
endtask

`define PSRAM_READ_CODE 8'heb

task PSRAM_READ;
input [23:0] addr;
begin
    case (task_state)
        8'd0: _PSRAM_CS(8'd1, 8'd0, `PSRAM_CE_ON);
        8'd1: _SHIFT_INOUT_1(8'd2, `PSRAM_READ_CODE);
        8'd5: _PSRAM_WAIT(8'd6, `WAIT_CYCLE);
        8'd6: _SHIFT_IN_4_16_2(8'd7);
        8'd7: _SHIFT_IN_4_16_2(8'd8);
        8'd8: _SHIFT_IN_4_16_2(8'd9);
        8'd9: _SHIFT_IN_4_16_2(8'd10);
        8'd10: _SHIFT_IN_4_16_2(8'd11);
        8'd11: _SHIFT_IN_4_16_2(8'd12);
        8'd12: _SHIFT_IN_4_16_2(8'd13);
        8'd13: _SHIFT_IN_4_16_2(8'd14);
        8'd14: _SHIFT_IN_4_16_2(8'd15);
        8'd15: _SHIFT_IN_4_16_2(8'd16);
        8'd16: _SHIFT_IN_4_16_2(8'd17);
        8'd17: _SHIFT_IN_4_16_2(8'd18);
        8'd18: _SHIFT_IN_4_16_2(8'd19);
        8'd19: _SHIFT_IN_4_16_2(8'd20);
        8'd20: _SHIFT_IN_4_16_2(8'd21);
        8'd21: _SHIFT_IN_4_16_2(8'd22);
        8'd22: begin
            lcd_fifo_wrreq <= 1'b0;
            _PSRAM_CS(8'hff, 8'd6, `PSRAM_CE_OFF);
        end
        8'hff: begin
        end
    endcase
end
endtask

// always @(negedge clk or posedge reset) begin
//     if (reset) begin
//         lcd_fifo_wrreq <= 1'b0;
//         lcd_fifo_data <= 16'hffff;
//         psram_clk_out <= 1'b0;
//         psram_ctrl <= 1'b0;
//         psram_ce_n <= 1'b1;
//         psram_sio_out <= 4'h0;
//         psram_eid <= 8'hffff;
//         task_state <= 8'd0;
//         tick_cnt <= 16'd0;
//         state <= `STATE_INIT;
//         px_cnt <= 24'd0;
//     end
//     else begin
//         case (state)
//             `STATE_INIT: begin
//                 psram_ctrl <= 1'b1;
//                 PSRAM_RESET();
//                 if (task_state == 8'hff) begin
//                     task_state <= 8'd0;
//                     task_x <= 8'd0;
//                     state <= 8'd1;
//                 end
//             end
//             8'd1: begin
//                 if (px_cnt < SC)
//             end
//         endcase
//     end
// end
