`timescale 1ns / 1ps

module Seg7_remap(
    input wire [31:0] in,
    output wire [31:0] out
    );
    assign out[ 7: 0] = {in[24], in[12], in[5], in[17], in[25], in[16], in[4], in[0]};
    assign out[15: 8] = {in[26], in[13], in[7], in[19], in[27], in[18], in[6], in[1]};
    assign out[23:16] = {in[28], in[14], in[9], in[21], in[29], in[20], in[8], in[2]};
    assign out[31:24] = {in[30], in[15], in[11],in[23], in[31], in[22], in[10],in[3]};
endmodule
