module video_starfield
(
    input        RST_i,
    input        CLK_i,
    //
    input  [2:0] VID_HVD_i,
    //
    output [7:0] VID_R_o,
    output [7:0] VID_G_o,
    output [7:0] VID_B_o,
    output [2:0] VID_HVD_o
);
    wire      w_hs_p0 = VID_HVD_i[2];
    wire      w_vs_p0 = VID_HVD_i[1];
    wire      w_de_p0 = VID_HVD_i[0];

    // ==================== Pixel position ====================

    reg [9:0] r_hpos_p0; // 0 - 719
    reg [8:0] r_vpos_p0; // 0 - 479

    always@(posedge CLK_i) begin : HV_POS_P0

        if (RST_i) begin
            r_hpos_p0 <= 10'd0;
            r_vpos_p0 <=  9'd0;
        end
        else begin
            // HS pulse clears the horizontal position
            if (w_hs_p0) begin
                r_hpos_p0 <= 10'd0;
            end
            // When DE = 1 : increment the horizontal position
            else if (w_de_p0) begin
                r_hpos_p0 <= r_hpos_p0 + 10'd1;
            end
            
            // HS pulse clears the vertical position
            if (w_vs_p0) begin
                r_vpos_p0 <= 9'd0;
            end
            // On HS rising edge, if DE was set, increment the vertical position
            else if ((w_hs_p0) && (r_hpos_p0[9:4] != 6'd0)) begin
                r_vpos_p0 <= r_vpos_p0 + 9'd1;
            end
        end
    end

    // ==================== HVD controls ====================

    reg         r_hs_p1;
    reg         r_vs_p1;
    reg         r_de_p1;
    
    reg         r_hs_p2;
    reg         r_vs_p2;
    reg         r_de_p2;

    always@(posedge CLK_i) begin : HVD_CTRL_P1_P2
        
        // Forward controls : stage #1 -> stage #2
        r_hs_p2 <= r_hs_p1;
        r_vs_p2 <= r_vs_p1;
        r_de_p2 <= r_de_p1;

        // Forward controls : stage #0 -> stage #1
        r_hs_p1 <= w_hs_p0;
        r_vs_p1 <= w_vs_p0;
        r_de_p1 <= w_de_p0;
    end
    
    // ==================== Starfield RAM ====================
    
    wire [17:0] w_star_ram_q;
    wire [17:0] w_star_ram_data;
    wire [12:0] w_star_hpos;
    wire  [4:0] w_star_hinc;
    
    sp_ram_512x18b
    #(
        .INIT_FILE ("star_ram.mem")
    )
    U_star_ram
    (
        .clock     (CLK_i),
        .rden      (w_hs_p0 & r_hs_p1),
        .wren      (w_de_p0 & r_de_p1),
        .address   (r_vpos_p0),
        .data      (w_star_ram_data),
        .q         (w_star_ram_q)
    );

    // Read horizontal position and increment
    assign w_star_hinc = w_star_ram_q[17:13];
    assign w_star_hpos = w_star_ram_q[12: 0];
    // Write back the new horizontal position
    assign w_star_ram_data[17:13] = w_star_hinc;
    assign w_star_ram_data[12: 0] = w_star_hpos + { 8'b0, w_star_hinc };
    
    reg       r_star_on_p1;
    reg [4:0] r_star_luma_p2;

    always@(posedge CLK_i) begin : DISPLAY_STARS_P1_P2
    
        r_star_on_p1   <= (r_hpos_p0 == w_star_hpos[12:3]) ? w_de_p0 : 1'b0;
        r_star_luma_p2 <= (r_star_on_p1) ? w_star_hinc : 5'b0;
    end
    
    assign VID_R_o   = { r_star_luma_p2, 3'b0 };
    assign VID_G_o   = { r_star_luma_p2, 3'b0 };
    assign VID_B_o   = { r_star_luma_p2, 3'b0 };
    assign VID_HVD_o = { r_hs_p2, r_vs_p2, r_de_p2 };

endmodule
