// ─── uart_tx.v ───
module uart_tx(
    input        clk,        // 100MHz
    input        reset,
    input        tx_start,   // 전송 시작 신호 (1클럭 펄스)
    input  [7:0] tx_data,    // 전송할 데이터
    output reg   tx,         // UART TX 핀 (직렬 출력)
    output reg   tx_busy     // 전송 중 표시
);

    // ========== 보레이트 생성기 ==========
    localparam CLKS_PER_BIT = 10417;  // 100MHz / 9600bps

    reg [13:0] baud_counter;  // 14비트 (10417 < 16384)
    wire       baud_tick;

    assign baud_tick = (baud_counter == CLKS_PER_BIT - 1);

    // ========== 상태 정의 ==========
    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_DATA  = 2'b10;
    localparam S_STOP  = 2'b11;

    reg [1:0] state, next_state;
    reg [2:0] bit_index;     // 현재 전송 중인 비트 (0~7)
    reg [7:0] tx_shift;      // 전송 데이터 보관용

    // ========== 보레이트 카운터 ==========
    always @(posedge clk) begin
        if (reset)
            baud_counter <= 14'd0;
        else if (state == S_IDLE)
            baud_counter <= 14'd0;
        else if (baud_tick)
            baud_counter <= 14'd0;
        else
            baud_counter <= baud_counter + 1;
    end

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
                if (tx_start)
                    next_state = S_START;
            end
            S_START: begin
                if (baud_tick)
                    next_state = S_DATA;
            end
            S_DATA: begin
                if (baud_tick && bit_index == 3'd7)
                    next_state = S_STOP;
            end
            S_STOP: begin
                if (baud_tick)
                    next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // ========== 데이터패스 (순차 논리) ==========
    always @(posedge clk) begin
        if (reset) begin
            bit_index <= 3'd0;
            tx_shift  <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    bit_index <= 3'd0;
                    if (tx_start)
                        tx_shift <= tx_data;  // 전송 데이터 캡처
                end
                S_DATA: begin
                    if (baud_tick) begin
                        bit_index <= bit_index + 1;
                        tx_shift  <= {1'b0, tx_shift[7:1]};  // 오른쪽 시프트
                    end
                end
            endcase
        end
    end

    // ========== 출력 로직 ==========
    always @(*) begin
        tx = 1'b1;          // 기본: HIGH (유휴)
        tx_busy = 1'b1;     // 기본: 바쁨
        case (state)
            S_IDLE: begin
                tx = 1'b1;
                tx_busy = 1'b0;
            end
            S_START: begin
                tx = 1'b0;          // Start bit = LOW
            end
            S_DATA: begin
                tx = tx_shift[0];   // LSB부터 전송
            end
            S_STOP: begin
                tx = 1'b1;          // Stop bit = HIGH
            end
        endcase
    end

endmodule