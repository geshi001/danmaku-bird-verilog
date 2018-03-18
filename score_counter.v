`timescale 1ns / 1ps

// The `score_counter` module describes a counter for 
// detecting the positive edge updates in a bit vector.
// For example, if a 4-bit vector A changes its value
// from 4'b0101 to 4'b1011, this module will detect 
// that there are 2 bits changed from 0 to 1 
// (namely A[1] and A[3]) and ignore the changes from
// 1 to 0 or those bits whose value doesn't change.
// The value is then fed into a counter which 
// accumulates the values and converted into 32-bit
// BCD codes for further use.

module score_counter(clk, rst, data, number);
    parameter WIDTH = 20;
    input wire clk;
    input wire rst;
    input wire [WIDTH-1:0] data;
    output reg [31:0] number; // hex
    reg [31:0] number_dec;

    initial number_dec = 0;
    reg [WIDTH-1:0] sampling [0:1];
    
    always @ (posedge clk) begin
        sampling[1] <= sampling[0];
        sampling[0] <= data;
    end
    
    wire [WIDTH-1:0] posedge_data;

    assign posedge_data = 
        sampling[0] & ~sampling[1];
    
    
    reg [31:0] popcount;
    integer i;
    always @ (*) begin
        popcount = 0;
        for (i = 0; i < WIDTH; i = i + 1) 
            popcount = popcount + posedge_data[i];
    end
    
    always @ (posedge clk) begin
        if (rst)
            number_dec <= 0;
        else
            number_dec <= number_dec + popcount;
    end
    
    always @ (*) begin
        number[ 3: 0] = number_dec            % 10;
        number[ 7: 4] = number_dec /       10 % 10;
        number[11: 8] = number_dec /      100 % 10;
        number[15:12] = number_dec /     1000 % 10;
        number[19:16] = number_dec /    10000 % 10;
        number[23:20] = number_dec /   100000 % 10;
        number[27:24] = number_dec /  1000000 % 10;
        number[31:28] = number_dec / 10000000 % 10;
    end
    
endmodule
