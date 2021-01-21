// `ifndef PSRAM_READ
// `define PSRAM_READ 

// `include "commands.v"
// `include "globals.v"
// `include "spi.sv"

// reg[23:0] current_position;
// reg[7:0] state;

// task PSRAM_READ; 
// input [3:0] next_state;
// input [23:0] address; 
// input [15:0] size;
// begin 
//     case (state)
//         8'h00: begin 
//             current_position <= 0;
//             _PSRAM_CS(8'h01, 8'h00, `IPS6404L_SQ_CE_LOW);
//         end
//         8'h01: begin 
//             _SPI_1LINE_READWRITE_8(8'h02, `IPS6404L_SQ_READ);
//         end
//         8'h02: _SPI_1LINE_READWRITE_8(8'h03, address[23:16]);
//         8'h03: _SPI_1LINE_READWRITE_8(8'h04, address[15:8]);
//         8'h04: _SPI_1LINE_READWRITE_8(8'h05, address[7:0]);
//         8'h05: begin 
//             _SPI_1LINE_READWRITE_8(8'h07, 8'h00);
//         end
//         8'h07: begin 
//             if (current_position < size - 1) begin 
//                 current_position <= current_position + 1;
//                 state <= 8'h05;
//             end else begin 
//                 state <= 8'h06;
//             end
//         end
//         8'h06: begin 
//             driver_state <= next_state;
//             state <= 0;
//             _PSRAM_CS(8'h05, 8'h00, `IPS6404L_SQ_CE_HIGH);
//         end
//         default: begin 
//             driver_state <= next_state;
//         end
//     endcase
// end
// endtask

// `endif
