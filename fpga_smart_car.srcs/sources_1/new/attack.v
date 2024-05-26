`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/25 08:50:31
// Design Name: 
// Module Name: attack
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


module attack(
    input clk,rst_n,
    input [1:0] lr,
    input sig,
    output reg attack_signal
    );
    reg [32:0] count;
    always@(posedge clk)
    begin
        if(rst_n)begin
            count <= 0;
            attack_signal <= 0;
        end
        else if(count == 50000000)begin
            count <= 0;
            if (sig == 1 && lr == 2'b11)
                attack_signal <= 1;
        end
        else
            count <= count + 1;
    end
    
endmodule
