`timescale 1ns / 1ps


module target_sim;

    // Inputs
    reg clk_100Hz;
    reg rst;
    reg start;
    reg [2:0] din;
    reg shot;

    // Outputs
    wire [9:0] x;
    wire [8:0] y;
    wire [1:0] state;
    wire [1:0] animation_state;

    // Instantiate the Unit Under Test (UUT)
    target uut (
        .clk_100Hz(clk_100Hz), 
        .rst(rst),
        .start(start), 
        .din(din), 
        .shot(shot), 
        .x(x), 
        .y(y), 
        .state(state), 
        .animation_state(animation_state)
    );

    initial begin
        // Initialize Inputs
        clk_100Hz = 1;
        rst = 0;
        start = 0;
        din = 0;
        shot = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        start = 1;
        din = 3;
        #5;
        start = 0;
        
        #2895;
        start = 1;
        din = 5;
        #5;
        start = 0;
        #495;
        shot = 1;
        #5;
        shot = 0;
        #195;
        
        
        // Try to change 'start' in state TARGET_DYING
        // Should not affect the transition
        start = 1;
        #5;
        start = 0;
        #5;
        start = 1;
        #5;
        start = 0;
        #5;
        start = 1;
        #5;
        start = 0;
        #5;
        start = 1;
        #5;
        start = 0;
        #5;
        start = 1;
        #5;
        start = 0;
        #5;
        
    end
    
    always begin
        #5;
        clk_100Hz = ~clk_100Hz;
    end
      
endmodule

