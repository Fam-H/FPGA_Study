module sw_led_gate(
    input  [15:0] SW,
    output [15:0] LED
);

    assign LED[0] = SW[0] & SW[1];   // AND
    assign LED[1] = SW[0] | SW[1];   // OR
    assign LED[2] = ~SW[0];          // NOT
    assign LED[3] = SW[0] ^ SW[1];   // XOR

    assign LED[15:4] = 12'b0;

    /*
    12'b0은 Verilog의 숫자 표현 방식 
    형식은 비트수'진법_값
    12'b0은 "12비트, 이진수(b), 값 0"이라는 뜻
    12비트 전부 0으로 채워서 LED를 다 꺼둔 것이다. 
    참고로 8'hFF라고 쓰면 "8비트, 16진수(h), 값 FF"가 된다.
    */


endmodule