`timescale 1ns / 1ps

module shift_reg(
    input wire clk,
    input wire [63:0] pdata,
    output wire [3:0] sout
    );
    wire sck, sdat, clrn;
    reg oe;
    
    assign sout = {sck, sdat, oe, clrn};
    
    reg [64:0] shift;
    reg [11:0] counter = -1;
    
    wire sckEn = |shift[63:0];
    assign sck = ~clk & sckEn;
    assign sdat = shift[64];
    assign clrn = 1'b1;
    
    always @ (posedge clk) begin
        if (sckEn)
            shift <= {shift[63:0], 1'b0};
        else begin
            if (&counter) begin
                shift <= {pdata, 1'b1};
                oe <= 1'b0;
            end
            else
                oe <= 1'b1;
            counter <= counter + 1;
        end
    end


endmodule
