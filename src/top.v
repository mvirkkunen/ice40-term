module top (
    input        clk100,
    input        uart_rx,
    output       uart_tx,
    input        ps2_clk,
    input        ps2_data,
    output       led1,
    output       led2,
    output [2:0] vga_red,
    output [2:0] vga_green,
    output [2:0] vga_blue,
    output       vga_hsync,
    output       vga_vsync,
    output       spi_sdo,
    input        spi_sdi,
    output       spi_sck,
    output       spi_ss
);
    reg [7:0] us_div = 0;
    reg [10:0] ms_div = 0;
    reg [10:0] s_div = 0;

    reg [5:0] wr_row = 0;
    reg [6:0] wr_col = 0;
    reg wr_en = 0;
    reg [10:0] wr_addr = 0;
    reg [7:0] wr_data = 0;
    reg write = 0;

    wire [7:0] uart_rx_data;
    wire uart_rx_complete;

    reg        blit_en = 0;
    reg [10:0] blit_start = 0;
    reg [10:0] blit_end = 0;
    reg [7:0]  blit_offset = 0;
    wire       blit_complete;

    reg        clear_last = 0;

    reg [15:0] startup_delay = 16'hffff;
    wire startup = (startup_delay == 16'h0001);

    vga_text_mode mod_vga_text_mode (
        .clk100(clk100),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .blit_en(blit_en),
        .blit_start(blit_start),
        .blit_end(blit_end),
        .blit_offset(blit_offset),
        .blit_complete(blit_complete),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );

    uart_rx mod_uart_rx (
        .clk100(clk100),
        .rx(uart_rx),
        .rx_data(uart_rx_data),
        .rx_complete(uart_rx_complete)
    );

    keyboard_transmitter mod_keyboard_transmitter (
        .clk100(clk100),
        .startup(startup),
        .uart_tx(uart_tx),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .spi_sdo(spi_sdo),
        .spi_sdi(spi_sdi),
        .spi_sck(spi_sck),
        .spi_ss(spi_ss),
        .led1(led1),
        .led2(led2)
    );

    always @(posedge clk100) begin
        blit_en <= 0;

        us_div <= us_div + 1;
        if (us_div == 100) begin
            us_div <= 0;
            ms_div <= ms_div + 1;

            if (ms_div == 1000) begin
                ms_div <= 0;
                s_div <= s_div + 1;

                if (s_div == 1000) begin
                    s_div <= 0;
                end
            end
        end

        if (startup_delay != 0)
            startup_delay <= startup_delay - 1;

        if (write)
            write <= 0;
        else if (wr_en) begin
            wr_en <= 0;
        end else if (uart_rx_complete) begin
            if (uart_rx_data == "\n")
                wr_row <= wr_row + 1;
            else if (uart_rx_data == "\r")
                wr_col <= 0;
            else begin
                wr_col <= wr_col + 1;
                if (wr_col == 80) begin
                    wr_col <= 0;
                    wr_row <= wr_row + 1;
                end

                wr_addr <= 80 * wr_row + wr_col;
                wr_data <= uart_rx_data;
                wr_en <= 1;
                write <= 1;
            end
        end

        if (wr_row == 25 && !wr_en) begin
            wr_row <= 24;

            blit_start <= 0;
            blit_end <= 24 * 80;
            blit_offset <= 80;
            blit_en <= 1;

            clear_last <= 1;
        end

        if (clear_last && blit_complete) begin
            clear_last <= 0;

            blit_start <= 24 * 80;
            blit_end <= 25 * 80;
            blit_offset <= 0;
            blit_en <= 1;
        end
    end

    //assign led1 = 0;
    //assign led2 = 0;
endmodule
