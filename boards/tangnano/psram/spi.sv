// `ifndef PSRAM_SPI
// `define PSRAM_SPI 



// reg[7:0] state;
// reg spi_ce;

// reg[31:0] cs_delay;

// reg[3:0] spi_out;
// reg enable_spi_clock;
// reg[7:0] temp;

// task _PSRAM_CS;
// input[7:0] next_state;
// input[31:0] delay;
// input cs_n;
// begin
//     // debug_led <= 0;
//     spi_ce <= cs_n;
//     if (cs_delay < delay) begin
//         cs_delay <= cs_delay + 1;
//     end
//     else begin
//         // debug_led <= 0;
//         state <= next_state;
//         cs_delay <= 8'd0;
//     end
// end
// endtask

// task _SPI_1LINE_READWRITE_8;
// input[7:0] next_state;
// input[7:0] output_data;
// begin
//     current_spi_mode <= `SPI_MODE_1;
//     case (temp)
//         8'd0: begin
//             spi_out[0] <= output_data[7];
//             enable_spi_clock <= 1'b1;
//             // debug_led <= 0;
//             temp <= 8'd1;
//         end
//         8'd1: begin temp <= 8'd2; spi_out[0] <= output_data[6]; end
//         8'd2: begin temp <= 8'd3; spi_out[0] <= output_data[5]; end
//         8'd3: begin temp <= 8'd4; spi_out[0] <= output_data[4]; end
//         8'd4: begin temp <= 8'd5; spi_out[0] <= output_data[3]; end
//         8'd5: begin temp <= 8'd6; spi_out[0] <= output_data[2]; end
//         8'd6: begin temp <= 8'd7; spi_out[0] <= output_data[1]; end
//         8'd7: begin temp <= 8'd8; spi_out[0] <= output_data[0]; end
//         8'd8: begin
//             enable_spi_clock <= 1'b0;
//             spi_out[0] <= 0;
//             state <= next_state;
//             temp <= 8'h0;
//         end
//         default: temp <= 8'h0;
//     endcase
// end
// endtask


// `endif 
