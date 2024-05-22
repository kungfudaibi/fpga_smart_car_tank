`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/04/29 21:58:49
// Design Name:
// Module Name: MotorControl
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


module MotorControl #(parameter SPEED_RANGE_MAX = 128)(
    input clock_i,
    input reset_i,
    input enable_i,
    input rotate_i, // 0: 正转，1: 反转
    input [15:0] motor_speed_i, // 电机速度
    output motor_portA_o, // 电机引脚A
    output motor_portB_o // 电机引脚B
    );
    
    localparam CLOCK_FREQUENCY = 100_000_000; // 时钟频率
    localparam PWM_FREQUENCY   = 100_000; // PWM频率
    
    wire PWM_signal;
    assign motor_portA_o = rotate_i ? PWM_signal : 0;
    assign motor_portB_o = rotate_i ? 0 : PWM_signal;
    
    wire enable;
    assign enable = enable_i & !reset_i;
    
    // 电机速度转译pwm波
    localparam PERIOD = (CLOCK_FREQUENCY / PWM_FREQUENCY) - 1;
    wire [15:0] high_time;
    assign high_time = motor_speed_i * PERIOD / SPEED_RANGE_MAX;
    GeneratePWM Pwm_to_control_motor (
        .clock_i(clock_i),
        .reset_i(reset_i),
        .enable_i(enable),
        .period(PERIOD),
        .high_time(high_time),
        .pwm_o(PWM_signal)
    );
    
endmodule
