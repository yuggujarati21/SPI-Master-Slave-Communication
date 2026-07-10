module spi_master (
    input            clk,
    input            rst,
    input            start,
    input      [7:0] tx_data,
    input            miso,

    output reg       sclk,
    output reg       mosi,
    output reg       ss,
    output reg [7:0] rx_data,
    output reg       done
);

    parameter DIV = 250; 
    parameter BLINK_DURATION = 5000000; 

    reg [7:0]  clk_div;
    reg [7:0]  tx_shift;
    reg [7:0]  rx_shift;
    reg [2:0]  bit_cnt;
    reg        transfer;
    reg        sclk_track;
    
    reg [22:0] blink_timer; 

    wire clk_tick = (clk_div == DIV-1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div     <= 0;
            sclk        <= 0;
            sclk_track  <= 0;
            ss          <= 1;
            mosi        <= 0;
            transfer    <= 0;
            bit_cnt     <= 0;
            tx_shift    <= 0;
            rx_shift    <= 0;
            rx_data     <= 0;
            done        <= 0;
            blink_timer <= 0;
        end 
        else begin
            // LED Blink Timer Logic
            if (done) begin
                if (blink_timer >= BLINK_DURATION) begin
                    done        <= 0; 
                    blink_timer <= 0;
                end else begin
                    blink_timer <= blink_timer + 1;
                end
            end

            if (!transfer) begin
                sclk    <= 0;
                clk_div <= 0;
                if (start) begin
                    transfer   <= 1;
                    ss         <= 0;
                    tx_shift   <= tx_data;
                    bit_cnt    <= 3'd7;
                    mosi       <= tx_data[7]; 
                    sclk_track <= 0;
                end
            end 
            else begin 
                if (clk_tick) begin
                    clk_div    <= 0;
                    sclk_track <= ~sclk_track;
                    sclk       <= ~sclk_track; 

                    // Rising edge of SCLK: Master changes state to High
                    if (sclk_track == 0) begin 
                        // We do not sample immediately here anymore to avoid the 1-bit latency bug
                    end
                    // Falling edge of SCLK: Sample incoming MISO *FIRST*, then shift out next MOSI bit
                    else begin 
                        // FIXED: Sample MISO right here before the line changes!
                        rx_shift[bit_cnt] <= miso;

                        if (bit_cnt == 0) begin
                            ss          <= 1;
                            transfer    <= 0;
                            done        <= 1; 
                            blink_timer <= 0; 
                            // Capture the full byte including the final sampled bit
                            rx_data     <= {rx_shift[7:1], miso}; 
                        end else begin
                            bit_cnt  <= bit_cnt - 1;
                            tx_shift <= {tx_shift[6:0], 1'b0};
                            mosi     <= tx_shift[6];
                        end
                    end
                end 
                else begin
                    clk_div <= clk_div + 1;
                end
            end
        end
    end
endmodule
