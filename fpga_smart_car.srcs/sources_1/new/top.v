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
   input        pclk,
   input        vsync,
   input        href,
   input [7:0]  d,
   input        rst_n,
   output       sioc,
   inout        siod,
   output       reset,
   output       pwdn,
   output       xclk,
   output       vga_hsync,
   output       vga_vsync,
   output [3:0] vga_r,
   output [3:0] vga_g,
   output [3:0] vga_b,
   input        sys_clock,
   input        flash_open,
   input        rst_lr,
   input  SW,
   input ROTATE,
   output [8:1] OUT,
   output  attack_signal,
   output wire [7:0] an,
   output wire [6:0] sseg,
   output  pin,//传递给串口的控制信号
   input wire PWM,
   output sig
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
    attack attack_inst(
        .clk(sys_clock),
        .rst_n(rst_n),
        .lr(lr),
        .sig(sig),
        .attack_signal(attack_signal)
    );
    TestCar TestCar_inst(
        .CLK100MHZ(sys_clock),
        .SW(SW),
        .ROTATE(ROTATE),
        .DIRECTION(lr),
        .SPEED(speed),
        .OUT(OUT)
    );
endmodule
