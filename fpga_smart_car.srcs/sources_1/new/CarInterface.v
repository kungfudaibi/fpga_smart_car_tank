`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/04/29 19:37:42
// Design Name:
// Module Name: TestMotor
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

// 顶层模块
module TestCar(
    input CLK100MHZ,
    input  SW,
    input ROTATE,
    input [1:0] DIRECTION,
    input [1:0] SPEED,
    output [8:1] OUT
    );

    wire master_switch;
    wire rotate;
    wire reset;
    wire [1:0] direction;
    reg [15:0] motor1_speed;
    
    assign master_switch = SW;
    assign rotate = ROTATE;
    assign reset = 1'b0;
    assign direction = DIRECTION[1:0];

    always @(*) begin
        // if (SW[0]) begin
        //     motor1_speed = 128;
        // end else if (SW[1]) begin
        //     motor1_speed = 96;
        // end else if (SW[2]) begin
        //     motor1_speed = 64;
        // end else if (SW[3]) begin
        //     motor1_speed = 32;
        // end else begin
        //     motor1_speed = 0;
        // end
        case(SPEED)
            2'b00: motor1_speed = 0;
            2'b01: motor1_speed = 40;
            2'b10: motor1_speed = 80;
            2'b11: motor1_speed = 128;
        endcase
    end

    CarControl car_control (
        .clock_i(CLK100MHZ),
        .reset_i(reset),
        .enable_i(master_switch),
        .speed_i(motor1_speed),
        .direction_i(direction),
        .rotate_i(rotate),
        .out_o(OUT)
    );
endmodule
