module ps2 (
    input            clk100,
    input            clk,
    input            data,
    output reg [7:0] rx_data = 0,
    output reg       rx_complete = 0,
);
    parameter [9:0] BAUD_DIVISOR = 868;

    reg clk_reg = 1;
    reg data_reg = 1;

    reg [7:0] buffer = 0;
    reg [3:0] state = 0;

    always @(posedge clk100) begin
        clk_reg <= clk;
        data_reg <= data;
        rx_complete <= 0;
    end

    always @(negedge clk_reg) begin
        complete <= 1;

        if (state == 0) begin
            if (!data_reg)
                state <= 1;
        end else if (1 <= state && state <= 8) begin
            buffer <= (buffer >> 1) | (data_reg[0] << 7);
            state <= state + 1;
        end else if (state == 9) begin
            state <= 10;
        end else if (state == 10) begin
            if (data_reg) begin
                rx_data <= buffer;
                rx_complete <= 1;
            end

            state <= 0;
        end
    end
endmodule