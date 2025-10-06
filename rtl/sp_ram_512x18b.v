module sp_ram_512x18b
(
    input         clock,
    input         rden,
    input         wren,
    input   [8:0] address,
    input  [17:0] data,
    output [17:0] q
);
    parameter string INIT_FILE = "NONE";

    reg [17:0] r_ram [0:511];
    
    initial begin : RAM_INIT
        integer _i;
        integer _v;
        
        if (INIT_FILE == "NONE") begin
            for (_i = 0; _i < 512; _i = _i + 1) begin
                r_ram[_i] = 18'b0;
            end
        end
        else if (INIT_FILE == "RAND") begin
            for (_i = 0; _i < 512; _i = _i + 1) begin
                _v = $random();
                r_ram[_i] = _v[17:0];
            end
        end
        else begin
            $readmemh(INIT_FILE, r_ram);
        end
    end
    
    always@(posedge clock) begin : WR_PORT

        if (wren) begin
            r_ram[address] <= data;
        end
    end
    
    reg [17:0] r_q_p1;
    reg [17:0] r_q_p2;

    always@(posedge clock) begin : RD_PORT

        if (rden) begin
            r_q_p1 <= r_ram[address];
        end
        r_q_p2 <= r_q_p1;
    end
    
    assign q = r_q_p2;

endmodule
