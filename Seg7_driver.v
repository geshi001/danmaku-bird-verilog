`timescale 1ns / 1ps

// The `Seg7_driver` module describes a driver for the seven-segment display.

module Seg7_driver(
    input wire clk,
    input wire [31:0] data,
    output wire SEGLED_CLK, SEGLED_DO, SEGLED_PEN, SEGLED_CLR
    );

    reg [31:0] clk_div = 0;
    always @ (posedge clk) begin
        clk_div <= clk_div + 1;
    end
    
    wire clk_io = clk_div[3];
    wire [1:0] clk_scan = clk_div[15:14];
    wire clk_blink = clk_div[25];
    
    wire [63:0] disp_data;
    wire [31:0] disp_pattern;
    wire [3:0] sout;
    
    Seg7_decode decode (
        .data(data),
        .LE(8'h00),
        .pattern(disp_data)
    );
    
    Seg7_remap remap (
        .in(data),
        .out(disp_pattern)
    );
    
    shift_reg shift_reg (
        .clk(clk_io),
        .pdata(disp_data),
        .sout(sout)
    );
    assign {SEGLED_CLK, SEGLED_DO, SEGLED_PEN, SEGLED_CLR} = sout;
    
endmodule
