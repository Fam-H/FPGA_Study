module sw_led_adder_8bit(
    input  [15:0] SW,
    output [15:0] LED
);

    // SW[7:0]  = A (오른쪽 스위치 8개)
    // SW[15:8] = B (왼쪽 스위치 8개)
    // LED[8:0] = A + B (캐리 포함 9비트)
    assign LED[8:0] = SW[7:0] + SW[15:8];

    assign LED[15:9] = 7'b0; // 보드에서 왼쪽 7개 LED를 0으로 세팅해서 OFF
    // 7'b0 -> (7bit)(구분자)(2진수binary)(값)
    
endmodule