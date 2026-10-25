`timescale 1ns/1ps
// UART 송신기, 8N1, LSB부터 송신
module uart_tx #(parameter CLKS_PER_BIT = 5208)(
    input  wire       clk_50mhz,
    input  wire       rst_p,
    input  wire       tx_start,    // busy가 0일 때 한 클록 HIGH
    input  wire [7:0] tx_data,
    output reg        tx,          // F6, 보드 USB-UART로 PC에 출력
    output reg        busy
);
    reg [15:0] count;
    reg [3:0]  bit_idx;            // 0: 시작, 1~8: 데이터, 9: 정지
    reg [9:0]  frame;

    always @(posedge clk_50mhz) begin
        if (rst_p) begin
            tx <= 1'b1; busy <= 1'b0; count <= 0; bit_idx <= 0; frame <= 10'h3FF;
        end else if (!busy) begin
            tx <= 1'b1;
            if (tx_start) begin
                frame   <= {1'b1, tx_data, 1'b0};   // {정지, 데이터, 시작}
                busy    <= 1'b1;
                count   <= 0;
                bit_idx <= 0;
                tx      <= 1'b0;                    // 시작 비트
            end
        end else if (count == CLKS_PER_BIT - 1) begin
            count <= 0;
            if (bit_idx == 4'd9) begin
                busy <= 1'b0;                       // 정지 비트 한 개 끝
                tx   <= 1'b1;
            end else begin
                bit_idx <= bit_idx + 1'b1;
                tx      <= frame[bit_idx + 1'b1];
            end
        end else count <= count + 1'b1;
    end
endmodule
