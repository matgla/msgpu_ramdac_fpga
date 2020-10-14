//Copyright (C)2014-2020 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.7Beta
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Fri Oct 09 21:29:33 2020

module osc (oscout);

output oscout;

OSCH osc_inst (
   .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 10;

endmodule //osc
