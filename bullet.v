`timescale 1ns / 1ps

// The `bullet` module describes the FSM for bullets.
// It takes several control signals, maintains internal states and
// transitions according to the control signals.  

module bullet(
    input wire clk_100Hz,
    input wire rst,
    input wire fire,
    input wire [9:0] x_din,
    input wire [8:0] y_din,
    input wire [7:0] vx_din_16x,
    input wire signed [12:0] vy_din_16x,
    output wire [9:0] x,
    output wire [8:0] y,
    output reg state = 0
    );

    localparam
        BULLET_INITIAL = 1'b0,
        BULLET_FIRING  = 1'b1;

    assign x = x_16x[13:4];
    assign y = y_16x[12:4];

    // internal states
    reg [7:0] vx_16x = 0;
    reg signed [12:0] vy_16x = 0;
    reg [13:0] x_16x = 0; 
    reg [12:0] y_16x = 0;
    reg next_state = BULLET_INITIAL;
    
    initial begin
        x_16x = {x_din, 4'h0};
        y_16x = {y_din, 4'h0};
    end

    always @ (posedge clk_100Hz) begin
        state <= next_state;
        case (state)
            BULLET_INITIAL: begin
                x_16x <= {x_din, 4'h0};
                y_16x <= {y_din, 4'h0};
                vx_16x <= vx_din_16x;
                vy_16x <= vy_din_16x;
            end
            BULLET_FIRING: begin
                x_16x <= x_16x + vx_16x;
                y_16x <= y_16x + vy_16x;
            end
        endcase
    end


    always @ (*) begin
        next_state = state;
        case (state)
            BULLET_INITIAL: begin
                if (fire & ~rst)
                    next_state = BULLET_FIRING;
            end
            BULLET_FIRING: begin
                if (rst)
                    next_state = BULLET_INITIAL;
                if (x >= 640 || y >= 400)
                    next_state = BULLET_INITIAL;
            end
        endcase
    end


endmodule
