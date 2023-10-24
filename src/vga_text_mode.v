module index_ram (
    input             clk,
    input             wr_en,
    input      [10:0] wr_addr,
    input      [7:0]  wr_data,
    input             rd_en,
    input      [10:0] rd_addr,
    output reg [7:0]  rd_data = 8'h00
);
    reg [7:0] mem [0:1<<13];

    always @(posedge clk) begin
        if (rd_en)
            rd_data <= mem[rd_addr];
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end
endmodule

module vga_text_mode (
    input             clk100,
    input             wr_en,
    input      [10:0] wr_addr,
    input      [7:0]  wr_data,
    input             blit_en,
    input      [10:0] blit_start,
    input      [10:0] blit_end,
    input      [7:0]  blit_offset,
    output reg        blit_complete = 0,
    output     [2:0]  vga_red,
    output     [2:0]  vga_green,
    output     [2:0]  vga_blue,
    output            vga_hsync,
    output            vga_vsync
);
    localparam [9:0] H_BACK = 48;
    localparam [9:0] H_VISIBLE = 640;
    localparam [9:0] H_FRONT = 16;
    localparam [9:0] H_SYNC = 96;
    localparam [9:0] H_TOTAL = H_BACK + H_VISIBLE + H_FRONT + H_SYNC;

    localparam [9:0] V_BACK = 33;
    localparam [9:0] V_VISIBLE = 480;
    localparam [9:0] V_FRONT = 10;
    localparam [9:0] V_SYNC = 2;
    localparam [9:0] V_TOTAL = V_BACK + V_VISIBLE + V_FRONT + V_SYNC;

    reg [1:0] clkdiv = 0;
    reg [9:0] line = 0;
    reg [9:0] pixel = 0;

    reg [7:0] chr_rom [0:256*16-1];
    initial $readmemh("build/chr_rom.hex", chr_rom);

    reg         index_rd_en = 0;
    reg  [10:0] index_rd_addr = 0;
    wire [7:0]  index_rd_data;

    reg        blit = 0;
    reg [10:0] b_addr = 0;
    reg [10:0] b_end = 0;
    reg [7:0]  b_offset = 0;
    reg        b_wr_en = 0;
    reg [10:0] b_wr_addr = 0;
    reg [7:0]  b_wr_data = 0;

    index_ram r (
        .clk(clk100),
        .wr_en(blit ? b_wr_en : wr_en),
        .wr_addr(blit ? b_wr_addr : wr_addr),
        .wr_data(blit ? b_wr_data : wr_data),
        .rd_en(index_rd_en),
        .rd_addr(index_rd_addr),
        .rd_data(index_rd_data)
    );

    reg [7:0] next_index = 0;
    reg [7:0] next_pat = 0;
    reg [7:0] cur_pat = 0;

    reg [8:0] rgb = 0;

    reg [7:0] addr = 0;

    always @(posedge clk100) begin
        clkdiv <= clkdiv + 1;
        b_wr_en <= 0;
        blit_complete <= 0;

        if (!blit && blit_en) begin
            blit <= 1;
            b_addr <= blit_start;
            b_end <= blit_end;
            b_offset <= blit_offset;
        end

        if (clkdiv == 0) begin
            if (V_BACK - 1 <= line && line < V_BACK + 16 * 25 && H_BACK - 8 <= pixel && pixel < H_BACK + H_VISIBLE) begin
                if (pixel % 8 == 7)
                    cur_pat <= next_pat;
                else
                    cur_pat <= cur_pat >> 1;

                if (pixel % 8 == 0 && !blit) begin
                    index_rd_addr <= (line + 1 - V_BACK) / 16 * 80 + (pixel + 8 - H_BACK) / 8;
                    index_rd_en <= 1;
                end else if (pixel % 8 == 1 && !blit) begin
                    next_index <= index_rd_data - 1;
                    index_rd_en <= 0;
                end else if (pixel % 8 == 2) begin
                    next_pat <= blit ? 0 : chr_rom[next_index * 16 + line % 16];
                end
            end

            if (V_BACK <= line && line < V_BACK + 16 * 25 && H_BACK <= pixel && pixel < H_BACK + H_VISIBLE)
                rgb <= cur_pat[0] != 0 ? 9'b111111111 : 0;
            else
                rgb <= 0;

            pixel <= pixel + 1;
            if (pixel == H_TOTAL) begin
                pixel <= 0;

                line <= line + 1;
                if (line == V_TOTAL) begin
                    line <= 0;
                end
            end
        end else if (blit) begin
            if (b_addr == b_end) begin
                blit <= 0;
                blit_complete <= 1;
            end else if (clkdiv == 1 && b_offset != 0) begin
                index_rd_addr <= b_addr + b_offset + 1;
                index_rd_en <= 1;
            end else if (clkdiv == 2) begin
                b_wr_addr <= b_addr;
                b_wr_data <= b_offset == 0 ? 8'h00 : index_rd_data;
                b_wr_en <= 1;
                b_addr <= b_addr + 1;
                index_rd_en <= 0;
            end
        end
    end

    assign vga_red = rgb[2:0];
    assign vga_green = rgb[5:3];
    assign vga_blue = rgb[8:6];
    assign vga_hsync = !(pixel >= H_TOTAL - H_SYNC);
    assign vga_vsync = !(line >= V_TOTAL - V_SYNC);
endmodule
