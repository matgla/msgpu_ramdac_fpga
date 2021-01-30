`ifndef MCU_BUS_INTERFACE
`define MCU_BUS_INTERFACE 

typedef enum {
    MCU_BUS_INPUT,
    MCU_BUS_OUTPUT
} BusMode; 



interface McuBusExternalInterface(input system_clock);
    logic bus_clock;
    logic [7:0] signal_input; 
    logic [7:0] signal_output; 
    logic signal_direction; 
    logic signal_command_data_input;
    logic signal_command_data_output;

    reg [1:0] mcu_bus_clock_buffer;
    BusMode bus_mode;
    always @(bus_mode) begin 
        case (bus_mode)
            MCU_BUS_INPUT: signal_direction = 0;
            MCU_BUS_OUTPUT: signal_direction = 1; 
        endcase
    end

    always @(posedge system_clock) begin 
        bus_mode <= MCU_BUS_INPUT;
        mcu_bus_clock_buffer <= {mcu_bus_clock_buffer[0], bus_clock};
    end
    wire bus_clock_rising_edge = (mcu_bus_clock_buffer == 2'b01);
endinterface

interface McuBusInternalInterfaceInput();
    logic data_clock;
    logic command_clock; 
    byte data;
    byte command;
endinterface

`endif 
