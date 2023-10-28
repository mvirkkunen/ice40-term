module spi (
    input            clk100,
    output reg       mosi = 0,
    input            miso,
    output reg       sck = 0,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    input            start,
    output reg       complete = 0
);
    reg [2:0] bitclk   = 0;
    reg [3:0] bits     = 0;
    reg [7:0] buffer   = 0;
    reg       reg_miso = 0;

    assign rx_data = buffer;

    always @(posedge clk100) begin
        reg_miso <= miso;
        bitclk <= bitclk + 1;
        complete <= 0;

        if (bits == 0 && start) begin
            bitclk <= 1;
            mosi <= tx_data[7];
            buffer <= tx_data;
            bits <= 9;
        end

        if (bitclk == 0 && bits != 0) begin
            if (bits == 1) begin
                complete <= 1;
                bits <= 0;
            end else if (sck) begin
                mosi <= buffer[7];
                sck <= 0;

                bits <= bits - 1;
            end else begin
                sck <= 1;
                buffer <= {buffer[6:0], reg_miso};
            end
        end
    end
endmodule