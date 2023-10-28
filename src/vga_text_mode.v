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
    input      [10:0] cursor,
    input             wr_start,
    input      [10:0] wr_begin,
    input      [10:0] wr_end,
    input      [7:0]  wr_data,
    input      [7:0]  wr_offset,
    output     reg    wr_complete,
    output     [2:0]  vga_red,
    output     [2:0]  vga_green,
    output     [2:0]  vga_blue,
    output            vga_hsync,
    output            vga_vsync
);
    localparam [1:0] S_VISIBLE = 0;
    localparam [1:0] S_FRONT = 1;
    localparam [1:0] S_SYNC = 2;
    localparam [1:0] S_BACK = 3;

    localparam [9:0] H_VISIBLE = 640 + 8;
    localparam [9:0] H_FRONT = 16;
    localparam [9:0] H_SYNC = 96;
    localparam [9:0] H_BACK = 48 - 8;

    localparam [9:0] V_VISIBLE = 480 - 80;
    localparam [9:0] V_FRONT = 10 + 80;
    localparam [9:0] V_SYNC = 2;
    localparam [9:0] V_BACK = 33;

    reg [1:0] clkdiv = 0;
    reg [1:0] h_state = S_VISIBLE;
    reg [1:0] v_state = S_VISIBLE;
    reg [9:0] line = 0;
    reg [9:0] pixel = 0;

    reg [7:0] chr_rom [0:256*16-1];
    initial $readmemh("build/chr_rom.hex", chr_rom);

    reg  [10:0] index_rd_addr = 0;
    wire [7:0]  index_rd_data;

    reg         index_wr_start_reg = 0;
    reg         index_wr_busy = 0;
    reg         index_wr_en = 0;
    reg [10:0]  index_wr_addr = 0;
    reg [10:0]  index_wr_end = 0;
    reg [7:0]   index_wr_data = 0;
    reg [7:0]   index_wr_offset = 0;

    index_ram r (
        .clk(clk100),
        .wr_en(index_wr_en),
        .wr_addr(index_wr_addr),
        .wr_data(index_wr_data),
        .rd_en(1),
        .rd_addr(index_rd_addr),
        .rd_data(index_rd_data)
    );

    wire [10:0] cur_addr = (line / 16 * 80) + (pixel / 8);
    wire [8:0] fg = (cur_addr - 1 == cursor) ? 0 : 9'b111111111;
    wire [8:0] bg = (cur_addr - 1 == cursor) ? 9'b111111111 : 0;
    reg [7:0] next_pat = 0;
    reg [7:0] cur_pat = 0;

    reg [8:0] rgb = 0;

    reg [7:0] addr = 0;

    always @(posedge clk100) begin
        clkdiv <= clkdiv + 1;
        index_wr_en <= 0;
        wr_complete <= 0;

        if (!index_wr_busy && wr_start) begin
            index_wr_start_reg <= 1;
            index_wr_addr <= wr_begin;
            index_wr_end <= wr_end;
            index_wr_data <= wr_data;
            index_wr_offset <= wr_offset;
        end

        if (clkdiv == 0) begin
            if (pixel % 8 == 7)
                cur_pat <= next_pat;
            else
                cur_pat <= cur_pat >> 1;

            if (pixel % 8 == 0 && !index_wr_busy)
                index_rd_addr <= cur_addr;
            else if (pixel % 8 == 1)
                next_pat <= chr_rom[(index_rd_data) * 16 + line % 16];

            if (h_state == S_VISIBLE && v_state == S_VISIBLE && pixel >= 8)
                rgb <= cur_pat[0] ? fg : bg;
            else
                rgb <= 0;

            pixel <= pixel + 1;
            if ((h_state == S_VISIBLE && pixel == H_VISIBLE - 1)
                || (h_state == S_FRONT && pixel == H_FRONT - 1)
                || (h_state == S_SYNC && pixel == H_SYNC - 1)
                || (h_state == S_BACK && pixel == H_BACK - 1))
            begin
                pixel <= 0;
                h_state <= h_state + 1;

                if (h_state == S_BACK)
                    line <= line + 1;
            end

            if ((v_state == S_VISIBLE && line == V_VISIBLE - 1)
                || (v_state == S_FRONT && line == V_FRONT - 1)
                || (v_state == S_SYNC && line == V_SYNC - 1)
                || (v_state == S_BACK && line == V_BACK - 1))
            begin
                line <= 0;
                v_state <= v_state + 1;
            end

            if (index_wr_start_reg) begin
                index_wr_busy <= 1;
                index_wr_start_reg <= 0;
            end
        end
        
        if (pixel % 8 >= 2 && index_wr_busy) begin
            if (index_wr_addr == index_wr_end) begin
                index_wr_busy <= 0;
                wr_complete <= 1;
            end else if (clkdiv == 1) begin
                index_rd_addr <= index_wr_addr + index_wr_offset;
            end else if (clkdiv == 2) begin
                if (index_wr_offset != 0) begin
                    index_wr_data <= index_rd_data;
                end
                index_wr_en <= 1;
            end else if (clkdiv == 3)
                index_wr_addr <= index_wr_addr + 1;
        end
    end

    assign vga_red = rgb[2:0];
    assign vga_green = rgb[5:3];
    assign vga_blue = rgb[8:6];
    assign vga_hsync = !(h_state == S_SYNC);
    assign vga_vsync = !(v_state == S_SYNC);
endmodule
