module video_top
(
    input        RST_i,
    input        CLK_i,

    output [7:0] VID_R_o,
    output [7:0] VID_G_o,
    output [7:0] VID_B_o,
    output [2:0] VID_HVD_o
);

wire [2:0] w_vid_hvd_gen;

video_gen U_video_gen
(
    .RST_i     (RST_i),
    .CLK_i     (CLK_i),
    .VID_HVD_o (w_vid_hvd_gen)
);

wire [7:0] w_vid_r_sf;
wire [7:0] w_vid_g_sf;
wire [7:0] w_vid_b_sf;
wire [2:0] w_vid_hvd_sf;

video_starfield U_video_starfield
(
    .RST_i     (RST_i),
    .CLK_i     (CLK_i),
    .VID_HVD_i (w_vid_hvd_gen),
    .VID_R_o   (w_vid_r_sf),
    .VID_G_o   (w_vid_g_sf),
    .VID_B_o   (w_vid_b_sf),
    .VID_HVD_o (w_vid_hvd_sf)
);

assign VID_R_o   = w_vid_r_sf;
assign VID_G_o   = w_vid_g_sf;
assign VID_B_o   = w_vid_b_sf;
assign VID_HVD_o = w_vid_hvd_sf;

endmodule
