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

        #10000

        fork
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
        join

        #1000


        $finish();
    end
endmodule