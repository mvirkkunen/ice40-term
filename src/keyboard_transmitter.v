module keyboard_transmitter (
    input  clk100,
    input  startup,
    output uart_tx,
    input  ps2_clk,
    input  ps2_data,
    output spi_sdo,
    input  spi_sdi,
    output spi_sck,
    output spi_ss,
    output reg led1 = 0,
    output reg led2 = 0
);
    parameter [7:0] KEY_LSHIFT = 8'h12;
    parameter [7:0] KEY_RSHIFT = 8'h59;
    parameter [7:0] KEY_ALT = 8'h11;
    parameter [7:0] KEY_E0_ALTGR = 8'h11;
    parameter [7:0] KEY_LCTRL = 8'h14;
    parameter [7:0] KEY_E0_RCTRL = 8'h14;

    wire [7:0]  char;
    wire        ps2_rx_complete;

    reg [31:0]  spi_cmd = 0;
    reg [7:0]   spi_cmd_len = 0;
    reg [7:0]   spi_data_len = 0;
    reg         spi_start = 0;
    wire [63:0] spi_data_out;
    wire        spi_complete;

    reg [7:0]   uart_tx_data = 0;
    reg         uart_tx_start = 0;
    wire        uart_tx_complete;

    reg [63:0]  tx_buf;

    reg         break = 0;
    reg         e0 = 0;
    reg         shift = 0;
    reg         altgr = 0;
    reg         ctrl = 0;

    ps2 mod_ps2 (
        .clk100(clk100),
        .clk(ps2_clk),
        .data(ps2_data),
        .rx_data(char),
        .rx_complete(ps2_rx_complete)
    );

    spi_flash mod_spi_flash (
        .clk100(clk100),
        .mosi(spi_sdo),
        .miso(spi_sdi),
        .sck(spi_sck),
        .cs(spi_ss),
        .cmd(spi_cmd),
        .cmd_len(spi_cmd_len),
        .data_len(spi_data_len),
        .start(spi_start),
        .data_out(spi_data_out),
        .complete(spi_complete)
    );

    uart_tx mod_uart_tx (
        .clk100(clk100),
        .tx(uart_tx),
        .tx_data(uart_tx_data),
        .tx_start(uart_tx_start),
        .tx_complete(uart_tx_complete)
    );

    wire [23:0] scancode_table_offset;
    assign scancode_table_offset = (
        32'h00008000
        | (e0 ? 5 * 8 * 8'h80
            : ctrl ? 4 * 8 * 8'h80
            : (altgr && shift) ? 3 * 8 * 8'h80
            : altgr ? 2 * 8 * 8'h80
            : shift ? 1 * 8 * 8'h80
            : 0
        )
    );

    always @(posedge clk100) begin
        uart_tx_start <= 0;
        spi_start <= 0;

        led1 <= shift;
        led2 <= e0;

        if (startup) begin
            spi_cmd <= 32'hab000000;
            spi_cmd_len <= 8;
            spi_data_len <= 0;
            spi_start <= 1;
        end

        if (ps2_rx_complete) begin
            if (char == 8'he0)
                e0 <= 1;
            else if (char == 8'hf0)
                break <= 1;
            else begin
                case (char)
                    KEY_LSHIFT, KEY_RSHIFT: shift <= !break;
                    KEY_LCTRL: ctrl <= !break;
                    KEY_ALT: if (e0) altgr <= !break;
                    default: if (!break) begin
                        spi_cmd <= 32'h03008000 | scancode_table_offset | (char << 3);
                        spi_cmd_len <= 32;
                        spi_data_len <= 64;
                        spi_start <= 1;
                    end
                endcase

                e0 <= 0;
                break <= 0;
            end
        end

        if (spi_complete && spi_data_out[7:0] != 8'hff) begin
            uart_tx_data <= spi_data_out[7:0];
            uart_tx_start <= 1;
            tx_buf <= spi_data_out >> 8;
        end

        if (uart_tx_complete) begin
            led1 <= !led1;
        end

        if (uart_tx_complete && tx_buf[7:0] != 8'hff) begin
            uart_tx_data <= tx_buf[7:0];
            uart_tx_start <= 1;
            tx_buf <= tx_buf >> 8;
        end
    end
endmodule