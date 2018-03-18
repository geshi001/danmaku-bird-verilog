`timescale 1ns / 1ps

// The `display_scene` module describes an mapping to
// the colors of the scene (background, foreground, etc)
// from the coordinates (x, y). It is always synchronized 
// with game_state (i.e. It is a pure function). 

module display_scene(
	input wire clk,
	input wire clk_100Hz,
	input wire [8:0] y,
	input wire [9:0] x,
	input wire [1:0] game_state,
	output reg [11:0] data
    );
	
	localparam
		GAME_INITIAL = 2'd0,
		GAME_PLAYING = 2'd1,
		GAME_OVER    = 2'd2;
		
	// internal states
	
	reg [9:0] background_offset = 0;
	reg [9:0] foreground_offset = 0;
	
	wire [11:0] image_background_day;
	wire [11:0] image_background_night;
	wire [11:0] image_foreground;
	wire [11:0] image_title;
	
	reg [31:0] counter = 0;
	always @ (posedge clk_100Hz) begin
		counter <= counter + 1;
	end
	
	ROM_background_day ROM_background_day (
		.clka(clk),
		.addra((y - 286) * 278 + (x + background_offset) % 278),
		.douta(image_background_day)
	);
	
	ROM_foreground ROM_foreground (
		.clka(clk),
		.addra((y - 400) * 24 + (x + foreground_offset) % 24),
		.douta(image_foreground)
	);
	
	ROM_title ROM_title (
		.clka(clk),
		.addra((y - 140) * 218 + (x - 211)),
		.douta(image_title)
	);
	
	always @ (posedge clk_100Hz) begin
		case (game_state) 
			GAME_INITIAL: begin
				background_offset <= 0;
				foreground_offset <= 0;
			end
			GAME_PLAYING: begin
				if (background_offset < 277)
					background_offset <= background_offset + 1;
				else
					background_offset <= 0;
					
				if (foreground_offset < 24)
					foreground_offset <= foreground_offset + 2;
				else
					foreground_offset <= 0;
			end
			GAME_OVER: begin
			end
		endcase
	end


	always @ (*) begin
		if (y < 286)
			data = 12'hCC4;
		else if (y < 366)
			data = image_background_day;
		else if (y < 400)
			data = 12'h7E5;
		else
			data = image_foreground;
		if (game_state == GAME_INITIAL && (x >= 211 && x <429 && y >= 140 && y < 260))
			data = image_title;
	end


endmodule
