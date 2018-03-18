`timescale 1ns / 1ps

// The `rand_gen` module describes a pseudorandom number generator
// based on linear congruential relationships. 
//   	X_n+1 = (a * X_n + c) mod m
// The parameters we selected here is 
//		a = 1103515235,
//		c = 12345,
//		m = 2^31
// as suggested in the ISO/IEC 9899.

module rand_gen(
    input wire clk,
    output reg [31:0] rand
    );
    
    initial rand = 1;
    
    always @ (posedge clk) begin 
        rand <= (rand * 32'h41C6_4E6D + 32'h0000_3039) & 32'h7ffff_ffff;
    end

endmodule
