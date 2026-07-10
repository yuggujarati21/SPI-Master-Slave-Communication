module spi_top(
    input         clk,      // 50MHz Clock
    input         rst,      // Reset Button
    input         start,    // Start Button (Active Low)
    input  [7:0]  sw,       // Switches

    output [7:0]  slave_rx,
    output        done,

    output [6:0]  HEX0, HEX1, HEX2, HEX3
);

    wire sclk, ss, mosi, miso;
    wire [7:0] master_rx;
    wire clean_start;

    // Re-use your debouncer instance here...
    debouncer #(.COUNTER_MAX(500000)) BTN_DEBOUNCE (
        .clk(clk), .rst(rst), .noisy_btn(start), .clean_pulse(clean_start)
    );

    // SPI Master Instance
    spi_master MASTER (
        .clk(clk), .rst(rst), .start(clean_start), .tx_data(sw),
        .miso(miso), .sclk(sclk), .mosi(mosi), .ss(ss), .rx_data(master_rx), .done(done)
    );

    // SPI Slave Instance (Now with System clk passed in)
    spi_slave SLAVE (
        .clk(clk), // Added to stabilize the asynchronous bus lines
        .rst(rst), .sclk(sclk), .ss(ss), .mosi(mosi), .miso(miso), .rx_data(slave_rx)
    );

    // Hex Displays mapping
    hex_decoder H0 (.bin(slave_rx[3:0]),  .seg(HEX0));
    hex_decoder H1 (.bin(slave_rx[7:4]),  .seg(HEX1));
    hex_decoder H2 (.bin(master_rx[3:0]), .seg(HEX2));
    hex_decoder H3 (.bin(master_rx[7:4]), .seg(HEX3));

endmodule
