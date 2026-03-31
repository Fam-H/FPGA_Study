module seg7_display(
    input        clk,
    input        btnC,
    input  [15:0] SW,       // 하위 4비트로 숫자 입력
    output reg [6:0] seg,   // 7-segment (CA~CG), active-low
    output reg       dp,    // decimal point, active-low
    output reg [7:0] an     // 자릿수 선택, active-low
);

    // =========================================
    // 1) 스캔 카운터: 8자리를 순서대로 켜기 위한 타이머
    // =========================================
    // 1kHz 스캔 속도 (100MHz / 100,000 = 1kHz)
    // 8자리를 순서대로 돌리면 각 자리는 125Hz로 갱신
    // 사람 눈에는 깜빡임 없이 보임
    localparam SCAN_CNT_MAX = 17'd99_999;

    reg [16:0] scan_counter;
    reg [2:0]  digit_sel;    // 현재 켜는 자릿수 (0~7)

    always @(posedge clk) begin
        if (btnC) begin
            scan_counter <= 17'd0;
            digit_sel    <= 3'd0;
        end
        else if (scan_counter == SCAN_CNT_MAX) begin
            scan_counter <= 17'd0;
            digit_sel    <= digit_sel + 1'b1;  // 3비트라 자동으로 0~7 순환
        end
        else begin
            scan_counter <= scan_counter + 1'b1;
        end
    end

    // =========================================
    // 2) 자릿수별 표시할 데이터 선택
    // =========================================
    reg [3:0] hex_digit;  // 현재 자릿수에 표시할 4비트 값

    always @(*) begin     // 조합 논리이므로 always @(*), blocking(=) 사용
        case (digit_sel)
            3'd0: hex_digit = SW[3:0];    // 1번째 자리
            3'd1: hex_digit = SW[7:4];    // 2번째 자리
            3'd2: hex_digit = SW[11:8];   // 3번째 자리
            3'd3: hex_digit = SW[15:12];  // 4번째 자리
            3'd4: hex_digit = 4'h0;       // 5~8번째는 0 표시
            3'd5: hex_digit = 4'h0;
            3'd6: hex_digit = 4'h0;
            3'd7: hex_digit = 4'h0;
            default: hex_digit = 4'h0;
        endcase
    end

    // =========================================
    // 3) 7-Segment 디코더 (BCD → 세그먼트 패턴)
    // =========================================
    // NEXYS A7은 active-low: 0이면 해당 세그먼트 켜짐
    //   세그먼트 배치:
    //      AAA
    //     F   B
    //      GGG
    //     E   C
    //      DDD   (DP)
    //
    //   seg[6:0] = {CA, CB, CC, CD, CE, CF, CG}
    //            = { A,  B,  C,  D,  E,  F,  G}

    always @(*) begin
        case (hex_digit)
            //                    ABCDEFG
            4'h0: seg = 7'b000_0001;  // 0: A,B,C,D,E,F on
            4'h1: seg = 7'b100_1111;  // 1: B,C on
            4'h2: seg = 7'b001_0010;  // 2: A,B,D,E,G on
            4'h3: seg = 7'b000_0110;  // 3: A,B,C,D,G on
            4'h4: seg = 7'b100_1100;  // 4: B,C,F,G on
            4'h5: seg = 7'b010_0100;  // 5: A,C,D,F,G on
            4'h6: seg = 7'b010_0000;  // 6: A,C,D,E,F,G on
            4'h7: seg = 7'b000_1111;  // 7: A,B,C on
            4'h8: seg = 7'b000_0000;  // 8: 전부 on
            4'h9: seg = 7'b000_0100;  // 9: A,B,C,D,F,G on
            4'hA: seg = 7'b000_1000;  // A
            4'hB: seg = 7'b110_0000;  // b
            4'hC: seg = 7'b011_0001;  // C
            4'hD: seg = 7'b100_0010;  // d
            4'hE: seg = 7'b011_0000;  // E
            4'hF: seg = 7'b011_1000;  // F
            default: seg = 7'b111_1111; // 전부 off
        endcase
    end

    // =========================================
    // 4) 자릿수 활성화 (active-low)
    // =========================================
    always @(*) begin
        an = 8'b1111_1111;          // 전부 끄고
        an[digit_sel] = 1'b0;       // 현재 자릿수만 켜기
    end

    // DP는 항상 off
    always @(*) begin
        dp = 1'b1;
    end

endmodule