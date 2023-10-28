module top_tb;
    reg  clk = 0;
    wire spi_sdo;
    wire spi_sck;
    wire spi_cc;
    reg uart_rx = 1;
    reg ps2_clk = 1;
    reg ps2_data = 1;

    top uut (
        .clk100(clk),
        .uart_rx(uart_rx),
        //.uart_tx(),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        //.led1(),
        //.led2(),
        //.vga_red(),
        //.vga_green(),
        //.vga_blue(),
        //.vga_hsync(),
        //.vga_vsync(),
        //.spi_sdo(),
        .spi_sdi(1'b0)
        //.spi_sck(),
        //.spi_ss()
    );

    initial clk = 1;
    always #1 clk = !clk;

    initial begin
        $dumpfile("build/test.vcd");
        $dumpvars(0, top_tb);

        #1000

        /*fork
            repeat (20) begin
                #(2*866) uart_rx <= 0;
                #(2*866) uart_rx <= 0;
                #(2*866) uart_rx <= 1;
                #(2*866) uart_rx <= 1;
                #(2*866) uart_rx <= 1;
                #(2*866) uart_rx <= 0;
                #(2*866) uart_rx <= 0;
                #(2*866) uart_rx <= 0;
                #(2*866) uart_rx <= 0;
                #(2*866) uart_rx <= 1;
            end

            repeat (20) begin
                #100 ps2_clk <= 1; ps2_data <= 0; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 1; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 0; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 1; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 0; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 1; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 0; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 0; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 0; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 0; #100 ps2_clk <= 0;
                #100 ps2_clk <= 1; ps2_data <= 1; #100 ps2_clk <= 0;
                #10000;
            end
        join*/

        repeat (20) begin
            #1

            uut.wr_start <= 1;
            uut.wr_begin <= 0;
            uut.wr_end <= 24 * 80;
            uut.wr_data <= 0;
            uut.wr_offset <= 80;

            #1

            uut.wr_start <= 0;

            #20;
        end

        #20000


        $finish();
    end
endmodule