`timescale 1ns / 1ps

module game_state_sim;

    // Inputs
    reg clk;
    reg start_game;
    reg game_over;
    reg restart;

    // Outputs
    wire [1:0] state;

    // Instantiate the Unit Under Test (UUT)
    game_state uut (
        .clk(clk), 
        .start_game(start_game), 
        .game_over(game_over), 
        .restart(restart), 
        .state(state)
    );

    initial begin
        // Initialize Inputs
        clk = 1;
        start_game = 0;
        game_over = 0;
        restart = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        start_game = 1;
        #10;
        start_game = 0;
        #90;
        
        game_over = 1;
        #10;
        game_over = 0;
        #90;
        
        restart = 1;
        #10;
        restart = 0;
        start_game = 1;
        #10;
        start_game = 0;
        #80;
        
        restart = 1;
        #10;
        restart = 0;
        #90;
    end
    
    always begin
        #5;
        clk = ~clk;
    end
      
endmodule

