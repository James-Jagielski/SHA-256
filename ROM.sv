`timescale 1ns/1ps
`default_nettype none

module block_rom_async(/*AUTOARG*/
    // Outputs
    data,
    // Inputs
    addr, clk
    );

    parameter WIDTH = 8;
    parameter LENGTH = 32;
    parameter INIT = "zeros.memh";

    input wire [$clog2(LENGTH)-1:0] addr;
    input wire                      clk;

    output logic [WIDTH-1:0] data;

    (* rom_style = "block" *) logic [WIDTH-1:0] rom [LENGTH-1:0];

    initial begin
        $display("Initializing block ROM from %s", INIT);
        $readmemh(INIT, rom); // Initializes the ROM with the values in the init file.
    end

    assign data = rom[addr];


endmodule