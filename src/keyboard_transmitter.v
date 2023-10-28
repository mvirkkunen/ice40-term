module keyboard_transmitter (
    input  clk100,
    input  startup,
    output uart_tx,
    input  ps2_clk,
    input  ps2_data,
    output spi_sdo,
    input  spi_sdi,
    output spi_sck,
    output reg spi_ss = 1,
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

    reg  [31:0] spi_tx_data = 0;
    reg  [3:0]  spi_tx_len = 0;
    wire [7:0]  spi_rx_data;
    reg         spi_start = 0;
    wire        spi_complete;

    reg [7:0]   uart_tx_data = 0;
    reg         uart_tx_start = 0;
    wire        uart_tx_complete;

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

    spi spi_mod (
        .clk100(clk100),
        .mosi(spi_sdo),
        .miso(spi_sdi),
        .sck(spi_sck),
        .tx_data(spi_tx_data[31:24]),
        .rx_data(spi_rx_data),
        .start(spi_start),
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
        e0 ? 5 * 8 * 8'h80
            : ctrl ? 4 * 8 * 8'h80
            : (altgr && shift) ? 3 * 8 * 8'h80
            : altgr ? 2 * 8 * 8'h80
            : shift ? 1 * 8 * 8'h80
            : 0
    );

    always @(posedge clk100) begin
        uart_tx_start <= 0;
        spi_start <= 0;

        led1 <= shift;
        led2 <= e0;

        if (startup) begin
            spi_tx_data <= 32'hab000000;
            spi_tx_len <= 1;
            spi_start <= 1;
            spi_ss <= 0;
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
                        spi_tx_data <= 32'h03008000 | scancode_table_offset | (char << 3);
                        spi_tx_len = 4;
                        spi_ss <= 0;
                        spi_start <= 1;
                    end
                endcase

                e0 <= 0;
                break <= 0;
            end
        end

        if (spi_complete) begin
            if (spi_tx_len != 0) begin
                spi_tx_data <= spi_tx_data << 8;
                spi_tx_len <= spi_tx_len - 1;
                spi_start <= 1;
            end else if (spi_rx_data != 8'hff && spi_rx_data != 8'h00) begin
                uart_tx_data <= spi_rx_data[7:0];
                uart_tx_start <= 1;
            end else
                spi_ss <= 1;
        end

        if (uart_tx_complete) begin
            led1 <= !led1;
        end

        if (uart_tx_complete) begin
            spi_start <= 1;
        end
    end
endmodule