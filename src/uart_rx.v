module uart_rx (
    input            clk100,
    input            rx,
    output reg [7:0] rx_data = 0,
    output reg       rx_complete = 0
);
    parameter [9:0] BAUD_DIVISOR = 868;

    parameter [3:0] STATE_IDLE     = 0;
    parameter [3:0] STATE_START    = 1;
    parameter [3:0] STATE_DATA0    = 2;
    parameter [3:0] STATE_DATA7    = 9;
    parameter [3:0] STATE_STOP     = 10;

    reg rx_reg = 0;

    reg [7:0] buffer = 0;
    reg [3:0] state = STATE_IDLE;
    reg [9:0] timer = 0;

    always @(posedge clk100) begin
        rx_reg <= rx;
        timer <= timer - 1;
        rx_complete <= 0;

        if (state == STATE_IDLE && !rx_reg) begin
            state <= state + 1;
            timer <= BAUD_DIVISOR / 2;
        end else if (state == STATE_START && timer == 0) begin
            if (!rx_reg) begin
                state <= state + 1;
                timer <= BAUD_DIVISOR;
            end else
                state <= STATE_IDLE;
        end else if (STATE_DATA0 <= state && state <= STATE_DATA7 && timer == 0) begin
            buffer <= (buffer >> 1) | (rx_reg << 7);
            state <= state + 1;
            timer <= BAUD_DIVISOR;
        end else if (state == STATE_STOP && timer == 0) begin
            if (rx_reg) begin
                rx_data <= buffer;
                rx_complete <= 1;
            end

            state <= STATE_IDLE;
        end
    end
endmodule