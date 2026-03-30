module sw_led_sync(
    input        clk,       // 100MHz 시스템 클럭
    input        btnC,      // 센터 버튼 (리셋용)
    input  [15:0] SW,
    output reg [15:0] LED   // reg로 선언 (always 블록에서 대입하니까)
);

    // 순차 논리: 클럭의 상승 엣지마다 실행
    always @(posedge clk) begin
        if (btnC)           // btnC가 눌리면 리셋
            LED <= 16'b0;
        else
            LED <= SW;      // 클럭 엣지에서 SW 값을 LED에 저장
    end

endmodule