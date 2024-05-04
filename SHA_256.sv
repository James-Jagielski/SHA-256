`timescale 1ns/1ps
`default_nettype none

module sha_256_accelerator (clk, rst, ena, input_data, input_valid, output_hash, output_valid);

input wire clk, rst, ena;
input wire [511:0] input_data; // Input to this module is always 512 bits long
input wire input_valid;

output logic [255:0] output_hash; // The output hash is always 256 bits long
output logic output_valid;

logic [31:0] a, b, c, d, e, f, g, h;

always_comb begin
	output_hash = {a, b, c, d, e, f, g, h};
end

// wire [2047:0] k; // TODO: initialize this from the ROM
wire [32:0] k;
logic [2047:0] w;
logic [10:0] index;
parameter ROM_L=64;
logic [$clog2(ROM_L)-1:0] rom_addr;

enum logic [2:0] {
	S_IDLE = 0,
	S_COMPUTE_MSA,
	S_COMPRESSION_FUNC,
	S_OUTPUT_VALID
} hash_state;

always_ff @(posedge clk) begin : hashing_fsm
	if (rst) begin
		hash_state <= S_IDLE;
	end 
	else if (ena) begin
		case(hash_state)
			S_IDLE : begin
				if (input_valid) begin
					w <= {input_data, 1536'b0};
					index <= 16*32;
					a <= 32'h6a09e667;
					b <= 32'hbb67ae85;
					c <= 32'h3c6ef372;
					d <= 32'ha54ff53a;
					e <= 32'h510e527f;
					f <= 32'h9b05688c;
					g <= 32'h1f83d9ab;
					h <= 32'h5be0cd19;
					hash_state <= S_COMPUTE_MSA;
				end
			end
			S_COMPUTE_MSA : begin
				if (index == 63*32) begin
					hash_state <= S_COMPRESSION_FUNC;
					index <= 0;
				end
				else begin
					w[index : index+32] <= 
						w[index-16*32+31:index-16*32] + (
						{w[index-15*32+6:index-15*32], w[index-15*32+31:index-15*32+7]} ^ 
						{w[index-15*32+17:index-15*32], w[index-15*32+31:index-15*32+18]} ^
						(w[index-15*32+31:index-15*32] >> 3)) + 
						w[index-7*32+31:index-7*32] + (
						{w[index-2*32+16:index-2*32], w[index-2*32+31:index-2*32+17]} ^
						{w[index-2*32+18:index-2*32], w[index-2*32+31:index-2*32+19]} ^
						(w[index-2*32:index-2*32] >> 10));
					index <= index + 32;
				end
			end
			S_COMPRESSION_FUNC : begin
				if (index == 63*32) begin
					hash_state <= S_OUTPUT_VALID;
				end
				else begin

					block_rom #(.L(ROM_L), .W(32), .INIT("mems/has_values.memh")) ROM(.clk(clk), .addr(index/32), .data(k));
					h <= g;
					g <= f;
					f <= e;
					e <= d + (h + ({e[5:0], e[31:6]} ^ {e[10:0], e[31:11]} ^ {e[24:0], e[31:25]}) + ((e & f) ^ (~e & g)) + k[index+31:index] + w[index+31:index]);
					d <= c;
					c <= b;
					b <= a;
					a <= (h + ({e[5:0], e[31:6]} ^ {e[10:0], e[31:11]} ^ {e[24:0], e[31:25]}) + ((e & f) ^ (~e & g)) + k[index+31:index] + w[index+31:index]) + 
						(({a[1:0], a[31:2]} ^ {a[12:0], a[31:13]} ^ {a[21:0], a[31:22]}) + ((a & b) ^ (a & c) ^ (b & c)));
					index <= index + 32;
				end
			end
			S_OUTPUT_VALID : begin
				// Stay at this state until a reset is called
				if (~output_valid) begin
					output_valid <= 1;
					a <= 32'h6a09e667 + a;
					b <= 32'hbb67ae85 + b;
					c <= 32'h3c6ef372 + c;
					d <= 32'ha54ff53a + d;
					e <= 32'h510e527f + e;
					f <= 32'h9b05688c + f;
					g <= 32'h1f83d9ab + g;
					h <= 32'h5be0cd19 + h;
				end		
			end 
		endcase
	end
end
endmodule
