// ─── uart_tx_top.v ───
module uart_tx_top(
    input        clk,
    input        reset,       // BTNC
    input        btn_send,    // BTNU - 전송 버튼
    input  [7:0] SW,          // 전송할 데이터
    output       tx,          // JA[0] 또는 USB-UART TX
    output       tx_busy_led, // LED[15] - 전송 중 표시
    output [7:0] LED          // LED[7:0] - 현재 스위치 값 표시
);

    // ─── 버튼 디바운싱 + 엣지 검출 ───
    reg [19:0] debounce_cnt;
    reg        btn_stable, btn_prev, btn_pulse;

    always @(posedge clk) begin
        if (reset) begin
            debounce_cnt <= 20'd0;
            btn_stable   <= 1'b0;
            btn_prev     <= 1'b0;
            btn_pulse    <= 1'b0;
        end else begin
            if (btn_send != btn_stable) begin
                debounce_cnt <= debounce_cnt + 1;
                if (debounce_cnt == 20'hFFFFF)
                    btn_stable <= btn_send;
            end else begin
                debounce_cnt <= 20'd0;
            end
            btn_prev  <= btn_stable;
            btn_pulse <= btn_stable & ~btn_prev;  // 상승 엣지
        end
    end

    // ─── UART TX 인스턴스 ───
    wire tx_busy;

    uart_tx u_uart_tx(
        .clk(clk),
        .reset(reset),
        .tx_start(btn_pulse),
        .tx_data(SW),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    assign tx_busy_led = tx_busy;
    assign LED = SW;

endmodule