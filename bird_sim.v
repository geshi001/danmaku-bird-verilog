`timescale 1ns / 1ps

module bird_sim;

    // Inputs
    reg clk_100Hz;
    reg rst;
    reg start;
    reg kill;
    reg jump;
    reg fall;

    // Outputs
    wire [9:0] x;
    wire [8:0] y;
    wire [2:0] state;
    wire [1:0] animation_state;

    // Instantiate the Unit Under Test (UUT)
    bird uut (
        .clk_100Hz(clk_100Hz), 
        .rst(rst), 
        .start(start), 
        .kill(kill), 
        .jump(jump), 
        .fall(fall), 
        .x(x), 
        .y(y), 
        .state(state), 
        .animation_state(animation_state)
    );

    initial begin
        // Initialize Inputs
        clk_100Hz = 0;
        rst = 0;
        start = 0;
        kill = 0;
        jump = 0;
        fall = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        start = 1;
        #10;
        start = 0;
        #90;
        
        jump = 1;
        #10;
        jump = 0;
        #90;
    
        fall = 1;
        #10;
        fall = 0;
        #90;
        
        kill = 1;
        #10;
        kill = 0;
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

