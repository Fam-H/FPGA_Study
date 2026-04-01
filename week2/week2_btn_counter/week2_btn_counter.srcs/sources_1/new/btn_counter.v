module btn_counter(
    input        clk,
    input        btnC,      // 리셋
    input        btnU,      // 카운트 업 버튼
    input        btnD,      // 카운트 다운 버튼
    output reg [6:0] seg,
    output reg       dp,
    output reg [7:0] an
);

    // =========================================
    // 1) 디바운서 (btnU용)
    // =========================================
    // 10ms 대기: 100MHz × 0.01s = 1,000,000 클럭
    localparam DEBOUNCE_MAX = 20'd999_999;

    reg [19:0] db_counter_u;
    reg        btn_u_stable;    // 디바운스된 안정 상태
    reg        btn_u_prev;      // 이전 안정 상태 (엣지 검출용)
    wire       btn_u_pressed;   // 상승 엣지 = "방금 눌림"

    always @(posedge clk) begin
        if (btnC) begin
            db_counter_u <= 20'd0;
            btn_u_stable <= 1'b0;
            btn_u_prev   <= 1'b0;
        end
        else begin
            btn_u_prev <= btn_u_stable;

            if (btnU != btn_u_stable) begin
                // 현재 입력이 안정 상태와 다르면 카운터 시작
                if (db_counter_u == DEBOUNCE_MAX) begin
                    btn_u_stable <= btnU;       // 충분히 기다렸으면 상태 업데이트
                    db_counter_u <= 20'd0;
                end
                else begin
                    db_counter_u <= db_counter_u + 1'b1;
                end
            end
            else begin
                db_counter_u <= 20'd0;  // 입력이 안정 상태와 같으면 카운터 리셋
            end
        end
    end

    // 상승 엣지 검출: 이전에 0이었고 지금 1이면 = 방금 눌림
    assign btn_u_pressed = (btn_u_stable & ~btn_u_prev);

    // =========================================
    // 2) 디바운서 (btnD용) - 동일 구조
    // =========================================
    reg [19:0] db_counter_d;
    reg        btn_d_stable;
    reg        btn_d_prev;
    wire       btn_d_pressed;

    always @(posedge clk) begin
        if (btnC) begin
            db_counter_d <= 20'd0;
            btn_d_stable <= 1'b0;
            btn_d_prev   <= 1'b0;
        end
        else begin
            btn_d_prev <= btn_d_stable;

            if (btnD != btn_d_stable) begin
                if (db_counter_d == DEBOUNCE_MAX) begin
                    btn_d_stable <= btnD;
                    db_counter_d <= 20'd0;
                end
                else begin
                    db_counter_d <= db_counter_d + 1'b1;
                end
            end
            else begin
                db_counter_d <= 20'd0;
            end
        end
    end

    assign btn_d_pressed = (btn_d_stable & ~btn_d_prev);

    // =========================================
    // 3) 카운터 (0~9999)
    // =========================================
    reg [15:0] count;

    always @(posedge clk) begin
        if (btnC)
            count <= 16'd0;
        else if (btn_u_pressed) begin
            if (count == 16'd9999)
                count <= 16'd0;
            else
                count <= count + 1'b1;
        end
        else if (btn_d_pressed) begin
            if (count == 16'd0)
                count <= 16'd9999;
            else
                count <= count - 1'b1;
        end
    end

    // =========================================
    // 4) 10진수 자릿수 분리 (BCD 변환)
    // =========================================
    reg [3:0] digit0, digit1, digit2, digit3;

    always @(*) begin
        digit0 = count % 10;
        digit1 = (count / 10) % 10;
        digit2 = (count / 100) % 10;
        digit3 = (count / 1000) % 10;
    end

    // =========================================
    // 5) 7-Segment 스캔 (Day 3과 동일 패턴)
    // =========================================
    localparam SCAN_CNT_MAX = 17'd99_999;

    reg [16:0] scan_counter;
    reg [2:0]  digit_sel;

    always @(posedge clk) begin
        if (btnC) begin
            scan_counter <= 17'd0;
            digit_sel    <= 3'd0;
        end
        else if (scan_counter == SCAN_CNT_MAX) begin
            scan_counter <= 17'd0;
            digit_sel    <= digit_sel + 1'b1;
        end
        else begin
            scan_counter <= scan_counter + 1'b1;
        end
    end

    // 현재 자릿수에 표시할 값 선택
    reg [3:0] hex_digit;

    always @(*) begin
        case (digit_sel)
            3'd0: hex_digit = digit0;
            3'd1: hex_digit = digit1;
            3'd2: hex_digit = digit2;
            3'd3: hex_digit = digit3;
            default: hex_digit = 4'h0;
        endcase
    end

    // 7-Segment 디코더
    always @(*) begin
        case (hex_digit)
            4'h0: seg = 7'b000_0001;
            4'h1: seg = 7'b100_1111;
            4'h2: seg = 7'b001_0010;
            4'h3: seg = 7'b000_0110;
            4'h4: seg = 7'b100_1100;
            4'h5: seg = 7'b010_0100;
            4'h6: seg = 7'b010_0000;
            4'h7: seg = 7'b000_1111;
            4'h8: seg = 7'b000_0000;
            4'h9: seg = 7'b000_0100;
            default: seg = 7'b111_1111;
        endcase
    end

    // 하위 4자리만 활성화
    always @(*) begin
        an = 8'b1111_1111;
        if (digit_sel <= 3'd3)
            an[digit_sel] = 1'b0;
    end

    always @(*) begin
        dp = 1'b1;
    end

endmodule