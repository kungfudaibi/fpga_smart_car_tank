`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/29 20:12:18
// Design Name: 
// Module Name: GeneratePWM
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

// PWM波生成模块
module GeneratePWM #(
    parameter PWM_BIT_WIDTH = 16
    )(
    input clock_i,
    input reset_i,
    input enable_i,
    input [PWM_BIT_WIDTH-1:0] period, // 计数周期（PWM频率约为时钟频率/period）
    input [PWM_BIT_WIDTH-1:0] high_time, // 高电平时间（0 ~ period）
    output reg pwm_o
    );

    reg [PWM_BIT_WIDTH-1:0] counter;

    always @(posedge clock_i or posedge reset_i) begin
        if (reset_i) begin
            counter <= 0;
        end else if (counter >= period) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    always @(posedge clock_i or posedge reset_i) begin
        if (reset_i) begin
            pwm_o <= 0;
        end else begin
            if (!enable_i) begin
                pwm_o <= 0;
            end else begin
                if (counter <= high_time) begin
                    pwm_o <= 1;
                end else begin
                    pwm_o <= 0;
                end
            end
        end
    end

endmodule
