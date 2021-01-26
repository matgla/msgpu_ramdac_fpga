`include "commands.v"
`include "mcu_bus_interface.sv" 

module McudBus (
    McuBusInterface bus,
    output reg dataclk,
    output reg cmdclk, 
    input [7:0] data_in, 
    output reg[7:0] data_out
);

//`define GET_ID 8'h01

//`define STATE_IDLE 4'h00
//`define STATE_SEND_ID 4'h01
//`define STATE_SET_ADDRESS 4'h02
//`define STATE_SET_BANK 4'h03
//`define STATE_PROCESS_COMMAND 4'h04

//localparam MSGPU_ID = 8'hae;

//reg [3:0] state = `STATE_IDLE;

//reg [3:0] task_state = 4'b0;

//reg [7:0] command;

//task PROCESS_COMMAND;
//    input [7:0] cmd;
//    input [7:0] data;
//begin
//    case (cmd)
//        `GET_ID: begin
//            state <= `STATE_SEND_ID;
//            task_state <= 4'd0;
//            command <= 8'd0;
//        end
//        `SET_ADDRESS: begin
//            state <= `STATE_PROCESS_COMMAND;
//            case (task_state)
//                4'd0: begin
//                    task_state <= 4'd1;
//                end
//                4'd1: begin
//                    address[31:24] <= data[7:0];
//                    task_state <= 4'd2;
//                end
//                4'd2: begin
//                    address[23:16] <= data;
//                    task_state <= 4'd3;
//                end
//                4'd3: begin
//                    address[15:8] <= data;
//                    task_state <= 4'd4;

//                end
//                4'd4: begin
//                    address[7:0] <= data;
//                    task_state <= 4'd0;
//                    command <= 8'd0;
//                    state <= `STATE_IDLE;
//                    cmdclk <= 1'b1;
//                    data_out <= `SET_ADDRESS;
//                end
//                default: begin
//                    task_state <= 4'd0;
//                    state <= `STATE_IDLE;
//                end
//            endcase
//        end
//        default: begin end
//    endcase
//end
//endtask

//reg counter;

//always @(posedge sysclk) begin
//    dataclk <= 1'b0;
//    cmdclk <= 1'b0;
//    if (risingedge) begin
//        case (state)
//            `STATE_IDLE: begin
//                if (command_data == 1'b0) begin
//                    command <= bus_in;
//                    cmdclk <= 1'b1;
//                end
//                else begin
//                    data_out <= bus_in;
//                    dataclk <= 1'b1;
//                end
//            end
//            `STATE_SEND_ID: begin
//                case (task_state)
//                    4'd0: begin
//                        task_state <= 4'd1;
//                    end
//                    4'd1: begin
//                        bus_out <= 8'hae;
//                        state <= `STATE_IDLE;
//                        task_state <= 4'd0;
//                    end
//                    default: begin end
//                endcase
//            end
//            `STATE_PROCESS_COMMAND: begin
//                PROCESS_COMMAND(command, bus_in);
//            end
//            default: state <= `STATE_IDLE;
//        endcase
//    end
//end

always @(posedge bus.system_clock) begin 
    bus.signal_command_data_output = 0;
end

endmodule
