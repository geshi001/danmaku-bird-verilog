`timescale 1ns / 1ps

// The `Top` module acts as a hub that connects all
// submodules together.

module Top(
    input wire clk,
    input wire rst,
    input wire ps2_clk,
    input wire ps2_data,
    output wire [3:0] R, G, B,
    output wire HS, VS,
    output wire Buzzer,
    output wire SEGLED_CLK,
    output wire SEGLED_CLR,
    output wire SEGLED_DO,
    output wire SEGLED_PEN
    );

    wire clk_25MHz, clk_100Hz, clk_4Hz;

    localparam
        GAME_INITIAL = 2'd0,
        GAME_PLAYING = 2'd1,
        GAME_OVER    = 2'd2;

    wire start_game;
    wire game_over;
    wire restart;
    wire [1:0] game_state;

    // FSM manipulating status of the game
    game_state game_state_handler (
        .clk(clk_100Hz),
        .start_game(start_game),
        .game_over(game_over),
        .restart(restart),
        .state(game_state)
    );

    reg [11:0] vga_data;
    wire [8:0] y;
    wire [9:0] x;


    // Pseudo-Random Number Generator
    wire [31:0] rand;
    rand_gen rand_gen(clk, rand);


    // Clock divider
    clock_div clock_div (
        .clk(clk),
        .clk_25MHz(clk_25MHz),
        .clk_100Hz(clk_100Hz),
        .clk_4Hz(clk_4Hz)
    );


    // VGA Driver
    VGA_driver VGA_driver (
        .clk_25MHz(clk_25MHz),
        .Din(vga_data),
        .row(y), .col(x),
        .R(R), .G(G), .B(B),
        .HS(HS), .VS(VS)
    );

    // Seg7 Driver
    wire [31:0] seg_data;
    Seg7_driver Seg7_driver (
        .clk(clk),
        .data(seg_data),
        .SEGLED_CLK(SEGLED_CLK),
        .SEGLED_DO(SEGLED_DO),
        .SEGLED_PEN(SEGLED_PEN),
        .SEGLED_CLR(SEGLED_CLR)
    );

    // PS2 Driver
    wire [7:0] ps2_byte;
    wire ps2_state;

    reg [2:0] ps2_state_sampling = 3'b0;
    wire ps2_posedge_state = ps2_state_sampling[1] & ~ps2_state_sampling[2];

    always @ (posedge clk_100Hz) begin
        ps2_state_sampling <= {ps2_state_sampling[1:0], ps2_state};
    end

    PS2_driver PS2_driver (
        .clk(clk),
        .rst(rst),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .ps2_byte(ps2_byte),
        .ps2_state(ps2_state)
    );

    wire keydown_ESC  = ps2_posedge_state && (ps2_byte == 8'h76);
    wire keydown_UP   = ps2_posedge_state && (ps2_byte == 8'h75);
    wire keydown_DOWN = ps2_posedge_state && (ps2_byte == 8'h72);

    // Press any key to start the game
    assign start_game = ps2_posedge_state;
    assign restart = keydown_ESC;

    // Background and Foreground Controllers
    wire [11:0] image_scene;

    display_scene display_scene (
        .clk(clk),
        .clk_100Hz(clk_100Hz),
        .y(y), .x(x),
        .game_state(game_state),
        .data(image_scene)
    );



    // Bird Controller
    localparam
        BIRD_ANIMATION_WING_UP   = 2'd0,
        BIRD_ANIMATION_WING_MID  = 2'd1,
        BIRD_ANIMATION_WING_DOWN = 2'd2,
        BIRD_ANIMATION_DEAD      = 2'd3;

    wire [9:0] bird_x;
    wire [8:0] bird_y;
    wire [2:0] bird_state;
    wire [1:0] bird_animation_state;

    bird bird_instance (
        .clk_100Hz(clk_100Hz),
        .start(game_state == GAME_PLAYING),
        .rst(game_state == GAME_INITIAL),
        .kill(game_state == GAME_OVER),
        .jump(keydown_UP),
        .fall(keydown_DOWN),
        .x(bird_x), .y(bird_y),
        .state(bird_state),
        .animation_state(bird_animation_state)
    );

    wire [15:0] bird_image [0:3];
    wire [9:0] bird_x_relative = x - bird_x;
    wire [8:0] bird_y_relative = y - bird_y;
    wire [9:0] bird_memory_addr =
        bird_y_relative * 34 + bird_x_relative;

    ROM_bird_y_u ROM_bird_y_u (
        .clka(clk),
        .addra(bird_memory_addr),
        .douta(bird_image[BIRD_ANIMATION_WING_UP])
    );

    ROM_bird_y_m ROM_bird_y_m (
        .clka(clk),
        .addra(bird_memory_addr),
        .douta(bird_image[BIRD_ANIMATION_WING_MID])
    );

    ROM_bird_y_d ROM_bird_y_d (
        .clka(clk),
        .addra(bird_memory_addr),
        .douta(bird_image[BIRD_ANIMATION_WING_DOWN])
    );

    ROM_bird_y_dead ROM_bird_y_dead (
        .clka(clk),
        .addra(bird_memory_addr),
        .douta(bird_image[BIRD_ANIMATION_DEAD])
    );




    // Targets Controller
    localparam TARGET_NUM_MAX = 20;
    localparam
        TARGET_INITIAL = 2'd0,
        TARGET_FLYING  = 2'd1,
        TARGET_DYING   = 2'd2;

    localparam
        TARGET_ANIMATION_WING_UP   = 2'd0,
        TARGET_ANIMATION_WING_MID  = 2'd1,
        TARGET_ANIMATION_WING_DOWN = 2'd2,
        TARGET_ANIMATION_DEAD      = 2'd3;

    reg [TARGET_NUM_MAX-1:0] target_start ;
    wire target_shot [0:TARGET_NUM_MAX-1];
    wire [9:0] target_x [0:TARGET_NUM_MAX-1];
    wire [8:0] target_y [0:TARGET_NUM_MAX-1];
    wire [1:0] target_state [0:TARGET_NUM_MAX-1];
    wire [1:0] target_animation_state [0:TARGET_NUM_MAX-1];
    wire [9:0] target_memory_addr [0:TARGET_NUM_MAX-1];
    wire [15:0] target_image [0:TARGET_NUM_MAX-1][0:3];
    wire [9:0] target_x_relative [0:TARGET_NUM_MAX-1];
    wire [8:0] target_y_relative [0:TARGET_NUM_MAX-1];
    wire [TARGET_NUM_MAX-1:0] target_state_dying;


    generate
        genvar target_connection_index;
        for (target_connection_index = 0; target_connection_index < TARGET_NUM_MAX; target_connection_index = target_connection_index + 1)
        begin: target_connection
            initial target_start[target_connection_index] = (target_connection_index == 0);
            target target_instance (
                .clk_100Hz(clk_100Hz),
                .rst(game_state == GAME_INITIAL),
                .start(target_start[target_connection_index] & clk_4Hz & (game_state == GAME_PLAYING)),
                .din(rand[24:22]),
                .shot(target_shot[target_connection_index]),
                .x(target_x[target_connection_index]),
                .y(target_y[target_connection_index]),
                .state(target_state[target_connection_index]),
                .animation_state(target_animation_state[target_connection_index])
            );
            assign target_x_relative[target_connection_index] = x - target_x[target_connection_index];
            assign target_y_relative[target_connection_index] = y - target_y[target_connection_index];
            assign target_memory_addr[target_connection_index] =
                target_y_relative[target_connection_index] * 34 + target_x_relative[target_connection_index];

            assign target_state_dying[target_connection_index] =
                (target_state[target_connection_index] == TARGET_DYING);

            ROM_bird_r_u ROM_bird_r_u (
                .clka(clk),
                .addra(target_memory_addr[target_connection_index]),
                .douta(target_image[target_connection_index][TARGET_ANIMATION_WING_UP])
            );

            ROM_bird_r_m ROM_bird_r_m (
                .clka(clk),
                .addra(target_memory_addr[target_connection_index]),
                .douta(target_image[target_connection_index][TARGET_ANIMATION_WING_MID])
            );

            ROM_bird_r_d ROM_bird_r_d (
                .clka(clk),
                .addra(target_memory_addr[target_connection_index]),
                .douta(target_image[target_connection_index][TARGET_ANIMATION_WING_DOWN])
            );

            ROM_bird_r_dead ROM_bird_r_dead (
                .clka(clk),
                .addra(target_memory_addr[target_connection_index]),
                .douta(target_image[target_connection_index][TARGET_ANIMATION_DEAD])
            );
        end
    endgenerate

    reg [4:0] target_emit_index = 0;
    always @ (posedge clk_4Hz) begin
        if (game_state == GAME_PLAYING)
            target_start <= {target_start[TARGET_NUM_MAX-2:0], target_start[TARGET_NUM_MAX-1]};
    end


    // Score Counter
    score_counter #(.WIDTH(TARGET_NUM_MAX)) score_counter (
        .clk(clk_100Hz),
        .rst(game_state == GAME_INITIAL),
        .data(target_state_dying),
        .number(seg_data)
    );

    // Bullets Controller
    wire [9:0] bullet_initial_x = bird_x + 28;
    wire [8:0] bullet_initial_y = bird_y + 7;

    localparam  BULLET_NUM_MAX = 21;
    localparam
        BULLET_INITIAL = 1'b0,
        BULLET_FIRING  = 1'b1;
    localparam BULLET_GROUP_NUM = 3;

    reg [BULLET_NUM_MAX-1:0] bullet_fire = 'b111;
    reg bullet_clear [0:BULLET_NUM_MAX-1];
    wire [7:0] bullet_vx_din_16x [0:BULLET_NUM_MAX-1];
    wire signed [12:0] bullet_vy_din_16x [0:BULLET_NUM_MAX-1];
    wire [9:0] bullet_x [0:BULLET_NUM_MAX-1];
    wire [8:0] bullet_y [0:BULLET_NUM_MAX-1];
    wire [0:BULLET_NUM_MAX-1] bullet_state;
    wire bullet_enable [0:BULLET_NUM_MAX/3-1];

    always @ (posedge clk_4Hz) begin
        if (game_state == GAME_PLAYING)
            bullet_fire = {bullet_fire[BULLET_NUM_MAX-4:0], bullet_fire[BULLET_NUM_MAX-1:BULLET_NUM_MAX-3]};
    end

    generate
        genvar bullet_connection_index;
        for (bullet_connection_index = 0; bullet_connection_index < BULLET_NUM_MAX; bullet_connection_index = bullet_connection_index + 1)
        begin: bullet_connection
            initial bullet_clear[bullet_connection_index] = 0;
            bullet bullet_instance (
                .clk_100Hz(clk_100Hz),
                .fire(bullet_fire[bullet_connection_index] & bullet_enable[bullet_connection_index / 3] & (game_state == GAME_PLAYING)),
                .rst((game_state == GAME_INITIAL) || bullet_clear[bullet_connection_index]),
                .x_din(bullet_initial_x),
                .y_din(bullet_initial_y),
                .vx_din_16x(bullet_vx_din_16x[bullet_connection_index]),
                .vy_din_16x(bullet_vy_din_16x[bullet_connection_index]),
                .x(bullet_x[bullet_connection_index]),
                .y(bullet_y[bullet_connection_index]),
                .state(bullet_state[bullet_connection_index])
            );
        end
        for (bullet_connection_index = 0; bullet_connection_index < BULLET_NUM_MAX; bullet_connection_index = bullet_connection_index + 3)
        begin: bullet_connection_groups
            assign bullet_enable[bullet_connection_index / 3] =
                ~|bullet_state[bullet_connection_index+:3];

            //assign bullet_vx_din_16x[bullet_connection_index    ] = 64;
            //assign bullet_vy_din_16x[bullet_connection_index    ] = 48;

            assign bullet_vx_din_16x[bullet_connection_index    ] = 76;
            assign bullet_vy_din_16x[bullet_connection_index    ] = 25;

            assign bullet_vx_din_16x[bullet_connection_index + 1] = 80;
            assign bullet_vy_din_16x[bullet_connection_index + 1] = 0;

            assign bullet_vx_din_16x[bullet_connection_index + 2] = 76;
            assign bullet_vy_din_16x[bullet_connection_index + 2] = -25;

            //assign bullet_vx_din_16x[bullet_connection_index + 4] = 64;
            //assign bullet_vy_din_16x[bullet_connection_index + 4] = -48;
        end
    endgenerate

    // Collisions of Targets and Bullets
    reg [BULLET_NUM_MAX-1:0] target_intersect [0:TARGET_NUM_MAX-1];

    generate
        genvar target_intersect_index, bullet_intersect_index;
        for (target_intersect_index = 0; target_intersect_index != TARGET_NUM_MAX; target_intersect_index = target_intersect_index + 1)
        begin: target_intersect_generation
            for (bullet_intersect_index = 0; bullet_intersect_index != BULLET_NUM_MAX; bullet_intersect_index = bullet_intersect_index + 1)
            begin: target_intersect_generation_inner
                always @ (*) begin
                    target_intersect[target_intersect_index][bullet_intersect_index] =
                        (bullet_state[bullet_intersect_index] == BULLET_FIRING) && (
                        (bullet_x[bullet_intersect_index] >= target_x[target_intersect_index] + 4 &&
                         bullet_x[bullet_intersect_index] < target_x[target_intersect_index] + 30 &&
                         bullet_y[bullet_intersect_index] >= target_y[target_intersect_index] + 2 &&
                         bullet_y[bullet_intersect_index] < target_y[target_intersect_index] + 22) ||
                        (bullet_x[bullet_intersect_index] + 7 >= target_x[target_intersect_index] + 4 &&
                         bullet_x[bullet_intersect_index] + 7 < target_x[target_intersect_index] + 30 &&
                         bullet_y[bullet_intersect_index] >= target_y[target_intersect_index] + 2 &&
                         bullet_y[bullet_intersect_index] < target_y[target_intersect_index] + 22) ||
                        (bullet_x[bullet_intersect_index] >= target_x[target_intersect_index] + 4 &&
                         bullet_x[bullet_intersect_index] < target_x[target_intersect_index] + 30 &&
                         bullet_y[bullet_intersect_index] + 7 >= target_y[target_intersect_index] + 2 &&
                         bullet_y[bullet_intersect_index] + 7 < target_y[target_intersect_index] + 22) ||
                        (bullet_x[bullet_intersect_index] + 7 >= target_x[target_intersect_index] + 4 &&
                         bullet_x[bullet_intersect_index] + 7 < target_x[target_intersect_index] + 30 &&
                         bullet_y[bullet_intersect_index] + 7 >= target_y[target_intersect_index] + 2 &&
                         bullet_y[bullet_intersect_index] + 7 < target_y[target_intersect_index] + 22));
                end
            end
            assign target_shot[target_intersect_index] = |target_intersect[target_intersect_index];
        end
    endgenerate

    reg [TARGET_NUM_MAX-1:0] bird_collision;
    generate
        genvar target_collide_with_bird_index;
        for (target_collide_with_bird_index = 0; target_collide_with_bird_index != TARGET_NUM_MAX; target_collide_with_bird_index = target_collide_with_bird_index + 1)
        begin: bird_collision_generation
            always @ (*) begin
                bird_collision[target_collide_with_bird_index] =
                    (target_state[target_collide_with_bird_index] == TARGET_FLYING) && (
                    (bird_x + 4>= target_x[target_collide_with_bird_index] + 4 &&
                     bird_x + 4< target_x[target_collide_with_bird_index] + 30 &&
                     bird_y + 2>= target_y[target_collide_with_bird_index] + 2 &&
                     bird_y + 2< target_y[target_collide_with_bird_index] + 22) ||
                    (bird_x + 30>= target_x[target_collide_with_bird_index] + 4 &&
                     bird_x + 30 < target_x[target_collide_with_bird_index] + 30 &&
                     bird_y + 2>= target_y[target_collide_with_bird_index] + 2 &&
                     bird_y + 2< target_y[target_collide_with_bird_index] + 22) ||
                    (bird_x + 4>= target_x[target_collide_with_bird_index] + 4 &&
                     bird_x + 4< target_x[target_collide_with_bird_index] + 30 &&
                     bird_y + 22 >= target_y[target_collide_with_bird_index] + 2 &&
                     bird_y + 22 < target_y[target_collide_with_bird_index] + 22) ||
                    (bird_x + 30 >= target_x[target_collide_with_bird_index] + 4 &&
                     bird_x + 30 < target_x[target_collide_with_bird_index] + 30 &&
                     bird_y + 22 >= target_y[target_collide_with_bird_index] + 2 &&
                     bird_y + 22 < target_y[target_collide_with_bird_index] + 22));
            end
        end
    endgenerate

    assign game_over = |bird_collision;


    // Display
    wire [15:0] image_game_over;

    ROM_game_over ROM_game_over (
        .clka(clk),
        .addra((y - 172) * 192 + (x - 224)),
        .douta(image_game_over)
    );

    integer target_display_index = 0;
    integer bullet_display_index = 0;
        always @ (posedge clk) begin
        case (game_state)
            GAME_INITIAL: begin
                if (bird_x_relative < 34 && bird_y_relative < 24 &&
                    bird_image[bird_animation_state][15:12])
                begin
                    vga_data <= bird_image[bird_animation_state][11:0];
                end
                else
                    vga_data <= image_scene;

            end
            GAME_PLAYING: begin
                vga_data <= image_scene;
                if (y < 400) begin
                    for (target_display_index = 0; target_display_index != TARGET_NUM_MAX; target_display_index = target_display_index + 1)
                    begin
                        if (target_state[target_display_index] != TARGET_INITIAL &&
                            target_x_relative[target_display_index] < 34 && target_y_relative[target_display_index] < 24 &&
                            target_image[target_display_index][target_animation_state[target_display_index]][15:12])
                        begin
                            vga_data <= target_image[target_display_index][target_animation_state[target_display_index]][11:0];
                        end
                    end
                    for (bullet_display_index = 0; bullet_display_index != BULLET_NUM_MAX; bullet_display_index = bullet_display_index + 1)
                    begin
                        if (bullet_state[bullet_display_index] != BULLET_INITIAL) begin
                            case ((y - bullet_y[bullet_display_index]) >> 1)
                                0: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    1: vga_data <= 12'h435;
                                    2: vga_data <= 12'h435;
                                endcase
                                1: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    0: vga_data <= 12'h435;
                                    1: vga_data <= 12'h5df;
                                    2: vga_data <= 12'h5df;
                                    3: vga_data <= 12'h435;
                                endcase
                                2: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    0: vga_data <= 12'h435;
                                    1: vga_data <= 12'h4bf;
                                    2: vga_data <= 12'h4bf;
                                    3: vga_data <= 12'h435;
                                endcase
                                3: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    1: vga_data <= 12'h435;
                                    2: vga_data <= 12'h435;
                                endcase
                            endcase
                        end
                    end
                end
                if (bird_x_relative < 34 && bird_y_relative < 24 &&
                    bird_image[bird_animation_state][15:12])
                begin
                    vga_data <= bird_image[bird_animation_state][11:0];
                end
            end

            GAME_OVER: begin
                vga_data <= image_scene;
                if (y < 400) begin
                    for (target_display_index = 0; target_display_index != TARGET_NUM_MAX; target_display_index = target_display_index + 1)
                    begin
                        if (target_state[target_display_index] != TARGET_INITIAL &&
                            target_x_relative[target_display_index] < 34 && target_y_relative[target_display_index] < 24 &&
                            target_image[target_display_index][target_animation_state[target_display_index]][15:12])
                        begin
                            vga_data <= target_image[target_display_index][target_animation_state[target_display_index]][11:0];
                        end
                    end
                    for (bullet_display_index = 0; bullet_display_index != BULLET_NUM_MAX; bullet_display_index = bullet_display_index + 1)
                    begin
                        if (bullet_state[bullet_display_index] != BULLET_INITIAL) begin
                            case ((y - bullet_y[bullet_display_index]) >> 1)
                                0: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    1: vga_data <= 12'h435;
                                    2: vga_data <= 12'h435;
                                endcase
                                1: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    0: vga_data <= 12'h435;
                                    1: vga_data <= 12'h5df;
                                    2: vga_data <= 12'h5df;
                                    3: vga_data <= 12'h435;
                                endcase
                                2: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    0: vga_data <= 12'h435;
                                    1: vga_data <= 12'h4bf;
                                    2: vga_data <= 12'h4bf;
                                    3: vga_data <= 12'h435;
                                endcase
                                3: case ((x - bullet_x[bullet_display_index]) >> 1)
                                    1: vga_data <= 12'h435;
                                    2: vga_data <= 12'h435;
                                endcase
                            endcase
                        end
                    end
                end
                if (bird_x_relative < 34 && bird_y_relative < 24 &&
                    bird_image[bird_animation_state][15:12])
                begin
                    vga_data <= bird_image[bird_animation_state][11:0];
                end
                if (game_state == GAME_OVER &&
                    x >= 224 && y >= 172 && x < 416 && y < 214 &&
                    image_game_over[15:12])
                begin
                    vga_data <= image_game_over[11:0];
                end
            end
            default: begin
                vga_data <= 12'h000;
            end
        endcase
    end

    assign Buzzer = 1;

endmodule
