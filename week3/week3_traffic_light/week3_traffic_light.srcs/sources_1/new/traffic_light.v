// ─── traffic_light.v ───
module traffic_light(
    input  clk,          // 100MHz
    input  reset,        // BTNC
    output reg [15:0] LED,      // 상태 표시용
    output reg [6:0] seg,       // 7세그먼트 세그먼트
    output reg [7:0] an         // 7세그먼트 자릿수 선택
);

    // ========== 상태 정의 ==========
    localparam S_NS_GREEN   = 2'b00;  // 남북 초록 (동서 빨강)
    localparam S_NS_YELLOW  = 2'b01;  // 남북 노랑 (동서 빨강)
    localparam S_EW_GREEN   = 2'b10;  // 동서 초록 (남북 빨강)
    localparam S_EW_YELLOW  = 2'b11;  // 동서 노랑 (남북 빨강)

    reg [1:0] state, next_state;

    // ========== 타이머 ==========
    // 100MHz → 1초 카운터에 100_000_000 필요 → 27비트
    reg [26:0] clk_counter;
    reg [3:0]  sec_counter;    // 남은 초 (0~9)
    wire       tick_1s;        // 1초마다 1클럭 펄스

    assign tick_1s = (clk_counter == 27'd99_999_999);

    always @(posedge clk) begin
        if (reset)
            clk_counter <= 27'd0;
        else if (tick_1s)
            clk_counter <= 27'd0;
        else
            clk_counter <= clk_counter + 1;
    end

    // ========== 초 카운터 ==========
    always @(posedge clk) begin
        if (reset) begin
            sec_counter <= 4'd4;   // 첫 상태(NS_GREEN) 5초 → 4부터 시작 (0도 1초)
        end else if (tick_1s) begin
            if (sec_counter == 4'd0) begin
                // 타이머 만료 → 다음 상태의 시간 로드
                case (state)
                    S_NS_GREEN:  sec_counter <= 4'd1;  // 노랑 2초
                    S_NS_YELLOW: sec_counter <= 4'd4;  // 초록 5초
                    S_EW_GREEN:  sec_counter <= 4'd1;  // 노랑 2초
                    S_EW_YELLOW: sec_counter <= 4'd4;  // 초록 5초
                    default:     sec_counter <= 4'd4;
                endcase
            end else begin
                sec_counter <= sec_counter - 1;
            end
        end
    end

    // ========== 상태 레지스터 ==========
    always @(posedge clk) begin
        if (reset)
            state <= S_NS_GREEN;
        else
            state <= next_state;
    end

    // ========== 다음 상태 로직 ==========
    always @(*) begin
        next_state = state;
        case (state)
            S_NS_GREEN: begin
                if (tick_1s && sec_counter == 4'd0)
                    next_state = S_NS_YELLOW;
            end
            S_NS_YELLOW: begin
                if (tick_1s && sec_counter == 4'd0)
                    next_state = S_EW_GREEN;
            end
            S_EW_GREEN: begin
                if (tick_1s && sec_counter == 4'd0)
                    next_state = S_EW_YELLOW;
            end
            S_EW_YELLOW: begin
                if (tick_1s && sec_counter == 4'd0)
                    next_state = S_NS_GREEN;
            end
            default: next_state = S_NS_GREEN;
        endcase
    end

    // ========== 출력 로직: LED ==========
    // LED[2:0] = 남북 신호 (R, Y, G)
    // LED[6:4] = 동서 신호 (R, Y, G)
    always @(*) begin
        LED = 16'd0;
        case (state)
            S_NS_GREEN: begin
                LED[0] = 1'b1;  // 남북 초록
                LED[6] = 1'b1;  // 동서 빨강
            end
            S_NS_YELLOW: begin
                LED[1] = 1'b1;  // 남북 노랑
                LED[6] = 1'b1;  // 동서 빨강
            end
            S_EW_GREEN: begin
                LED[2] = 1'b1;  // 남북 빨강
                LED[4] = 1'b1;  // 동서 초록
            end
            S_EW_YELLOW: begin
                LED[2] = 1'b1;  // 남북 빨강
                LED[5] = 1'b1;  // 동서 노랑
            end
        endcase
    end

    // ========== 7세그먼트: 남은 초 표시 ==========
    // 1자리만 사용 (AN[0]만 활성화)
    reg [3:0] display_num;

    always @(*) begin
        display_num = sec_counter + 1;  // 0부터 카운트하므로 +1 표시
    end

    // 7세그먼트: sec_counter 값을 표시 (active-low, seg[6]=a ~ seg[0]=g)
    //  aaa
    // f   b
    //  ggg
    // e   c
    //  ddd
    
    always @(*) begin
        an = 8'b11111110;  // AN[0]만 활성화
        case (sec_counter)
            4'd0: seg = 7'b0000001;  // 0: a,b,c,d,e,f ON / g OFF
            4'd1: seg = 7'b1001111;  // 1: b,c ON
            4'd2: seg = 7'b0010010;  // 2: a,b,d,e,g ON
            4'd3: seg = 7'b0000110;  // 3: a,b,c,d,g ON
            4'd4: seg = 7'b1001100;  // 4: b,c,f,g ON
            4'd5: seg = 7'b0100100;  // 5: a,c,d,f,g ON
            4'd6: seg = 7'b0100000;  // 6: a,c,d,e,f,g ON
            4'd7: seg = 7'b0001111;  // 7: a,b,c ON
            4'd8: seg = 7'b0000000;  // 8: 전부 ON
            4'd9: seg = 7'b0000100;  // 9: a,b,c,d,f,g ON
            default: seg = 7'b1111111;  // 모두 끔
        endcase
    end

endmodule