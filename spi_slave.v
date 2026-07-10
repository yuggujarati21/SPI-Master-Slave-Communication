module spi_slave(
    input            clk,      
    input            rst,
    input            sclk,
    input            ss,
    input            mosi,

    output reg       miso,
    output reg [7:0] rx_data
);

    reg [7:0] tx_data = 8'h5a; 
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;
    reg [2:0] bit_cnt;

    reg [2:0] sclk_sync;
    reg [1:0] ss_sync;
    reg [1:0] mosi_sync;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_sync <= 3'b000;
            ss_sync   <= 2'b11;
            mosi_sync <= 2'b00;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            ss_sync   <= {ss_sync[0], ss};
            mosi_sync <= {mosi_sync[0], mosi};
        end
    end

    wire sclk_rising  = (sclk_sync[1:0] == 2'b01);
    wire sclk_falling = (sclk_sync[1:0] == 2'b10);
    wire ss_active    = ~ss_sync[1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_shift <= 0;
            rx_data  <= 0;
            bit_cnt  <= 3'd7;
            tx_shift <= 8'h5a;
            miso     <= 0;
        end 
        else if (!ss_active) begin
            bit_cnt  <= 3'd7;
            tx_shift <= tx_data;
            miso     <= tx_data[7]; // Ready out out-of-the-gate
        end 
        else begin
            // SPI Mode 0: Sample MOSI on Rising Edge
            if (sclk_rising) begin
                rx_shift[bit_cnt] <= mosi_sync[1];
                if (bit_cnt == 0) begin
                    rx_data <= {rx_shift[7:1], mosi_sync[1]};
                end else begin
                    bit_cnt <= bit_cnt - 1;
                end
            end

            // SPI Mode 0: Shift out MISO on Falling Edge
            if (sclk_falling) begin
                miso     <= tx_shift[6];
                tx_shift <= {tx_shift[6:0], 1'b0};
            end
        end
    end
endmodule
