`timescale 1ns / 1ps

module rand_gen_sim;

    // Inputs
    reg clk;

    // Outputs
    wire [31:0] rand;
    wire [2:0] rand_y = rand[24:22];
    // Instantiate the Unit Under Test (UUT)
    rand_gen uut (
        .clk(clk), 
        .rand(rand)
    );

    initial begin
        // Initialize Inputs
        clk = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here

    end
    
    always begin
        #1;
        clk = ~clk;
    end
      
endmodule

