module ps2 (
    input            clk100,
    input            clk,
    input            data,
    output reg [7:0] rx_data = 0,
    output reg       rx_complete = 0
);
    parameter [3:0] STATE_IDLE = 0;
    parameter [3:0] STATE_DATA0 = 1;
    parameter [3:0] STATE_DATA7 = 8;
    parameter [3:0] STATE_PARITY = 9;
    parameter [3:0] STATE_STOP = 10;

    reg [3:0] clk_reg   = 4'b1111;
    reg       data_reg  = 1;

    reg [7:0] buffer    = 0;
    reg [3:0] state     = 0;

    always @(posedge clk100) begin
        clk_reg <= {clk_reg[2:0], clk};
        data_reg <= data;
        rx_complete <= 0;

        if (clk_reg == 4'b1100) begin
            if (state == STATE_IDLE) begin
                if (!data_reg) begin
                    state <= 1;
                end
            end else if (STATE_DATA0 <= state && state <= STATE_DATA7) begin
                buffer <= {data_reg, buffer[7:1]};
                state <= state + 1;
            end else if (state == STATE_PARITY) begin
                state <= STATE_STOP;
            end else if (state == STATE_STOP) begin
                if (data_reg) begin
                    rx_data <= buffer;
                    rx_complete <= 1;
                end

                state <= STATE_IDLE;
            end
        end
    end
endmodule