module debouncer (
    input  clk,
    input  rst,
    input  noisy_btn,
    output reg clean_pulse
);
    parameter COUNTER_MAX = 500000; 

    reg [18:0] count;
    reg btn_state;
    reg btn_sync_0, btn_sync_1;

    always @(posedge clk) begin
        btn_sync_0 <= noisy_btn;
        btn_sync_1 <= btn_sync_0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count       <= 0;
            btn_state   <= 1'b1; 
            clean_pulse <= 0;
        end else begin
            clean_pulse <= 0; 
            
            if (btn_sync_1 != btn_state) begin
                count <= count + 1;
                if (count == COUNTER_MAX) begin
                    btn_state <= btn_sync_1;
                    count     <= 0;
                    if (btn_state == 1'b1 && btn_sync_1 == 1'b0) begin
                        clean_pulse <= 1'b1;
                    end
                end
            end else begin
                count <= 0;
            end
        end
    end
endmodule
