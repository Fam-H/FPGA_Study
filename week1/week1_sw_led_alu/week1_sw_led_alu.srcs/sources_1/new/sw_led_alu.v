module sw_led_alu(
    input  [15:0] SW,
    output [15:0] LED
);

    // SW[3:0]  = A (첫 번째 숫자, 4비트)
    // SW[7:4]  = B (두 번째 숫자, 4비트)
    // SW[9:8]  = 연산 선택
    //   00 = A + B (덧셈)
    //   01 = A - B (뺄셈)
    //   10 = A & B (AND)
    //   11 = A ^ B (XOR)

    reg [7:0] result;
    /*
    reg : register. always 블록 안에서 값을 할당할 수 있는 신호 타입. 반드시 레지스터가 되는 것은 아님.
    [7:0] : 8bit
    result : 이 신호의 이름. 자유롭게 변경할 수 있다.
    전체 의미 : 8bit짜리 신호 result를 선언하고, 이 신호는 always 블록 안에서 값을 할당할 수 있다.
    */
    

    always @(*) begin
        case (SW[9:8])
            2'b00 : result = SW[3:0] + SW[7:4];
            2'b01 : result = SW[3:0] - SW[7:4];
            2'b10 : result = SW[3:0] & SW[7:4];
            2'b11 : result = SW[3:0] ^ SW[7:4];
        endcase
    end

    assign LED[7:0]  = result;
    assign LED[15:8] = 8'b0;

endmodule