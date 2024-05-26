`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/20 16:12:24
// Design Name: 
// Module Name: ultrasound_distance_detect
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
module ultrasound_distance_detect(
    input clk_100Mhz,rst_n,
    input PWM,//接收到的PWM信号
    input encontrol,//传递给超声波距离检测的控制信号
    output wire [7:0] an,
    output wire [6:0] sseg,
    output reg pin,//传递给串口的控制信号
    output  attack_signal 
    );
    always@(encontrol)
    begin
        if(encontrol)
            pin = 1;
        else
            pin = 0;
    end
    wire [7:0] distance;
    wire [3:0] one, ten, hun;
    wire [7:0] numtodisp;
    numtodisp numtodisp_inst(
        .clk(clk_100Mhz),
        .rst_n(rst_n),
        .number(distance),
        .numtodisplay(numtodisp),
        .sig(attack_signal)
    );
    chaosheng chaosheng_inst(
        .clk_100Mhz(clk_100Mhz),
        .rst_n(rst_n),
        .PWM(PWM),
        .distance(distance)
    );
    bintobcd8 bintobcd8_inst(
        .clk(clk_100Mhz),
        .rst(rst_n),
        .bin(numtodisp),
        .one(one),
        .ten(ten),
        .hun(hun)
    );
    scan_seg_disp scan_seg_disp_inst(
        .clk(clk_100Mhz),
        .one(one),
        .ten(ten),
        .hun(hun),
        .an(an),
        .sseg(sseg)
    );
endmodule
module numtodisp#(parameter timetodelay = 50000000)(
    input clk,
    input rst_n,
    input [7:0]number,
    output reg [7:0]numtodisplay,
    output reg sig
    );
    reg [32:0]temp = 0; 
    always @(posedge clk, negedge rst_n)begin
        if (!rst_n)begin
            temp <= 0;
            sig <= 0;
        end else if (temp == timetodelay)begin
            temp <= 0;
            numtodisplay <= number;
            if(number <= 10 && number >= 8)begin
                sig <= 1;                                       
            end else begin
                sig <= 0;
            end
        end else
            temp <= temp + 1;
    end
endmodule
module chaosheng(
    input clk_100Mhz,rst_n,
    input PWM,
    output reg [7:0] distance
    );
    reg [31:0] counter; // 计时器
    reg measuring; // 是否正在测量的标志

    always @(posedge clk_100Mhz , negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            distance <= 0;
            measuring <= 0;
        end else if (PWM == 1'b1 && measuring == 1'b0) begin
            // 当检测到PWM信号的上升沿时，开始计时
            measuring <= 1'b1;
            counter <= 0;
        end else if (PWM == 1'b0 && measuring == 1'b1) begin
            // 当检测到PWM信号的下降沿时，停止计时并计算距离
            measuring <= 1'b0;
            distance <= counter / (100 * 147); // 100MHz时钟下每147微秒计数一次
        end else if (measuring) begin
            // 如果正在测量，则计数器增加
            counter <= counter + 1;
        end
    end
endmodule
module bintobcd8(
    input clk, rst,
    input [7:0] bin,
    output reg [3:0]one,ten,hun
    );
    reg [17:0] shift_reg;
    reg [3:0] count;
    always@(posedge clk, negedge rst)
    begin
    if(!rst) begin
        one=0;
        ten=0;
        hun=0;
        shift_reg=0;
        count=0;
        end
	else begin
	 	if (count == 0)
        shift_reg = {10'd0, bin};
        if (count < 4'd8) begin
            count = count+1;
            if (shift_reg[11:8]>4)
                shift_reg[11:8]= shift_reg[11:8]+2'b11;
            if (shift_reg[15:12]>4)
                shift_reg[15:12] = shift_reg[15:12]+2'b11;
        shift_reg[17:1] = shift_reg[16:0];
        end
        else if (count==4'd8)  begin
            one= shift_reg[11:8];
            ten = shift_reg[15:12];
            hun= {2'b00,shift_reg[17:16]};
            count = count+1;
            end
            else 
            count = count-9;
        end
    end
endmodule

//扫描显示模块

module scan_seg_disp (
    input clk,
    input [3:0] one, ten, hun,
    output reg [7:0] an,
    output reg [6:0] sseg
    );
    localparam N=20;
    reg [N-1:0] cnt;
    reg [3:0] hex;
    always @(posedge clk)
    begin   
        cnt = cnt + 1;
        case (cnt[N-1 : N-2])
        2'b00:begin
         hex = one;
        an = 8'b11111110;
        end
        2'b01:begin
        hex = ten;
        an = 8'b11111101;
        end
        2'b10:begin
        hex = hun;
        an = 8'b11111011;
        end
        endcase
	end
    always@ (*)begin
        case(hex)
        4'h0:sseg[6:0] = 7'b0000001;
        4'h1:sseg[6:0] = 7'b1001111;
        4'h2:sseg[6:0] = 7'b0010010;
        4'h3:sseg[6:0] = 7'b0000110;
        4'h4:sseg[6:0] = 7'b1001100;
        4'h5:sseg[6:0] = 7'b0100100;
        4'h6:sseg[6:0] = 7'b0100000;
        4'h7:sseg[6:0] = 7'b0001111;
        4'h8:sseg[6:0] = 7'b0000000;
        4'h9:sseg[6:0] = 7'b0000100;
        default:
        sseg[6:0] = 7'b1111111;
        endcase
    end
endmodule
