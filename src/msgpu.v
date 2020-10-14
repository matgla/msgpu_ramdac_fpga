module msgpu (
   input clock,
   output hsync,
   output vsync,
   output [3:0] vga_red,
   output [3:0] vga_green,
   output [3:0] vga_blue 
);

pll vga_pll(
   .clkout(CLOCK_SYS),
   .clkoutd(CLOCK_PIXEL),
   .clkin(clock)
);


// HSYNC //
reg [10:0] hsync_counter;
wire line_end = (hsync_counter == 10'd799);
wire hsync_pulse = (hsync_counter >= 10'd656 && hsync_counter <= 10'd752);

always @(posedge CLOCK_PIXEL) begin 
   if (line_end) 
       hsync_counter <= 0;
   else 
       hsync_counter <= hsync_counter + 1;
end 

assign hsync = ~hsync_pulse;

// VSYNC //
reg [10:0] vsync_counter;
wire frame_end = (vsync_counter == 10'd524);
wire vsync_pulse = (vsync_counter >= 10'd490 && vsync_counter < 10'd492);

always @(posedge CLOCK_PIXEL) begin 
   if (frame_end) 
       vsync_counter <= 0;
   else if (line_end)
       vsync_counter <= vsync_counter + 1;
end 

assign vsync = ~vsync_pulse;

wire visible_area = (hsync_counter < 10'd640 && vsync_counter < 10'd480);

assign vga_red = (visible_area && hsync_counter < 150)? 4'b1111 : 4'b0000;
assign vga_blue = (visible_area && hsync_counter > 150)? 4'b1111 : 4'b0000;
assign vga_green = (visible_area && hsync_counter > 500)? 4'b1111 : 4'b0000;

endmodule
