`timescale 1ns / 1ps

module Seg7_decode(
    input wire [31:0] data,
    input wire [7:0] LE,
    output wire [63:0] pattern
    );
    wire [63:0] digits;
    
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin: decode
            Seg7_decoder decoder (
                .data(data[i*4+:4]),
                .seg(digits[i*8+:7])
            );
            assign digits[i*8+7] = 1;
            assign pattern[i*8+:8] = digits[i*8+:8] | {8{LE[i]}};
        end
    endgenerate

endmodule
