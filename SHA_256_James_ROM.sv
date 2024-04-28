

parameter ROM_L=13;
logic [$clog2(ROM_L)-1:0] rom_addr;
wire [7:0] rom_data;

block_rom #(.L(ROM_L), .W(8), .INIT("mems/block_rom.memh"))
ROM(
  .clk(clk), .addr(rom_addr), .data(rom_data)
);