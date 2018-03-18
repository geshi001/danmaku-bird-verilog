`timescale 1ns / 1ps

// The Target Module describes the FSM for targets (the red birds).
// It takes several control signals, maintains internal states and
// transitions according to the control signals.  

module target(
    input wire clk_100Hz,
    input wire rst,
    input wire start,
    input wire [2:0] din,
    input wire shot,
    output wire [9:0] x,
    output reg  [8:0] y = 0,
    output reg  [1:0] state = 0,
    output reg  [1:0] animation_state = 0
    );

    localparam
        TARGET_INITIAL = 2'd0,
        TARGET_FLYING  = 2'd1,
        TARGET_DYING   = 2'd2;

    localparam
        TARGET_ANIMATION_WING_UP   = 2'd0,
        TARGET_ANIMATION_WING_MID  = 2'd1,
        TARGET_ANIMATION_WING_DOWN = 2'd2,
        TARGET_ANIMATION_DEAD      = 2'd3;

    localparam
        TARGET_INITIAL_X_OFFSET = 10'd674;

    localparam a_10x = 1;
    localparam vx_flying = 3, vx_dying = 2;

	// There are only 8 different values for yPos of targets
	// specifically 48, 88, 128, 168, 208, 248, 288, and 328
	// The module takes an random 3-bit value as input and
	// calculates corresponding yPos as follows.
    wire [8:0] y_data = {6'd0, din} * 9'd40 + 9'd48;

    // internal states
    reg [1:0] next_state = TARGET_INITIAL;
    reg [9:0] x_offset = TARGET_INITIAL_X_OFFSET;  
    reg [4:0] animation_counter = 0;
    reg [31:0] vy_10x = 0;

    assign x = x_offset - 10'd34;

    always @ (posedge clk_100Hz) begin
        state <= next_state;
        case (state)
            TARGET_INITIAL: begin
                y <= y_data;
                x_offset <= TARGET_INITIAL_X_OFFSET;
                animation_counter <= 0;
                vy_10x <= 0;
            end
            TARGET_FLYING: begin
                animation_counter <= animation_counter + 1;
                x_offset <= x_offset - vx_flying;
            end
            TARGET_DYING: begin
                y <= y + (vy_10x / 10);
                vy_10x <= vy_10x + a_10x;
                x_offset <= x_offset - vx_dying;
            end
        endcase
    end

    always @ (*) begin
        if (state == TARGET_DYING)
            animation_state = TARGET_ANIMATION_DEAD;
        else begin
            case (animation_counter[4:3])
                2'd0: animation_state = TARGET_ANIMATION_WING_UP;
                2'd1: animation_state = TARGET_ANIMATION_WING_MID;
                2'd2: animation_state = TARGET_ANIMATION_WING_DOWN;
                2'd3: animation_state = TARGET_ANIMATION_WING_MID;
            endcase
        end
    end

    always @ (*) begin
        next_state = state;
        case (state)
            TARGET_INITIAL: begin
                if (start & ~rst)
                    next_state = TARGET_FLYING;
            end
            TARGET_FLYING: begin
                if (rst)
                    next_state = TARGET_INITIAL;
                else if (x_offset <= 3 || y >= 400 || (y != 48 && y != 88 && y != 128 && y != 168 && y != 208 && y != 248 && y != 288 && y != 328))
                    next_state = TARGET_INITIAL;
                else if (shot)
                    next_state = TARGET_DYING;
            end
            TARGET_DYING: begin
                if (rst)
                    next_state = TARGET_INITIAL;
                else if (x_offset <= 3 || y >= 400)
                    next_state = TARGET_INITIAL;
            end
        endcase
    end

endmodule
