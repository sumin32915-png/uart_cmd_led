# HBE-Combo II-DLD S75 (xc7s75fgga484-1) / STM32_2 과제6, 과제7 / Top: uart_cmd_led
# MAIN CLOCK 스위치 F(50 MHz), KEYPADS SEL 아래(Button Switch), UART 9600 8N1
# 연결: MCU PC10(UART3 TX) -> BDIO 0, MCU GND <-> 보드 GND
set_property PACKAGE_PIN B6 [get_ports clk_50mhz]
create_clock -name clk_50mhz -period 20.000 [get_ports clk_50mhz]

# SW_1 = 리셋
set_property PACKAGE_PIN K4 [get_ports rst_p]

# MCU에서 오는 UART 입력: 브레드보드 I/O BDIO 0 (기존 USB-UART RX인 C6는 사용하지 않음)
set_property PACKAGE_PIN F8 [get_ports mcu_rx]
# 점퍼선이 빠져도 UART 대기 상태(HIGH)를 유지하도록 내부 풀업 사용
set_property PULLUP TRUE [get_ports mcu_rx]

# FPGA -> PC: 보드 USB-UART TX (LAB3 UART 에코와 같은 핀)
set_property PACKAGE_PIN F6 [get_ports pc_tx]

# 명령 LED: LED 1
set_property PACKAGE_PIN L4 [get_ports led]

set_property IOSTANDARD LVCMOS33 [get_ports *]
set_false_path -from [get_ports {rst_p mcu_rx}]
