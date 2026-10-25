`timescale 1ns/1ps
// 축소된 CLKS_PER_BIT=16으로 UART 프레임을 모의 실행한다.
module tb;
    initial begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end  // 파형 기록
    localparam CPB = 16;
    reg clk = 0, rst = 1, rx = 1;
    always #5 clk = ~clk;
    wire tx, led;
    uart_cmd_led #(.CLKS_PER_BIT(CPB)) dut(clk, rst, rx, tx, led);

    // PC 쪽 수신 모델: F6 출력의 한 프레임을 해독한다.
    reg [7:0] got; integer i;
    task recv_tx(output [7:0] b);
        begin
            @(negedge tx);                 // 시작 비트
            repeat (CPB/2) @(posedge clk);
            if (tx !== 1'b0) $fatal(1, "tx start bit");
            for (i = 0; i < 8; i = i + 1) begin
                repeat (CPB) @(posedge clk);
                b[i] = tx;
            end
            repeat (CPB) @(posedge clk);
            if (tx !== 1'b1) $fatal(1, "tx stop bit");
        end
    endtask

    // MCU 쪽 송신 모델: 8N1 한 프레임을 보낸다.
    integer k;
    task send(input [7:0] b);
        begin
            @(negedge clk); rx = 0; repeat (CPB) @(negedge clk);
            for (k = 0; k < 8; k = k + 1) begin rx = b[k]; repeat (CPB) @(negedge clk); end
            rx = 1; repeat (CPB) @(negedge clk);
        end
    endtask

    // 보낸 문자와 PC로 돌아온 문자, LED 기대값을 차례로 검사
    task check(input [7:0] b, input exp_led);
        begin
            fork
                send(b);
                recv_tx(got);
            join
            if (got !== b) $fatal(1, "echo sent=%h got=%h", b, got);
            if (led !== exp_led) $fatal(1, "led cmd=%h exp=%b got=%b", b, exp_led, led);
            $display("sent %h (%c) echo %h led %b", b, b, got, led);
        end
    endtask

    initial begin
        repeat (3) @(negedge clk); rst = 0;
        if (tx !== 1 || led !== 0) $fatal(1, "reset");
        check("1", 1);  check("A", 1);  check("a", 1);      // 과제6 문자
        check("0", 0);  check("1", 1);  check("1", 1);      // '1' 반복은 계속 켜짐
        check("2", 0);  check("2", 1);  check("2", 0);      // '2' 반복은 매번 반전
        check("x", 0);  check(8'h01, 0);                    // 숫자 1(0x01)은 명령이 아님
        $display("PASS uart_cmd_led: echo 11 bytes, LED 0/1/2/other"); $finish;
    end
    initial begin #200000; $fatal(1, "timeout"); end
endmodule
