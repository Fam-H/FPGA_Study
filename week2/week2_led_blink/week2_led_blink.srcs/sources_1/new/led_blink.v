module led_blink(
    input  clk,
    input  btnC,        // 리셋
    output reg [15:0] LED
);

    // 50,000,000 - 1 = 49,999,999
    // 0부터 세기 때문에 -1
    localparam CNT_MAX = 26'd49_999_999;

    reg [25:0] counter;  // 26비트 카운터

    always @(posedge clk) begin
        if (btnC) begin
            counter <= 26'd0;
            LED     <= 16'b0;
        end
        else if (counter == CNT_MAX) begin
            counter <= 26'd0;
            LED     <= ~LED;    // 전체 LED 토글
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

endmodule