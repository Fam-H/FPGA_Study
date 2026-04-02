`timescale 1ns / 1ps   // 시간 단위 / 정밀도

module tb_led_blink();

    // 테스트벤치 신호 선언
    reg        clk;
    reg        btnC;
    wire [15:0] LED;

    // DUT (Device Under Test) 인스턴스
    // CNT_MAX를 4로 줄여서 빠르게 시뮬레이션
    led_blink_param #(
        .CNT_MAX(26'd4)
    ) uut (
        .clk(clk),
        .btnC(btnC),
        .LED(LED)
    );

    // 클럭 생성: 10ns 주기 = 100MHz
    initial clk = 0;
    always #5 clk = ~clk;   // 5ns마다 토글 → 10ns 주기

    // 테스트 시나리오
    initial begin
        // 파형 덤프 설정
        $dumpfile("led_blink.vcd");
        $dumpvars(0, tb_led_blink);

        // 리셋
        btnC = 1;
        #100;           // 100ns 동안 리셋 유지
        btnC = 0;

        // 충분한 시간 대기 (카운터가 여러 번 넘칠 때까지)
        #1000;

        $display("Simulation finished");
        $finish;
    end

    // LED 변화 모니터링
    initial begin
        $monitor("Time=%0t  counter=%0d  LED=%b", $time, uut.counter, LED);
    end

endmodule