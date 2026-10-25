`timescale 1ns/1ps
// STM32_2 과제6, 과제7 FPGA 최상위
// 과제6: MCU에서 받은 바이트를 그대로 PC(F6)로 다시 보낸다.
// 과제7: '0' 끄기, '1' 켜기, '2' 반전, 그 밖의 문자는 유지
module uart_cmd_led #(parameter CLKS_PER_BIT = 5208)(
    input  wire clk_50mhz,
    input  wire rst_p,
    input  wire mcu_rx,       // 확장 GPIO, MCU PC10과 연결
    output wire pc_tx,        // F6, 보드 USB-UART
    output reg  led           // 지정한 LED 한 개
);
    wire [7:0] rx_data;
    wire       rx_valid, frame_err, tx_busy;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx(
        .clk_50mhz(clk_50mhz), .rst_p(rst_p), .rx(mcu_rx),
        .rx_data(rx_data), .rx_valid(rx_valid), .frame_err(frame_err));

    // 송신 중에 다음 바이트가 도착할 때를 대비한 1바이트 대기 버퍼
    reg [7:0] pend_data;
    reg       pend;
    reg       tx_start;
    reg [7:0] tx_data;

    always @(posedge clk_50mhz) begin
        if (rst_p) begin
            pend <= 1'b0; pend_data <= 0; tx_start <= 1'b0; tx_data <= 0;
        end else begin
            tx_start <= 1'b0;
            if (rx_valid) begin pend <= 1'b1; pend_data <= rx_data; end
            else if (pend && !tx_busy && !tx_start) begin
                tx_data <= pend_data; tx_start <= 1'b1; pend <= 1'b0;
            end
        end
    end

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx(
        .clk_50mhz(clk_50mhz), .rst_p(rst_p), .tx_start(tx_start),
        .tx_data(tx_data), .tx(pc_tx), .busy(tx_busy));

    // 과제7 명령 처리, 문자 '0'은 0x30이며 숫자 0과 다르다
    always @(posedge clk_50mhz) begin
        if (rst_p) led <= 1'b0;
        else if (rx_valid) begin
            case (rx_data)
                8'h30:   led <= 1'b0;   // '0'
                8'h31:   led <= 1'b1;   // '1'
                8'h32:   led <= 1'b1;   // '2'
                default: led <= led;
            endcase
        end
    end
endmodule
