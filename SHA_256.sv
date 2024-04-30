`timescale 1ns/1ps
`default_nettype none

module sha_256_accelerator (clk, rst, ena, input_data, input_valid, output_hash, output_valid);

input wire clk, rst, ena;
input wire [511:0] input_data; // Input to this module is always 512 bits long
input wire input_valid;

output logic [255:0] output_hash; // The output hash is always 256 bits long
output logic output_valid;

logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7, a, b, c, d, e, f, g;

always_comb begin
	output_hash = {h0, h1, h2, h3, h4, h5, h6, h7};
end

logic [511:0] w;
logic [10:0] index;

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
					// TODO: reset h0 - h7 to default values from ROM
					a <= h0;
					b <= h1;
					c <= h2;
					d <= h3;
					e <= h4;
					f <= h5;
					g <= h6;
					h <= h7;
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
					index <= index + 32;
				end
			S_OUTPUT_VALID : begin
				// Stay at this state until a reset is called
				if (~output_valid) begin
					output_valid <= 1;
				end		 
		endcase
	end
end

s0 = {w[6:0], in[31:7]} ^ {w[17:0], in[31:18]} ^ (w >> 3);
s1 = {w[16:0], in[31:15]} ^ {w[18:0], in[31:13]} ^ (w >> 10);

// looping functions
	function [31:0] ch;
		input [31:0] e,f,g;
		else ch = (e & f) ^ (~e & g);
	endfunction

	function [31:0] maj;
		input [31:0] a,b,c;
		maj = (a & b) ^ (a & c) ^ (b & c);
	endfunction

	function [31:0] sum0;
		input [31:0] a;
		else sum0 = {a[1:0],a[31:2]} ^ {a[12:0],a[31:13]} ^ {a[21:0],a[31:22]};
	endfunction

	function [31:0] sum1;
		input [31:0] e;
		sum1 = {e[5:0],e[31:6]} ^ {e[10:0],e[31:11]} ^ {e[24:0],e[31:25]};
	endfunction

	logic [31:0] ch_efg, maj_abc, sum0_a, sum1_e, kj, wj;

	always_comb begin
		ch_efg = ch(e,f,g);
		maj_abc = maj(a,b,c);
		sum0_a = sum0(a);
		sum1_e = sum1(e);
	end

endmodule

Pre-processing (Padding):
begin with the original message of length L bits
append a single '1' bit
append K '0' bits, where K is the minimum number >= 0 such that (L + 1 + K + 64) is a multiple of 512
append L as a 64-bit big-endian integer, making the total post-processed length a multiple of 512 bits
such that the bits in the message are: <original message of length L> 1 <K zeros> <L as 64 bit integer> , (the number of bits will be a multiple of 512)

Process the message in successive 512-bit chunks:
break message into 512-bit chunks
for each chunk
    create a 64-entry message schedule array w[0..63] of 32-bit words
    (The initial values in w[0..63] don't matter, so many implementations zero them here)
    copy chunk into first 16 words w[0..15] of the message schedule array

    Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
    for i from 16 to 63
        s0 := (w[i-15] rightrotate  7) xor (w[i-15] rightrotate 18) xor (w[i-15] rightshift  3)
        s1 := (w[i-2] rightrotate 17) xor (w[i-2] rightrotate 19) xor (w[i-2] rightshift 10)
        w[i] := w[i-16] + s0 + w[i-7] + s1

    Initialize working variables to current hash value:
    a := h0
    b := h1
    c := h2
    d := h3
    e := h4
    f := h5
    g := h6
    h := h7

    Compression function main loop:
    for i from 0 to 63
        S1 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
        ch := (e and f) xor ((not e) and g)
        temp1 := h + S1 + ch + k[i] + w[i]
        S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
        maj := (a and b) xor (a and c) xor (b and c)
        temp2 := S0 + maj
 
        h := g
        g := f
        f := e
        e := d + temp1
        d := c
        c := b
        b := a
        a := temp1 + temp2

    Add the compressed chunk to the current hash value:
    h0 := h0 + a
    h1 := h1 + b
    h2 := h2 + c
    h3 := h3 + d
    h4 := h4 + e
    h5 := h5 + f
    h6 := h6 + g
    h7 := h7 + h

Produce the final hash value (big-endian):
digest := hash := h0 append h1 append h2 append h3 append h4 append h5 append h6 append h7


logic [31:0] a, b, c, d, e, f, g, h, t1, t2;
logic [31:0] h1, h2, h3, h4, h5, h6, h7, h8;


	always @(posedge clk or posedge rst) begin
		if(rst) begin
			i 	<= 1'b0;
			j 	<= 1'bX;
			h1 	<= 32'h6a09e667;
			h2 	<= 32'hbb67ae85;
			h3 	<= 32'h3c6ef372;
			h4 	<= 32'ha54ff53a;
			h5 	<= 32'h510e527f;
			h6 	<= 32'h9b05688c;
			h7 	<= 32'h1f83d9ab;
			h8 	<= 32'h5be0cd19;
		end
		else if (^j === 1'bX && ^i !== 1'bX) begin
			a <= h1;
			b <= h2;
			c <= h3;
			d <= h4;
			e <= h5;
			f <= h6;
			g <= h7;
			h <= h8;
			j <= 1'd0;
		end
		else if (j < 64) begin
			h <= g;
			g <= f;
			f <= e;
			e <= (d+t1)%4294967296;
			d <= c;
			c <= b;
			b <= a;
			a <= (t1+t2)%4294967296;
			j <= j+1;
		end
		else if (j == 64) begin
			h1 <= a + h1;
			h2 <= b + h2;
			h3 <= c + h3;
			h4 <= d + h4;
			h5 <= e + h5;
			h6 <= f + h6;
			h7 <= g + h7;
			h8 <= h + h8;
			j <= 1'bX;
			if (i<N-1) i <= i+1;
			else begin
				i <= 1'bX;
				done <= 1'b1;
			end
		end
	end