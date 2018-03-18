`timescale 1ns / 1ps

module bullet_sim;

    // Inputs
    reg clk_100Hz;
    reg rst;
    reg fire;
    reg [9:0] x_din;
    reg [8:0] y_din;
    reg [7:0] vx_din_16x;
    reg [12:0] vy_din_16x;

    // Outputs
    wire [9:0] x;
    wire [8:0] y;
    wire state;

    // Instantiate the Unit Under Test (UUT)
    bullet uut (
        .clk_100Hz(clk_100Hz), 
        .rst(rst), 
        .fire(fire), 
        .x_din(x_din), 
        .y_din(y_din), 
        .vx_din_16x(vx_din_16x), 
        .vy_din_16x(vy_din_16x), 
        .x(x), 
        .y(y), 
        .state(state)
    );

    initial begin
        // Initialize Inputs
        clk_100Hz = 1;
        rst = 0;
        fire = 0;
        x_din = 0;
        y_din = 0;
        vx_din_16x = 0;
        vy_din_16x = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        fire = 1;
        #10;
        fire = 0;
        #90;
        
        rst = 1;
        #10;
        rst = 0;
        #90;

    end
    
    always begin
        #5;
        clk_100Hz = ~clk_100Hz;
    end
      
endmodule

