`default_nettype none
`timescale 1ns/1ps

// Based on UG901 - The Vivado Synthesis Guide
module block_rom(clk, addr, data);

parameter W = 32; // Width of each row of  the memory
parameter L = 64; // Length fo the memory
parameter INIT = "../mems/hash_values.memh";

input wire clk;
input wire [$clog2(L)-1:0] addr;
output logic [W-1:0] data;

(* rom_style = "block" *) logic [W-1:0] rom [0:L-1];
initial begin
  $display("###########################################");
  $display("Initializing block rom from file %s.", INIT);
  $display("###########################################");
  $readmemh(INIT, rom); // Initializes the ROM with the values in the init file.
end

always_ff @(posedge clk) begin : synthesizable_rom
  data <= rom[addr];
end

endmodule
