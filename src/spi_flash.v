module spi_flash (
    input                    clk100,
    output reg               mosi = 0,
    input                    miso,
    output reg               sck = 0,
    output reg               cs = 1,
    input      [31:0]        cmd,
    input      [7:0]         cmd_len,
    input      [7:0]         data_len,
    input                    start,
    output reg [MAX_LEN-1:0] data_out = 0,
    output reg               complete = 0
);
    parameter [7:0] MAX_LEN        = 8 * 8;

    parameter [2:0] STATE_IDLE     = 0;
    parameter [2:0] STATE_CMD      = 1;
    parameter [2:0] STATE_DATA     = 2;
    parameter [2:0] STATE_END      = 3;
    parameter [2:0] STATE_COMPLETE = 4;

    reg [3:0]         bitclk       = 0;
    reg [2:0]         state        = STATE_IDLE;
    reg [7:0]         bits         = 0;
    reg [7:0]         data_len_reg = 0;
    reg [MAX_LEN-1:0] buffer       = 0;
    reg               reg_miso     = 0;

    always @(posedge clk100) begin
        reg_miso <= miso;
        bitclk <= bitclk + 1;
        complete <= 0;

        if (state == STATE_IDLE && start) begin
            bitclk <= 1;
            cs <= 0;
            buffer <= cmd << 1;
            mosi <= cmd[31];
            bits <= cmd_len - 1;
            data_len_reg <= data_len;
            state <= STATE_CMD;
        end

        if (bitclk == 0) begin
            case (state)
                STATE_CMD: begin
                    if (sck) begin
                        buffer <= buffer << 1;
                        mosi <= buffer[31];
                        sck <= 0;

                        if (bits == 0) begin
                            if (data_len_reg == 0) begin
                                mosi <= 0;
                                state <= STATE_END;
                            end else begin
                                buffer <= {MAX_LEN{1'b0}};
                                bits <= data_len_reg;
                                state <= STATE_DATA;
                            end
                        end else
                            bits <= bits - 1;
                    end else if (!sck) begin
                        sck <= 1;
                    end
                end
                STATE_DATA: begin
                    if (bits == 0) begin
                        mosi <= 0;
                        state <= STATE_END;
                    end else if (sck) begin
                        bits <= bits - 1;
                        sck <= 0;
                    end else if (!sck) begin
                        buffer <= (buffer << 1) | reg_miso;
                        sck <= 1;
                    end
                end
                STATE_END: begin
                    cs <= 1;
                    state <= STATE_COMPLETE;
                end
                STATE_COMPLETE: begin
                    data_out <= {
                        buffer[7:0],
                        buffer[15:8],
                        buffer[31:16],
                        buffer[39:32],
                        buffer[47:40],
                        buffer[55:48],
                        buffer[63:56]
                    }; // lol
                    complete <= 1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule