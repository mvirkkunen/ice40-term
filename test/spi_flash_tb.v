module spi_flash_tb;
    reg        clk = 0;
    wire       mosi;
    reg        miso = 0;
    wire       sck;
    wire       cs;

    reg  [31:0] cmd = 0;
    reg  [7:0]  cmd_len = 0;
    reg  [7:0]  data_len = 0;
    reg         start = 0;
    wire [63:0] data_out;
    wire        complete;
    wire [7:0]  byte0;

    spi_flash uut (
        .clk100(clk),
        .mosi(mosi),
        .miso(miso),
        .sck(sck),
        .cs(cs),
        .cmd(cmd),
        .cmd_len(cmd_len),
        .data_len(data_len),
        .start(start),
        .data_out(data_out),
        .complete(complete)
    );

    initial clk = 1;
    always #1 clk = !clk;

    initial begin
        $dumpfile("build/test.vcd");
        $dumpvars(0, spi_flash_tb);

        #4;

        cmd <= 32'h030000ff;
        cmd_len <= 32;
        data_len <= 8;

        #1 start <= 1;
        #1 start <= 0;

        #2180;

        miso <= 1;

        #32;

        miso <= 0;

        #2400;

        $finish();
    end

    assign byte0 = data_out[7:0];
endmodule