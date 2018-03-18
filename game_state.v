`timescale 1ns / 1ps

// The `game_state` module describes the FSM for the game as a whole.
// It takes several control signals, maintains internal states and
// transitions according to the control signals.  

module game_state(
    input wire clk,
    input wire start_game,
    input wire game_over,
    input wire restart,
    output reg [1:0] state = 0
    );

    localparam
        GAME_INITIAL = 2'd0,
        GAME_PLAYING = 2'd1,
        GAME_OVER    = 2'd2;

    reg [1:0] next_state = GAME_INITIAL;

    always @ (posedge clk) begin
        state <= next_state;
    end

    always @ (*) begin
        next_state = state;
        case (state)
            GAME_INITIAL: begin
                if (start_game & ~restart)
                    next_state = GAME_PLAYING;
            end
            GAME_PLAYING: begin
                if (game_over)
                    next_state = GAME_OVER;
                else if (restart)
                    next_state = GAME_INITIAL;
            end
            GAME_OVER: begin
                if (restart)
                    next_state = GAME_INITIAL;
            end
        endcase
    end

endmodule
