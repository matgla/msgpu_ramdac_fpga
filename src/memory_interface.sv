//`ifndef MEMORY_INTERFACE
//`define MEMORY_INTERFACE 

interface MemoryInterface();
    bit[23:0] input_address;
    bit[15:0] input_size; 
    byte input_data;
    
    int output_address; 
    int output_size;
    byte output_data;
    
    logic input_clock; 
    logic output_clock;
    bit busy;
endinterface

//`endif 
