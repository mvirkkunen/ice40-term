module uart_tx (
    input       clk100,
    output reg  tx,
    input [7:0] data,
    input       start,
    output      busy,
);
    parameter [9:0] BAUD_DIVISOR = 868;

    reg [7:0] buffer = 0;
    reg [3:0] state = 0;
    reg [9:0] timer = 0;

    initial tx = 1;

    always @(posedge clk100) begin
        if (state == 0) begin
            if (start) begin
                tx <= 0;
                buffer <= data;
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
                state <= 0;
            end else
                timer <= timer - 1;
        end
    end

    assign busy = (state != 0);
endmodule