`timescale 1ns/1ps
// UART 수신기, 8N1, LSB부터 수신
// CLKS_PER_BIT = 50,000,000 / 9600 = 5208
module uart_rx #(parameter CLKS_PER_BIT = 5208)(
    input  wire       clk_50mhz,
    input  wire       rst_p,
    input  wire       rx,          // MCU PC10(TX)에서 오는 선
    output reg  [7:0] rx_data,
    output reg        rx_valid,    // 한 바이트 수신 완료 시 한 클록 HIGH
    output reg        frame_err    // 정지 비트가 0이면 HIGH
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    // 비동기 입력을 클록에 맞추는 2단 동기화, 대기 상태는 HIGH
    reg rx_s1, rx_s2;
    always @(posedge clk_50mhz) begin
        if (rst_p) begin rx_s1 <= 1'b1; rx_s2 <= 1'b1; end
        else       begin rx_s1 <= rx;   rx_s2 <= rx_s1; end
    end

    reg [1:0]  state;
    reg [15:0] count;
    reg [2:0]  bit_idx;
    reg [7:0]  shift;

    always @(posedge clk_50mhz) begin
        if (rst_p) begin
            state <= IDLE; count <= 0; bit_idx <= 0; shift <= 0;
            rx_data <= 0; rx_valid <= 1'b0; frame_err <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            case (state)
            IDLE: begin
                count <= 0; bit_idx <= 0;
                if (rx_s2 == 1'b0) state <= START;   // 시작 비트의 하강 에지
            end
            START: begin                              // 시작 비트 중앙에서 다시 확인
                if (count == CLKS_PER_BIT/2 - 1) begin
                    count <= 0;
                    state <= (rx_s2 == 1'b0) ? DATA : IDLE;  // 짧은 잡음은 무시
                end else count <= count + 1'b1;
            end
            DATA: begin                               // 각 데이터 비트 중앙에서 샘플
                if (count == CLKS_PER_BIT - 1) begin
                    count <= 0;
                    shift <= {rx_s2, shift[7:1]};     // LSB가 먼저 들어온다
                    if (bit_idx == 3'd7) state <= STOP;
                    else bit_idx <= bit_idx + 1'b1;
                end else count <= count + 1'b1;
            end
            STOP: begin
                if (count == CLKS_PER_BIT - 1) begin
                    count <= 0;
                    state <= IDLE;
                    rx_data   <= shift;
                    rx_valid  <= rx_s2;               // 정지 비트가 1일 때만 유효
                    frame_err <= ~rx_s2;
                end else count <= count + 1'b1;
            end
            endcase
        end
    end
endmodule
