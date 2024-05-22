`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2024 10:26:37 PM
// Design Name: 
// Module Name: CarControl
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


module CarControl(
    input clock_i,
    input reset_i,
    input enable_i,
    input [15:0] speed_i,
    input [1:0] direction_i,
    input rotate_i,
    output [8:1] out_o
    );
    wire [4:1] motor_portA;
    wire [4:1] motor_portB;

    assign {out_o[1], out_o[3], out_o[8], out_o[6]} = motor_portA[4:1];
    assign {out_o[2], out_o[4], out_o[7], out_o[5]} = motor_portB[4:1];

    reg[7:0] speed_left;
    reg[7:0] speed_right;

    always @(*) begin
        case (direction_i)
            2'b01: begin
                speed_left = speed_i[7:0];
                speed_right = speed_i[7:0] / 2;
            end
            2'b10: begin
                speed_left = speed_i[7:0] / 2;
                speed_right = speed_i[7:0];
            end
            default: begin
                speed_left = speed_i[7:0];
                speed_right = speed_i[7:0];
            end
        endcase
    end



    MotorControl #(
        .SPEED_RANGE_MAX(128)
        ) Control_motor1 (
        .clock_i(clock_i),
        .reset_i(reset_i),
        .enable_i(enable_i),
        .rotate_i(rotate_i),
        .motor_speed_i(speed_left),
        .motor_portA_o(motor_portA[4]),
        .motor_portB_o(motor_portB[4])
    );

    MotorControl #(
        .SPEED_RANGE_MAX(128)
        ) Control_motor2 (
        .clock_i(clock_i),
        .reset_i(reset_i),
        .enable_i(enable_i),
        .rotate_i(rotate_i),
        .motor_speed_i(speed_left),
        .motor_portA_o(motor_portA[2]),
        .motor_portB_o(motor_portB[2])
    );

        MotorControl #(
        .SPEED_RANGE_MAX(128)
        ) Control_motor3 (
        .clock_i(clock_i),
        .reset_i(reset_i),
        .enable_i(enable_i),
        .rotate_i(rotate_i),
        .motor_speed_i(speed_right),
        .motor_portA_o(motor_portA[3]),
        .motor_portB_o(motor_portB[3])
    );

        MotorControl #(
        .SPEED_RANGE_MAX(128)
        ) Control_motor4 (
        .clock_i(clock_i),
        .reset_i(reset_i),
        .enable_i(enable_i), 
        .rotate_i(rotate_i),
        .motor_speed_i(speed_right),
        .motor_portA_o(motor_portA[1]),
        .motor_portB_o(motor_portB[1])
    );

endmodule 
