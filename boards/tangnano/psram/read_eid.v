// `ifndef PSRAM_READ_EID 
// `define PSRAM_READ_EID 


// reg[2:0] eid_type;
// reg[44:0] eid;
// reg[7:0] mfid;
// reg[7:0] kdg;

// reg[7:0] rx;

// task PSRAM_READ_EID;
// input[3:0] next_state;
// begin
//     case (state)
//         8'd0: _PSRAM_CS(8'd40, 8'd0, `IPS6404L_SQ_CE_LOW);
//         8'd40: _SPI_1LINE_READWRITE_8(8'd1, `IPS6404L_SQ_READ_ID);
//     //     // 24 bytes of dummy address
//         8'd1: _SPI_1LINE_READWRITE_8(8'd2, 8'hff);
//         8'd2: _SPI_1LINE_READWRITE_8(8'd3, 8'hff);
//         8'd3: _SPI_1LINE_READWRITE_8(8'd4, 8'hff);
//         8'd4: _SPI_1LINE_READWRITE_8(8'd5, 8'h00);
//         8'd5: begin
//             mfid <= rx;
//             state <= 8'd6;
//         end
//         8'd6: _SPI_1LINE_READWRITE_8(8'd7, 8'h00);
//         8'd7: begin
//             kdg <= rx;
//             state <= 8'd8;
//         end
//         8'd8: _SPI_1LINE_READWRITE_8(8'd9, 8'h00);
//         8'd9: begin
//             eid_type <= rx[7:5];
//             eid[44:40] <= rx[4:0];
//             state <= 8'd10;
//         end
//         8'd10: _SPI_1LINE_READWRITE_8(8'd11, 8'h00);
//         8'd11: begin
//             eid[40:33] <= rx;
//             state <= 8'd12;
//         end
//         8'd12: _SPI_1LINE_READWRITE_8(8'd13, 8'h00);
//         8'd13: begin
//             eid[32:25] <= rx;
//             state <= 8'd14;
//         end
//         8'd14: _SPI_1LINE_READWRITE_8(8'd15, 8'h00);
//         8'd15: begin
//             eid[24:17] <= rx;
//             state <= 8'd16;
//         end
//         8'd16: _SPI_1LINE_READWRITE_8(8'd17, 8'h00);
//         8'd17: begin
//             eid[16:9] <= rx;
//             state <= 8'd18;
//         end
//         8'd18: _SPI_1LINE_READWRITE_8(8'd19, 8'h00);
//         8'd19: begin
//             eid[7:0] <= rx;
//             state <= 8'd20;
//         end
//         8'd20: _PSRAM_CS(8'hff, 8'd0, `IPS6404L_SQ_CE_HIGH);
//         8'hff: begin
//             state <= 8'h0;
//             driver_state <= next_state;
//         end
//         default: state <= 8'h0;
//     endcase
// end
// endtask


// `endif 
