module spi_tb;
    reg        clk = 0;
    wire       mosi;
    reg        miso = 0;
    wire       sck;
    //wire       cs;

    reg  [7:0] tx_data = 0;
    reg        start = 0;
    wire [7:0] rx_data;
    wire       complete;

    spi uut (
        .clk100(clk),
        .mosi(mosi),
        .miso(miso),
        .sck(sck),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .start(start),
        .complete(complete)
    );

    initial clk = 1;
    always #1 clk = !clk;

    initial begin
        $dumpfile("build/test.vcd");
        $dumpvars(0, spi_tb);

        #20;

        tx_data <= 8'h8f;

        #1 start <= 1;
        #1 start <= 0;

        #2180;

        miso <= 1;

        #32;

        miso <= 0;

        #2400;

        $finish();
    end
endmodule