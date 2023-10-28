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
    //reg [7:0] us_div = 0;
    //reg [10:0] ms_div = 0;
    //reg [10:0] s_div = 0;

    reg [5:0] wr_row = 0;
    reg [6:0] wr_col = 0;

    wire [7:0] char;
    wire uart_rx_complete;
    reg uart_rx_pending = 0;

    reg        wr_start = 0;
    reg [10:0] wr_begin = 0;
    reg [10:0] wr_end = 0;
    reg [7:0]  wr_data = 0;
    reg [7:0]  wr_offset = 0;
    wire       wr_complete;
    reg wr_busy = 0;

    reg        clear_last = 0;

    reg [15:0] startup_delay = 16'hffff;
    wire startup = (startup_delay == 16'h0001);

    parameter [7:0] CH_NUL = 8'h00;
    parameter [7:0] CH_BEL = 8'h07;
    parameter [7:0] CH_BS = 8'h08;
    parameter [7:0] CH_LF = 8'h0a;
    parameter [7:0] CH_CR = 8'h0d;
    parameter [7:0] CH_ESC = 8'h1b;

    parameter [3:0] STATE_DEFAULT = 0;
    parameter [3:0] STATE_ESC = 1;
    parameter [3:0] STATE_CSI = 2;
    reg [3:0] state = STATE_DEFAULT;

    vga_text_mode mod_vga_text_mode (
        .clk100(clk100),
        .cursor(wr_row * 80 + wr_col),
        .wr_start(wr_start),
        .wr_begin(wr_begin),
        .wr_end(wr_end),
        .wr_data(wr_data),
        .wr_offset(wr_offset),
        .wr_complete(wr_complete),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );

    uart_rx mod_uart_rx (
        .clk100(clk100),
        .rx(uart_rx),
        .rx_data(char),
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
        wr_start <= 0;

        if (wr_start)
            wr_busy <= 1;

        /*us_div <= us_div + 1;
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
        end*/

        if (startup_delay != 0)
            startup_delay <= startup_delay - 1;

        if (uart_rx_complete)
            uart_rx_pending <= 1;

        if (uart_rx_pending && !wr_busy) begin
            uart_rx_pending <= 0;

            case (state)
                STATE_DEFAULT: case (char)
                    CH_NUL: ;
                    CH_BEL: ;
                    CH_LF: wr_row <= wr_row + 1;
                    CH_CR: wr_col <= 0;
                    CH_ESC: state <= STATE_ESC;
                    CH_BS: if (wr_col > 0) wr_col <= wr_col - 1;
                    default: begin
                        wr_col <= wr_col + 1;
                        if (wr_col == 80 - 1) begin
                            wr_col <= 0;
                            wr_row <= wr_row + 1;
                        end

                        wr_begin <= 80 * wr_row + wr_col;
                        wr_end <= 80 * wr_row + wr_col + 1;
                        wr_data <= char;
                        wr_offset <= 0;
                        wr_start <= 1;
                    end
                endcase
                STATE_ESC: begin
                    if (char == "[")
                        state <= STATE_CSI;
                    else
                        state <= STATE_DEFAULT;
                end
                STATE_CSI: begin
                    if (char == "C") begin
                        wr_col <= wr_col + 1;
                    end if (char == "H") begin
                        wr_row <= 0;
                        wr_col <= 0;
                    end else if (char == "J") begin
                        wr_begin <= 0;
                        wr_end <= 25 * 80;
                        wr_offset <= 0;
                        wr_data <= 0;
                        wr_start <= 1;
                    end else if (char == "K") begin
                        wr_begin <= wr_row * 80 + wr_col;
                        wr_end <= wr_row * 80 + 80;
                        wr_offset <= 0;
                        wr_data <= 0;
                        wr_start <= 1;
                    end else if (char == "P") begin
                        wr_begin <= wr_row * 80 + wr_col + 1;
                        wr_end <= wr_row * 80 + wr_col + 2;
                        wr_offset <= 0;
                        wr_data <= 0;
                        wr_start <= 1;
                    end 
                    
                    if (char & 8'h40) begin
                        state <= STATE_DEFAULT;
                    end
                end
            endcase
        end

        if (wr_row == 25) begin
            wr_row <= 24;

            wr_begin <= 0;
            wr_end <= 24 * 80;
            wr_offset <= 81;
            wr_start <= 1;

            clear_last <= 1;
        end

        if (wr_complete) begin
            if (clear_last) begin
                wr_begin <= 24 * 80;
                wr_end <= 25 * 80;
                wr_data <= 0;
                wr_offset <= 0;
                wr_start <= 1;

                clear_last <= 0;
            end else
                wr_busy <= 0;
        end
    end

    //assign led1 = 0;
    //assign led2 = 0;
endmodule
