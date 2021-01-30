`include "commands.v"
//`include "src/mcu_bus_interface.sv" 

module McuBus (
    McuBusExternalInterface external_bus,
    McuBusInternalInterfaceInput internal_bus_in
);

typedef enum {
    MCU_BUS_IDLE
} McuBusState;

always @(posedge external_bus.system_clock) begin 
    internal_bus_in.data_clock <= 1'b0;
    internal_bus_in.command_clock <= 1'b0;

    if (external_bus.bus_clock_rising_edge) begin 
        if (external_bus.signal_command_data_input == 1'b0) begin 
            internal_bus_in.command <= external_bus.signal_input;
            internal_bus_in.command_clock <= 1'b1;        
        end else begin 
            internal_bus_in.data <= external_bus.signal_input; 
            internal_bus_in.data_clock <= 1'b1;
        end
    end
end

always @(posedge external_bus.system_clock) begin 
    external_bus.signal_command_data_output = 0;
end

endmodule
