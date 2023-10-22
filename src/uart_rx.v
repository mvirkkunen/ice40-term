module uart_rx (
    input            clk100,
    input            rx,
    output reg [8:0] data,
    output reg       complete,
);
    parameter [9:0] BAUD_DIVISOR = 868;

    reg rx_reg = 0;

    reg [9:0] timer = 0;
    reg [7:0] buffer = 0;
    reg [3:0] state = 0;

    always @(posedge clk100) begin
        rx_reg <= rx;

        if (state == 0) begin
            if (!rx_reg) begin
                state <= 1;
                timer <= BAUD_DIVISOR / 2;
            end

            complete <= 0;
        end else if (state == 1) begin
            if (timer == 0) begin
                if (!rx_reg) begin
                    state <= 2;
                    timer <= BAUD_DIVISOR;
                end else
                    state <= 0;
            end else
                timer <= timer - 1;
        end else if (2 <= state && state <= 9) begin
            if (timer == 0) begin
                buffer <= (buffer >> 1) | (rx_reg << 7);
                state <= state + 1;
                timer <= BAUD_DIVISOR;
            end else
                timer <= timer - 1;
        end else if (state == 10) begin
            if (timer == 0) begin
                if (rx_reg) begin
                    data <= buffer;
                    complete <= 1;
                end

                state <= 0;
            end else
                timer <= timer - 1;
        end
    end
endmodule