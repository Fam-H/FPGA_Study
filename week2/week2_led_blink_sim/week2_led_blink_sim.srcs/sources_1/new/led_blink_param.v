module led_blink_param #(
    parameter CNT_MAX = 26'd49_999_999   // 기본값: 1초
)(
    input  clk,
    input  btnC,
    output reg [15:0] LED
);

    reg [25:0] counter;

    always @(posedge clk) begin
        if (btnC) begin
            counter <= 26'd0;
            LED     <= 16'b0;
        end
        else if (counter == CNT_MAX) begin
            counter <= 26'd0;
            LED     <= ~LED;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

endmodule