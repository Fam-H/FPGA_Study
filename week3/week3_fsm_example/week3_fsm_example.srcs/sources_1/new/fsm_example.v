module fsm_example(
    input  clk,
    input  reset,
    input  coin,        // 동전 투입 신호
    input  select,      // 상품 선택 신호
    output reg vend,    // 상품 배출 신호
    output reg [1:0] state_out  // 현재 상태 확인용
);

    // ─── 1) 상태 정의 ───
    localparam S_IDLE    = 2'b00;  // 대기
    localparam S_COIN    = 2'b01;  // 동전 투입됨
    localparam S_VEND    = 2'b10;  // 상품 배출 중

    reg [1:0] state, next_state;

    // ─── 2) 첫 번째 always: 상태 레지스터 ───
    //     현재 상태를 클럭 엣지에서 갱신
    always @(posedge clk) begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ─── 3) 두 번째 always: 다음 상태 로직 (조합 논리) ───
    //     현재 상태 + 입력 → 다음 상태 결정
    always @(*) begin
        next_state = state;  // 기본값: 현재 상태 유지
        case (state)
            S_IDLE: begin
                if (coin)
                    next_state = S_COIN;
            end
            S_COIN: begin
                if (select)
                    next_state = S_VEND;
            end
            S_VEND: begin
                next_state = S_IDLE;  // 배출 후 자동 복귀
            end
            default: next_state = S_IDLE;
        endcase
    end

    // ─── 4) 세 번째 always: 출력 로직 (조합 논리) ───
    //     현재 상태에 따라 출력 결정
    always @(*) begin
        vend = 1'b0;           // 기본값
        state_out = state;
        case (state)
            S_VEND: vend = 1'b1;  // 배출 상태일 때만 vend 활성화
        endcase
    end

endmodule