`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2024 10:48:54 PM
// Design Name: 
// Module Name: RemoteCar
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
module RemoteCar(
    input clk_i,
    input en_i,
    input rotate_i,
    input [1:0] direction_i,
    input [1:0] speed_i,
    output [8:1] out_o
    );

    wire master_switch;
    wire rotate;
    wire reset;
    wire [1:0] direction;
    reg [15:0] motor1_speed;
    
    assign master_switch = en_i;
    assign rotate = rotate_i;
    assign reset = 1'b0;
    assign direction = direction_i[1:0];

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
        case(speed_i[1:0])
            2'b00: motor1_speed = 0;
            2'b01: motor1_speed = 54;
            2'b10: motor1_speed = 108;
            2'b11: motor1_speed = 128;
        endcase
    end

    CarControl car_control (
        .clock_i(clk_i),
        .reset_i(reset),
        .enable_i(master_switch),
        .speed_i(motor1_speed),
        .direction_i(direction),
        .rotate_i(rotate),
        .out_o(out_o)
    );
endmodule

