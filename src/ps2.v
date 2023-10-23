module ps2 (
    input            clk100,
    input            ps2_clk,
    input            ps2_dat,
    output reg [7:0] data = 0,
    output reg       complete = 0,
);
    parameter [9:0] BAUD_DIVISOR = 868;

    reg clk_reg = 1;
    reg dat_reg = 1;

    reg [7:0] buffer = 0;
    reg [3:0] state = 0;

    always @(posedge clk100) begin
        clk_reg <= ps2_clk;
        dat_reg <= ps2_dat;
        //complete <= 0;
    end

    always @(negedge clk_reg) begin
        complete <= 1;

        if (state == 0) begin
            if (!dat_reg)
                state <= 1;
        end else if (1 <= state && state <= 8) begin
            buffer <= (buffer >> 1) | (dat_reg[0] << 7);
            state <= state + 1;
        end else if (state == 9) begin
            state <= 10;
        end else if (state == 10) begin
            if (dat_reg) begin
                data <= buffer;
                complete <= 1;
            end

            state <= 0;
        end
    end
endmodule