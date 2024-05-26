`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/24 22:22:51
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    // 摄像头
    input pclk,
    input vsync,
    input href,
    input [7:0] d,
    input rst_n,
    output sioc,
    inout siod,
    output reset,
    output pwdn,
    output xclk,
    output vga_hsync,
    output vga_vsync,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    input sys_clock,
    input flash_open,
    input rst_lr,
    // 网络控制通信接口
    input ROTATE,
    input [1:0] DIRECTION,
    input [1:0] SPEED,
    // 电机控制
    output reg [8:1] OUT,
    // 弹药发射信号
    output  attack_signal,
    output sig,
    // 数码显示管
    output wire [7:0] an,
    output wire [6:0] sseg,
    // 超声波测距
    output  pin,//传递给串口的控制信号
    input wire PWM,
    // 模式转换按钮
    input SW
);
    wire [1:0] lr;
    wire [1:0] speed;
    wire config_finished;
    cemera cemera_inst(
        .pclk(pclk),
        .vsync(vsync),
        .href(href),
        .d(d),
        .rst_n(rst_n),
        .config_finished(config_finished),
        .sioc(sioc),
        .siod(siod),
        .reset(reset),
        .pwdn(pwdn),
        .xclk(xclk),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .sys_clock(sys_clock),
        .flash_open(flash_open),
        .rst_lr(rst_lr),
        .lr(lr),
        .speed(speed)
    );
    ultrasound_distance_detect ultrasound_distance_detect_inst(
        .clk_100Mhz(sys_clock),
        .rst_n(rst_n),
        .PWM(PWM),
        .encontrol(config_finished),
        .an(an),
        .sseg(sseg),
        .pin(pin),
        .attack_signal(sig)
    );

    reg attack_enable;
    attack attack_inst(
        .clk(sys_clock),
        .rst_n(attack_enable),
        .lr(lr),
        .sig(sig),
        .attack_signal(attack_signal)
    );

    wire [8:1] output_auto;
    MoveCar auto_control_part(
        .CLK100MHZ(sys_clock),
        .SW(1'b1),
        .ROTATE(1'b0),
        .DIRECTION(lr),
        .SPEED(speed),
        .OUT(output_auto)
    );

    wire [8:1] output_web_control;
    RemoteCar remote_control_part(
        .clk_i(sys_clock),
        .en_i(1'b1),
        .rotate_i(ROTATE),
        .direction_i(DIRECTION),
        .speed_i(SPEED),
        .out_o(output_web_control)
    );

    always @(*) begin
        case (SW)
            1'b0: begin
                OUT <= output_auto;
                attack_enable <= 1'b1;
            end
            1'b1: begin
                OUT <= rst_n ? output_web_control : 8'b00000000;
                attack_enable <= 1'b0;
            end
        endcase
    end

endmodule
