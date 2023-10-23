module top (
    input        clk100,
    input        uart_rx,
    output       uart_tx,
    input        ps2_clk,
    input        ps2_dat,
    output       led1,
    output       led2,
    output [2:0] vga_red,
    output [2:0] vga_green,
    output [2:0] vga_blue,
    output       vga_hsync,
    output       vga_vsync,
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

    reg [7:0] uart_tx_data;
    reg uart_tx_start;
    wire uart_tx_busy;

    wire [7:0] ps2_rx_data;
    wire ps2_rx_complete;

    reg led = 0;

    vga_text_mode mod_vga_text_mode (
        .clk100(clk100),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
    );

    uart_rx mod_uart_rx (
        .clk100(clk100),
        .rx(uart_rx),
        .rx_data(uart_rx_data),
        .rx_complete(uart_rx_complete),
    );

    uart_tx mod_uart_tx (
        .clk100(clk100),
        .tx(uart_tx),
        .tx_data(uart_tx_data),
        .tx_start(uart_tx_start),
        .tx_busy(uart_tx_busy),
    );

    ps2 ps2_mod (
        .clk100(clk100),
        .clk(ps2_clk),
        .data(ps2_data),
        .rx_data(ps2_rx_data),
        .rx_complete(ps2_rx_complete),
    );

    always @(posedge clk100) begin
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

        uart_tx_start <= 0;

        /*if (ps2_rx_complete) begin
            uart_tx_data <= ps2_rx_data;
            uart_tx_start <= 1;
            led <= !led;
        end else if (uart_tx_start)
            uart_tx_start <= 0;*/

        if (write)
            write <= 0;
        else if (wr_en) begin
            wr_en <= 0;
        end else if (uart_rx_complete) begin
            uart_tx_data <= uart_rx_data;
            uart_tx_start <= 1;

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

            if (wr_row == 25)
                wr_row <= 0;
        end
    end

    assign led1 = led;
    assign led2 = ps2_data;
endmodule
