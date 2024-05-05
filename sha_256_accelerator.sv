`timescale 1ns/1ps
`default_nettype none

module sha_256_accelerator (clk, rst, ena, input_data, input_valid, output_hash, output_valid);

input wire clk, rst, ena;
input wire [511:0] input_data; // Input to this module is in chunks of 512 bits
input wire input_valid;

output logic [255:0] output_hash; // The output hash is always 256 bits long
output logic output_valid;

logic [31:0] a, b, c, d, e, f, g, h, h0, h1, h2, h3, h4, h5, h6, h7;

always_comb begin
	output_hash = {h0, h1, h2, h3, h4, h5, h6, h7};
end

wire [31:0] k;
logic [2047:0] w;
logic [10:0] index;

enum logic [2:0] {
	S_IDLE = 0,
	S_START_CHUNK,
	S_COMPUTE_MSA,
	S_COMPRESSION_FUNC,
	S_OUTPUT_VALID
} hash_state;

block_rom ROM (.clk(clk), .addr(64-index[10:5]), .data(k));

always_ff @(posedge clk) begin : hashing_fsm
	if (rst) begin
		hash_state <= S_IDLE;
	end 
	else if (ena) begin
		case(hash_state)
			S_IDLE : begin
				h0 <= 32'h6a09e667;
				h1 <= 32'hbb67ae85;
				h2 <= 32'h3c6ef372;
				h3 <= 32'ha54ff53a;
				h4 <= 32'h510e527f;
				h5 <= 32'h9b05688c;
				h6 <= 32'h1f83d9ab;
				h7 <= 32'h5be0cd19;
				output_valid <= 0;
				if (input_valid) begin
					hash_state <= S_START_CHUNK;
				end
			end
			S_START_CHUNK : begin
				if (input_valid) begin
					w <= {input_data, 1536'b0};
					index <= 2047 - 16*32;
					hash_state <= S_COMPUTE_MSA;
					output_valid <= 0;
				end
			end
			S_COMPUTE_MSA : begin
				w[index-:32] <= 
					w[index+16*32-:32] + (
					{w[index+15*32-25-:7], w[index+15*32-:25]} ^ 
					{w[index+15*32-14-:18], w[index+15*32-:14]} ^
					(w[index+15*32-:32] >> 3)) + 
					w[index+7*32-:32] + (
					{w[index+2*32-15-:17], w[index+2*32-:15]} ^
					{w[index+2*32-13-:19], w[index+2*32-:13]} ^
					(w[index+2*32-:32] >> 10));
				if (index == 31) begin
					hash_state <= S_COMPRESSION_FUNC;
					index <= 2047;
					a <= h0;
					b <= h1;
					c <= h2;
					d <= h3;
					e <= h4;
					f <= h5;
					g <= h6;
					h <= h7;
				end
				else begin
					index <= index - 32;
				end
			end
			S_COMPRESSION_FUNC : begin
				h <= g;
				g <= f;
				f <= e;
				e <= d + (h + ({e[5:0], e[31:6]} ^ {e[10:0], e[31:11]} ^ {e[24:0], e[31:25]}) + ((e & f) ^ (~e & g)) + k + w[index-:32]);
				d <= c;
				c <= b;
				b <= a;
				a <= (h + ({e[5:0], e[31:6]} ^ {e[10:0], e[31:11]} ^ {e[24:0], e[31:25]}) + ((e & f) ^ (~e & g)) + k + w[index-:32]) + 
					(({a[1:0], a[31:2]} ^ {a[12:0], a[31:13]} ^ {a[21:0], a[31:22]}) + ((a & b) ^ (a & c) ^ (b & c)));
				if (index == 31) begin
					hash_state <= S_OUTPUT_VALID;
				end
				else begin
					index <= index - 32;
				end
			end
			S_OUTPUT_VALID : begin
				output_valid <= 1;
				h0 <= h0 + a;
				h1 <= h1 + b;
				h2 <= h2 + c;
				h3 <= h3 + d;
				h4 <= h4 + e;
				h5 <= h5 + f;
				h6 <= h6 + g;
				h7 <= h7 + h;
				hash_state <= S_START_CHUNK;	
			end 
		endcase
	end
end
endmodule
