// ─── uart_rx.v ───
module uart_rx(
    input        clk,         // 100MHz
    input        reset,
    input        rx,          // UART RX 핀 (직렬 입력)
    output reg [7:0] rx_data, // 수신된 데이터
    output reg   rx_done      // 수신 완료 펄스 (1클럭)
);

    // ========== 보레이트 × 16 생성기 ==========
    localparam CLKS_PER_OVERSAMPLE = 651;  // 100MHz / (9600 × 16)

    reg [9:0] oversample_counter;
    wire      oversample_tick;

    assign oversample_tick = (oversample_counter == CLKS_PER_OVERSAMPLE - 1);

    always @(posedge clk) begin
        if (reset)
            oversample_counter <= 10'd0;
        else if (oversample_tick)
            oversample_counter <= 10'd0;
        else
            oversample_counter <= oversample_counter + 1;
    end

    // ========== 입력 동기화 (메타스태빌리티 방지) ==========
    reg rx_sync1, rx_sync2;

    always @(posedge clk) begin
        if (reset) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    // ========== 상태 정의 ==========
    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_DATA  = 2'b10;
    localparam S_STOP  = 2'b11;

    reg [1:0] state, next_state;
    reg [3:0] tick_count;    // 오버샘플 틱 카운터 (0~15)
    reg [2:0] bit_index;     // 수신 비트 인덱스 (0~7)
    reg [7:0] rx_shift;      // 수신 데이터 시프트 레지스터

    // ========== 상태 레지스터 ==========
    always @(posedge clk) begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ========== 다음 상태 로직 ==========
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (rx_sync2 == 1'b0)       // Start bit 하강 엣지 감지
                    next_state = S_START;
            end
            S_START: begin
                if (oversample_tick && tick_count == 4'd7) begin
                    // 반 비트 후 중앙에서 Start bit 재확인
                    if (rx_sync2 == 1'b0)
                        next_state = S_DATA;  // 진짜 Start bit
                    else
                        next_state = S_IDLE;  // 노이즈였음, 복귀
                end
            end
            S_DATA: begin
                if (oversample_tick && tick_count == 4'd15 && bit_index == 3'd7)
                    next_state = S_STOP;
            end
            S_STOP: begin
                if (oversample_tick && tick_count == 4'd15)
                    next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // ========== 데이터패스 ==========
    always @(posedge clk) begin
        if (reset) begin
            tick_count <= 4'd0;
            bit_index  <= 3'd0;
            rx_shift   <= 8'd0;
            rx_data    <= 8'd0;
            rx_done    <= 1'b0;
        end else begin
            rx_done <= 1'b0;  // 기본: 0 (1클럭 펄스)

            case (state)
                S_IDLE: begin
                    tick_count <= 4'd0;
                    bit_index  <= 3'd0;
                end

                S_START: begin
                    if (oversample_tick) begin
                        if (tick_count == 4'd7)
                            tick_count <= 4'd0;  // 중앙 도달, 카운터 리셋
                        else
                            tick_count <= tick_count + 1;
                    end
                end

                S_DATA: begin
                    if (oversample_tick) begin
                        if (tick_count == 4'd15) begin
                            tick_count <= 4'd0;
                            // 비트 중앙에서 샘플링
                            rx_shift <= {rx_sync2, rx_shift[7:1]};  // MSB에 새 비트, 오른쪽 시프트
                            bit_index <= bit_index + 1;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end

                S_STOP: begin
                    if (oversample_tick) begin
                        if (tick_count == 4'd15) begin
                            rx_done <= 1'b1;     // 수신 완료 펄스
                            rx_data <= rx_shift;  // 최종 데이터 출력
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule