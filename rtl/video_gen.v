module video_gen
(
    input        RST_i,
    input        CLK_i,     // 27 MHz clock
    output [2:0] VID_HVD_o  // HS, VS, DE
);
    // 480p59.94 video format
    localparam HTOTAL  = 858; // Horizontal frequency : 31.468 kHz
    localparam VTOTAL  = 525; // Vertical frequency   : 59.94 Hz
    // 720 x 480
    localparam HACTIVE = 720;
    localparam VACTIVE = 480;
    // Horizontal synchro
    localparam HS_STRT =  16;
    localparam HS_STOP =  78;
    // Horizontal synchro
    localparam VS_STRT =  9;
    localparam VS_STOP =  15;
    // Blanking
    localparam HBLANK = HTOTAL - HACTIVE;
    localparam VBLANK = VTOTAL - VACTIVE;
    
    // ==================== Beam counters ====================
    
    reg [9:0] r_hctr_p0; // Horizontal counter
    reg [9:0] r_vctr_p0; // Vertical counter
    reg       r_eol_p0;  // End of line flag
    reg       r_eof_p0;  // End of frame flag
    
    always@(posedge CLK_i) begin : HV_COUNTER_P0

        if (RST_i) begin
            r_hctr_p0 <= 10'd0;
            r_vctr_p0 <= 10'd0;
            r_eol_p0  <= 1'b0;
            r_eof_p0  <= 1'b0;
        end
        else begin
            if (r_eol_p0) begin
                if (r_eof_p0) begin
                    r_vctr_p0 <= 10'd0;
                end
                else begin
                    r_vctr_p0 <= r_vctr_p0 + 10'd1;
                end
                r_hctr_p0 <= 10'd0;
            end
            else begin
                r_hctr_p0 <= r_hctr_p0 + 10'd1;
            end
            r_eol_p0  <= (r_hctr_p0 == (HTOTAL[9:0] - 10'd2)) ? 1'b1 : 1'b0;
            r_eof_p0  <= (r_vctr_p0 == (VTOTAL[9:0] - 10'd1)) ? 1'b1 : 1'b0;
        end
    end

    // ==================== Synchros generation ====================
    
    reg       r_shs_p1; // Set HS pulse
    reg       r_chs_p1; // Clear HS pulse
    reg       r_svs_p1; // Set VS pulse
    reg       r_cvs_p1; // Clear VS pulse
    reg       r_hsy_p1; // Horizontal synchro
    reg       r_vsy_p1; // Vertical synchro

    always@(posedge CLK_i) begin : HV_SYNC_P1

        if (RST_i) begin
            r_hsy_p1 <= 1'b0;
            r_vsy_p1 <= 1'b0;
            r_shs_p1 <= 1'b0;
            r_chs_p1 <= 1'b0;
            r_svs_p1 <= 1'b0;
            r_cvs_p1 <= 1'b0;
        end
        else begin
            r_hsy_p1 <= (r_hsy_p1 | r_shs_p1) & ~r_chs_p1;
            if (r_shs_p1) begin
                r_vsy_p1 <= (r_vsy_p1 | r_svs_p1) & ~r_cvs_p1;
            end
            // Horizontal comparators
            r_shs_p1 <= (r_hctr_p0 == (HS_STRT[9:0] - 10'd1)) ? 1'b1 : 1'b0;
            r_chs_p1 <= (r_hctr_p0 == (HS_STOP[9:0] - 10'd1)) ? 1'b1 : 1'b0;
            // Vertical comparators
            r_svs_p1 <= (r_vctr_p0 == VS_STRT[9:0]) ? 1'b1 : 1'b0;
            r_cvs_p1 <= (r_vctr_p0 == VS_STOP[9:0]) ? 1'b1 : 1'b0;
        end
    end

    // ==================== Data enable ====================

    reg       r_den_p1; // Data enable
    reg       r_vbl_p1; // Vertical blanking
    reg       r_shb_p1; // Set horizontal blanking
    reg       r_chb_p1; // Clear horizontal blanking
    reg       r_svb_p1; // Set vertical blanking
    reg       r_cvb_p1; // Clear vertical blanking

    always@(posedge CLK_i) begin : DATA_ENA_P1

        if (RST_i) begin
            r_den_p1 <= 1'b0;
            r_vbl_p1 <= 1'b1;
            r_shb_p1 <= 1'b0;
            r_chb_p1 <= 1'b0;
            r_svb_p1 <= 1'b0;
            r_cvb_p1 <= 1'b0;
        end
        else begin
            r_den_p1 <= (r_den_p1 | (r_chb_p1 & ~r_vbl_p1)) & ~r_shb_p1;
            r_vbl_p1 <= (r_vbl_p1 | r_svb_p1) & ~r_cvb_p1;
            r_shb_p1 <= r_eol_p0;
            r_chb_p1 <= (r_hctr_p0 == (HBLANK[9:0] - 10'd1)) ? 1'b1 : 1'b0;
            if (r_eol_p0) begin
                r_svb_p1 <= r_eof_p0;
            end
            r_cvb_p1 <= (r_vctr_p0 == VBLANK[9:0]) ? 1'b1 : 1'b0;
        end
    end
    
    assign VID_HVD_o = { r_hsy_p1, r_vsy_p1, r_den_p1 };

endmodule

