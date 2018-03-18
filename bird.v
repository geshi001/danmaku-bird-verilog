`timescale 1ns / 1ps

// The `bird` module describes the FSM for the bird (the yellow one).
// It takes several control signals, maintains internal states and
// transitions according to the control signals.  

module bird(
    input wire clk_100Hz,
    input wire rst,
    input wire start,
    input wire kill,
    input wire jump,
    input wire fall,
    output wire [9:0] x,
    output reg  [8:0] y = 180,
    output reg  [2:0] state = 0,
    output reg  [1:0] animation_state = 0
    );


    localparam
        BIRD_INITIAL    = 3'd0,
        BIRD_ASCENDING  = 3'd1,
        BIRD_DESCENDING = 3'd2,
        BIRD_JUMPING    = 3'd3, // keydown
        BIRD_FALLING    = 3'd4, // keydown
        BIRD_DYING      = 3'd5;

    localparam
        BIRD_ANIMATION_WING_UP   = 2'd0,
        BIRD_ANIMATION_WING_MID  = 2'd1,
        BIRD_ANIMATION_WING_DOWN = 2'd2,
        BIRD_ANIMATION_DEAD      = 2'd3;

    localparam
        BIRD_INITIAL_X = 100,
        BIRD_INITIAL_Y = 180;

    localparam a_10x = 1;
    localparam DESCEND = 0, ASCEND = 1;

    // internal states
    reg [2:0] next_state = BIRD_INITIAL;
    reg [4:0] animation_counter = 0;
    reg [31:0] vy_10x = 0;

    wire [31:0] vy = vy_10x / 10;
    assign x = BIRD_INITIAL_X;

    always @ (posedge clk_100Hz) begin
        state <= next_state;
        case (state)
            BIRD_INITIAL: begin
                y <= BIRD_INITIAL_Y;
                animation_counter <= animation_counter + 1;
                vy_10x <= 0;
            end
            BIRD_ASCENDING: begin
                animation_counter <= animation_counter + 1;
                if (y * 10 < vy_10x) begin
                    y <= 0;
                    vy_10x <= 0;
                end
                else begin
                    vy_10x <= vy_10x - a_10x;
                    y <= y - vy;
                end
            end
            BIRD_DESCENDING: begin
                animation_counter <= animation_counter + 1;
                if (y + vy > 376)
                    vy_10x <= 9 * (vy_10x - a_10x) / 10;
                else begin
                    vy_10x <= vy_10x + a_10x;
                    y <= y + vy;
                end
            end
            BIRD_JUMPING: begin
                animation_counter <= animation_counter + 1;
                if (y * 10 < vy_10x) begin
                    y <= 0;
                    vy_10x <= 0;
                end
                else begin
                    vy_10x <= 50;
                    y <= y - vy;
                end
            end
            BIRD_FALLING: begin
                animation_counter <= animation_counter + 1;
                if (y + vy > 376)
                    vy_10x <= 9 * (vy_10x - a_10x) / 10;
                else begin
                    vy_10x <= 30;
                    y <= y + vy;
                end
            end
            BIRD_DYING: begin
                if (y + vy > 376) begin
                    y <= 376;
                    vy_10x <= 0;
                end
                else begin
                    y <= y + vy;
                    vy_10x <= vy_10x + a_10x;
                end
            end
        endcase
    end

    always @ (*) begin
        if (state == BIRD_DYING)
            animation_state = BIRD_ANIMATION_DEAD;
        else begin
            case (animation_counter[4:3])
                2'd0: animation_state = BIRD_ANIMATION_WING_UP;
                2'd1: animation_state = BIRD_ANIMATION_WING_MID;
                2'd2: animation_state = BIRD_ANIMATION_WING_DOWN;
                2'd3: animation_state = BIRD_ANIMATION_WING_MID;
            endcase
        end
    end

    always @ (*) begin
        next_state = state;
        case (state)
            BIRD_INITIAL: begin
                if (start & ~rst)
                    next_state = BIRD_DESCENDING;
            end
            BIRD_ASCENDING: begin
                if (rst)
                    next_state = BIRD_INITIAL;
                else if (kill)
                    next_state = BIRD_DYING;
                else if (jump)
                    next_state = BIRD_JUMPING;
                else if (fall)
                    next_state = BIRD_FALLING;
                else if (vy_10x < 4)
                    next_state = BIRD_DESCENDING;
                else if (y * 10 < vy_10x)
                    next_state = BIRD_DESCENDING;
            end
            BIRD_DESCENDING: begin
                if (rst)
                    next_state = BIRD_INITIAL;
                else if (kill)
                    next_state = BIRD_DYING;
                else if (jump)
                    next_state = BIRD_JUMPING;
                else if (fall)
                    next_state = BIRD_FALLING;
                else if (y + vy > 376)
                    next_state = BIRD_ASCENDING;
            end
            BIRD_JUMPING: begin
                if (rst)
                    next_state = BIRD_INITIAL;
                else if (kill)
                    next_state = BIRD_DYING;
                next_state = BIRD_ASCENDING;
            end
            BIRD_FALLING: begin
                if (rst)
                    next_state = BIRD_INITIAL;
                else if (kill)
                    next_state = BIRD_DYING;
                next_state = BIRD_DESCENDING;
            end
            BIRD_DYING: begin
                if (rst)
                    next_state = BIRD_INITIAL;
            end
        endcase
    end
endmodule
