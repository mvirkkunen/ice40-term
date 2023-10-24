module uart_tx (
    input       clk100,
    output reg  tx = 1,
    input [7:0] tx_data,
    input       tx_start,
    output      tx_busy,
    output      tx_complete
);
    parameter [9:0] BAUD_DIVISOR = 868;

    reg [7:0] buffer = 0;
    reg [3:0] state = 0;
    reg [9:0] timer = 0;

    always @(posedge clk100) begin
        if (state == 0) begin
            if (tx_start) begin
                tx <= 0;
                buffer <= tx_data;
                state <= 1;
                timer <= BAUD_DIVISOR;
            end
        end else if (1 <= state && state <= 8) begin
            if (timer == 0) begin
                tx <= buffer[0];
                buffer <= buffer >> 1;
                state <= state + 1;
                timer <= BAUD_DIVISOR;
            end else
                timer <= timer - 1;
        end else if (state == 9) begin
            if (timer == 0) begin
                tx <= 1;
                state <= 10;
                timer <= BAUD_DIVISOR;
            end else
                timer <= timer - 1;
        end else if (state == 10) begin
            if (timer == 0) begin
                state <= 11;
            end else
                timer <= timer - 1;
        end else if (state == 11) begin
            state <= 0;
        end
    end

    assign tx_busy = (state != 0);
    assign tx_complete = (state == 11);
endmodule