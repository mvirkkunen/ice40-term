module uart_tx (
    input       clk100,
    output reg  tx = 1,
    input [7:0] tx_data,
    input       tx_start,
    output      tx_busy,
    output reg  tx_complete
);
    parameter [9:0] BAUD_DIVISOR = 868;

    parameter [3:0] STATE_IDLE     = 0;
    parameter [3:0] STATE_DATA0    = 1;
    parameter [3:0] STATE_DATA7    = 8;
    parameter [3:0] STATE_STOP     = 9;
    parameter [3:0] STATE_END      = 10;
    parameter [3:0] STATE_COMPLETE = 11;

    reg [7:0] buffer = 0;
    reg [3:0] state = STATE_IDLE;
    reg [9:0] timer = 0;

    always @(posedge clk100) begin
        timer <= timer - 1;
        tx_complete <= 0;

        if (state == STATE_IDLE && tx_start) begin
            tx <= 0;
            buffer <= tx_data;
            state <= state + 1;
            timer <= BAUD_DIVISOR;
        end else if (STATE_DATA0 <= state && state <= STATE_DATA7 && timer == 0) begin
            tx <= buffer[0];
            buffer <= buffer >> 1;
            state <= state + 1;
            timer <= BAUD_DIVISOR;
        end else if (state == STATE_STOP && timer == 0) begin
            tx <= 1;
            state <= state + 1;
            timer <= BAUD_DIVISOR;
        end else if (state == STATE_END && timer == 0) begin
            state <= state + 1;
        end else if (state == STATE_COMPLETE && timer == 0) begin
            state <= STATE_IDLE;
            tx_complete <= 1;
        end
    end

    assign tx_busy = (state != STATE_IDLE);
endmodule