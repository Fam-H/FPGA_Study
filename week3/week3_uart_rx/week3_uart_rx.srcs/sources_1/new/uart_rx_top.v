// ─── uart_rx_top.v ───
module uart_rx_top(
    input        clk,
    input        reset,
    input        rx,           // USB-UART RX
    output [6:0] seg,
    output [7:0] an,
    output [7:0] LED           // 수신 데이터 표시
);

    wire [7:0] rx_data;
    wire       rx_done;
    reg  [7:0] display_data;

    // ─── UART RX 인스턴스 ───
    uart_rx u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // ─── 수신 데이터 래치 ───
    always @(posedge clk) begin
        if (reset)
            display_data <= 8'd0;
        else if (rx_done)
            display_data <= rx_data;
    end

    assign LED = display_data;

    // ─── 7세그먼트: 하위 4비트 + 상위 4비트 표시 ───
    // 2자리 16진수로 표시 (예: 'A' = 0x41 → "41")
    reg [6:0] seg_reg;
    reg [7:0] an_reg;
    reg [16:0] refresh_counter;
    wire refresh_tick;

    assign refresh_tick = (refresh_counter == 17'd99_999);  // ~1kHz 스캔

    always @(posedge clk) begin
        if (reset)
            refresh_counter <= 17'd0;
        else if (refresh_tick)
            refresh_counter <= 17'd0;
        else
            refresh_counter <= refresh_counter + 1;
    end

    reg scan_digit;  // 0 또는 1 (2자리)

    always @(posedge clk) begin
        if (reset)
            scan_digit <= 1'b0;
        else if (refresh_tick)
            scan_digit <= ~scan_digit;
    end

    reg [3:0] hex_digit;

    always @(*) begin
        case (scan_digit)
            1'b0: begin
                an_reg = 8'b11111110;   // AN[0] - 하위 4비트
                hex_digit = display_data[3:0];
            end
            1'b1: begin
                an_reg = 8'b11111101;   // AN[1] - 상위 4비트
                hex_digit = display_data[7:4];
            end
        endcase
    end

    // HEX 디코더 (0~F)
    always @(*) begin
        case (hex_digit)
            4'h0: seg_reg = 7'b1000000;
            4'h1: seg_reg = 7'b1111001;
            4'h2: seg_reg = 7'b0100100;
            4'h3: seg_reg = 7'b0110000;
            4'h4: seg_reg = 7'b0011001;
            4'h5: seg_reg = 7'b0010010;
            4'h6: seg_reg = 7'b0000010;
            4'h7: seg_reg = 7'b1111000;
            4'h8: seg_reg = 7'b0000000;
            4'h9: seg_reg = 7'b0010000;
            4'hA: seg_reg = 7'b0001000;
            4'hB: seg_reg = 7'b0000011;
            4'hC: seg_reg = 7'b1000110;
            4'hD: seg_reg = 7'b0100001;
            4'hE: seg_reg = 7'b0000110;
            4'hF: seg_reg = 7'b0001110;
            default: seg_reg = 7'b1111111;
        endcase
    end

    assign seg = seg_reg;
    assign an  = an_reg;

endmodule