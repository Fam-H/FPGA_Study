// bram_basic.v
module bram_basic(
    input        clk,
    input        btnC,       // 쓰기 버튼
    input [15:0] SW,
    output [7:0] LED
);

    // --- 버튼 동기화 + 엣지 검출 ---
    reg [2:0] btn_sync;
    always @(posedge clk)
        btn_sync <= {btn_sync[1:0], btnC};
    
    wire btn_edge = btn_sync[1] & ~btn_sync[2];

    // --- BRAM 추론 (Inferred BRAM) ---
    // 이 코딩 스타일을 사용하면 Vivado가 자동으로 Block RAM으로 합성합니다.
    // 핵심: reg 배열 + 동기식 읽기 = BRAM 추론 조건
    reg [7:0] mem [0:15];    // 16 x 8비트 메모리
    reg [7:0] read_data;     // 동기식 읽기용 레지스터

    wire [3:0] addr = SW[15:12];   // 주소
    wire [7:0] din  = SW[7:0];     // 쓰기 데이터

    always @(posedge clk) begin
        if (btn_edge)
            mem[addr] <= din;      // 동기식 쓰기
        read_data <= mem[addr];    // 동기식 읽기 (항상 수행)
    end

    assign LED = read_data;

endmodule