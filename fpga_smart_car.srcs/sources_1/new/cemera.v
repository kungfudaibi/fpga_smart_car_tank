`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/24 22:12:44
// Design Name: 
// Module Name: cemera
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
module cemera(
   input        pclk,
   input        vsync,
   input        href,
   input [7:0]  d,
   input        rst_n,
   output       config_finished,
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
   output [1:0] lr,
   output [1:0] speed
);
    wire clk_24m;
    wire clk_25m;
    wire clk_50m;
    wire [0:0]   we_t;
    wire [11:0]  dout_t;
    wire [17:0]  addr_t;
    wire [17:0]  frame_addr_t;
    wire [11:0]  frame_pixel_t;
    wire         reset_t;
    wire         initial_en_t;
    wire         rst_n_not;
    wire [19:0]   middle_pixel_count;
    wire [19:0]   left_pixel_count;
    wire [19:0]   right_pixel_count;
    assign xclk = clk_24m;
    assign reset = reset_t;
    assign rst_n_not = (~(rst_n));

    //实例化内存读取
    blk_mem_gen_0 bram(
      .clka(pclk),           // 第一个时钟输入，通常用于写入数据
      .wea(we_t),            // 写使能信号，当此信号为高时，数据会被写入内存
      .dina(dout_t),         // 数据输入端口，当写使能信号为高时，此端口的数据会被写入内存
      .addra(addr_t),        // 地址输入端口，用于指定要写入或读取的内存地址
      .addrb(frame_addr_t),  // 第二个地址输入端口，通常用于读取数据
      .clkb(clk_24m),        // 第二个时钟输入，通常用于读取数据
      .doutb(frame_pixel_t)  // 数据输出端口，当读取操作发生时，内存中的数据会从此端口输出
      );

    clk_wiz_0 clk(
        .reset(rst_n_not),
        .clk_in1(sys_clock),
        .clk_out1(clk_24m),
        .clk_out2(clk_25m),
        .clk_out3(clk_50m)
    );
    
   capture mycapture(
      .pclk(pclk),
      .vsync(vsync),
      .href(href),
      .d(d),
      .addr(addr_t),
      .dout(dout_t),
      .we(we_t[0])
   );

   //实例化vga
    vga vga(
      .clk25(clk_25m),
      .vga_red(vga_r),
      .vga_green(vga_g),
      .vga_blue(vga_b),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .frame_addr(frame_addr_t),
      .frame_pixel(frame_pixel_t),
      .left_pixel_count(left_pixel_count),
      .middle_pixel_count(middle_pixel_count),
      .right_pixel_count(right_pixel_count)
   );

   power_on_delay power(
      .clk_50m(clk_50m),
      .reset_n(rst_n),
      .camera1_rstn(reset_t),
      .camera_pwnd(pwdn),
      .initial_en(initial_en_t)
   );
   
   
   regcon configs(
      .clk_25m(clk_25m),
      .flash_open(flash_open),
      .camera_rstn(reset_t),
      .initial_en(initial_en_t),
      .reg_conf_done(config_finished),
      .i2c_sclk(sioc),
      .i2c_sdat(siod)
   );
   signalrl signalrlint(
      .clk(clk_25m),
      .lr(lr),
      .rst(rst_lr),
      .left_pixel_count(left_pixel_count),
      .middle_pixel_count(middle_pixel_count),
      .right_pixel_count(right_pixel_count) 
   );
   car_run_or_stop car_run_or_stop(
        .right_pixel_count(right_pixel_count),
        .middle_pixel_count(middle_pixel_count),
        .left_pixel_count(left_pixel_count),
        .clk(clk_25m),
        .rst(rst_lr),
        .speed(speed)
   );
endmodule
module capture (
    input pclk,  // 输入时钟
    input vsync, // 垂直同步信号
    input href,  // 水平参考信号
    input [7:0] d,  // 输入数据
    output  [17:0] addr,  // 输出地址
    output reg [11:0] dout,  // 输出数据
    output reg we  // 写使能信号
);

// 数据暂存寄存器
reg [15:0] d_latch = 16'b0;
// 当前地址寄存器
reg [18:0] address = 19'b0;
// 下一个地址寄存器
reg [18:0] address_next = 19'b0;
// 写控制寄存器
reg [1:0] wr_hold = 2'b0;

// 将地址的位·[18:1]赋值给输出addr
assign addr = address[18:1];

// 在每个pclk的上升沿
always @(posedge pclk) begin
    // 如果vsync为1
    if (vsync == 1'b1) begin
        // 重置地址和写控制寄存器
        address <= 19'b0;
        address_next <= 19'b0;
        wr_hold <= 2'b0;
    end else begin
        // 更新输出数据
        dout <= {d_latch[11:8], d_latch[7:4], d_latch[3:0]};
        // 更新地址
        address <= address_next;
        // 更新写使能信号
        we <= wr_hold[1];
        // 更新写控制寄存器和数据暂存寄存器
        wr_hold <= {wr_hold[0], href & ~wr_hold[0]};
        d_latch <= {d_latch[14:0], d};

        // 如果wr_hold[1]为1
        if (wr_hold[1] == 1'b1) begin
            // 增加下一个地址
            address_next <= address_next + 1;
        // 如果wr_hold[0]为1
        end else if (wr_hold[0] == 1'b1) begin
            // 下一个地址保持不变
            address_next <= address_next;
        end
    end
end

endmodule
module i2c(clock_i2c,          
               camera_rstn,     
               ack,              
               i2c_data,          
               start,             
               tr_end,          
               i2c_sclk,         
               i2c_sdat);         
    input [31:0]i2c_data;
    input camera_rstn;
    input clock_i2c;
    output ack;
    input start;
    output tr_end;
    output i2c_sclk;
    inout i2c_sdat;
    reg [5:0] cyc_count;
    reg reg_sdat;
    reg sclk;
    reg ack1,ack2,ack3;
    reg tr_end;
 
   
    wire i2c_sclk;
    wire i2c_sdat;
    wire ack;
   
    assign ack=ack1|ack2|ack3;
    assign i2c_sclk=sclk|(((cyc_count>=4)&(cyc_count<=39))?~clock_i2c:0);
    assign i2c_sdat=reg_sdat?1'bz:0; 
   
    always@(posedge clock_i2c or  negedge camera_rstn)
    begin
       if(!camera_rstn)
         cyc_count<=6'b111111;
       else 
		   begin
           if(start==0)
             cyc_count<=0;
           else if(cyc_count<6'b111111)
             cyc_count<=cyc_count+1;
         end
    end
	 
	 
    always@(posedge clock_i2c or negedge camera_rstn)
    begin
       if(!camera_rstn)
       begin
          tr_end<=0;
          ack1<=1;
          ack2<=1;
          ack3<=1;
          sclk<=1;
          reg_sdat<=1;
       end
       else
          case(cyc_count)
          0:begin ack1<=1;ack2<=1;ack3<=1;tr_end<=0;sclk<=1;reg_sdat<=1;end
          1:reg_sdat<=0;                 
          2:sclk<=0;
          3:reg_sdat<=i2c_data[31];
          4:reg_sdat<=i2c_data[30];
          5:reg_sdat<=i2c_data[29];
          6:reg_sdat<=i2c_data[28];
          7:reg_sdat<=i2c_data[27];
          8:reg_sdat<=i2c_data[26];
          9:reg_sdat<=i2c_data[25];
          10:reg_sdat<=i2c_data[24];
          11:reg_sdat<=1;                
          12:begin reg_sdat<=i2c_data[23];ack1<=i2c_sdat;end
          13:reg_sdat<=i2c_data[22];
          14:reg_sdat<=i2c_data[21];
          15:reg_sdat<=i2c_data[20];
          16:reg_sdat<=i2c_data[19];
          17:reg_sdat<=i2c_data[18];
          18:reg_sdat<=i2c_data[17];
          19:reg_sdat<=i2c_data[16];
          20:reg_sdat<=1;                      
          21:begin reg_sdat<=i2c_data[15];ack1<=i2c_sdat;end
          22:reg_sdat<=i2c_data[14];
          23:reg_sdat<=i2c_data[13];
          24:reg_sdat<=i2c_data[12];
          25:reg_sdat<=i2c_data[11];
          26:reg_sdat<=i2c_data[10];
          27:reg_sdat<=i2c_data[9];
          28:reg_sdat<=i2c_data[8];
          29:reg_sdat<=1;                     
          30:begin reg_sdat<=i2c_data[7];ack2<=i2c_sdat;end
          31:reg_sdat<=i2c_data[6];
          32:reg_sdat<=i2c_data[5];
          33:reg_sdat<=i2c_data[4];
          34:reg_sdat<=i2c_data[3];
          35:reg_sdat<=i2c_data[2];
          36:reg_sdat<=i2c_data[1];
          37:reg_sdat<=i2c_data[0];
          38:reg_sdat<=1;                      
          39:begin ack3<=i2c_sdat;sclk<=0;reg_sdat<=0;end
          40:sclk<=1;
          41:begin reg_sdat<=1;tr_end<=1;end
          endcase
       
end
endmodule
module regcon(     
		  input clk_25m,
		  input flash_open,
		  input camera_rstn,
		  input initial_en,
		  output reg_conf_done,
		  output i2c_sclk,
		  inout i2c_sdat,
		  output reg clock_20k,
		  output reg reg_conf_done_reg
	  );

    
     reg [8:0]reg_index;
     reg [15:0]clock_20k_cnt;
     reg [1:0]config_step;
	  
     reg [31:0]i2c_data;
     reg [23:0]reg_data;
     reg start;
	  
	  
     i2c u1(.clock_i2c(clock_20k),
               .camera_rstn(camera_rstn),
               .ack(ack),
               .i2c_data(i2c_data),
               .start(start),
               .tr_end(tr_end),
               .i2c_sclk(i2c_sclk),
               .i2c_sdat(i2c_sdat));

assign reg_conf_done=reg_conf_done_reg;
always@(posedge clk_25m or negedge camera_rstn)   
begin
   if(!camera_rstn) begin
        clock_20k<=0;
        clock_20k_cnt<=0;
   end
   else if(clock_20k_cnt<1249)
      clock_20k_cnt<=clock_20k_cnt+1'b1;
   else begin
         clock_20k<=!clock_20k;
         clock_20k_cnt<=0;
   end
end

always@(posedge clock_20k or negedge camera_rstn)    
begin
   if(!camera_rstn) begin
       config_step<=0;
       start<=0;
       reg_index<=0;
		 reg_conf_done_reg<=0;
   end
   else begin
      if(reg_conf_done_reg==1'b0) begin          //���camera��ʼ��δ���
			  if(reg_index<250+54*flash_open) begin               //����ǰ302���Ĵ���
					 case(config_step)
					 0:begin
						i2c_data<={8'h78,reg_data};       //OV5640 IIC Device address is 0x78   
						start<=1;                         //i2cд��ʼ
						config_step<=1;                  
					 end
					 1:begin
						if(tr_end) begin                  //i2cд����               					
							 start<=0;
							 config_step<=2;
						end
					 end
					 2:begin
						  reg_index<=reg_index+1'b1;       //������һ���Ĵ���
						  config_step<=0;
					 end
					 endcase
				end
			 else 
				reg_conf_done_reg<=1'b1;                //OV5640�Ĵ�����ʼ�����
      end
   end
 end
	
always@(reg_index)   
 begin
    case(reg_index)
	 //15fps VGA YUV output  // 24MHz input clock, 24MHz PCLK
	 0:reg_data<=24'h310311;// system clock from pad, bit[1]
	 1:reg_data<=24'h300882;// software reset, bit[7]// delay 5ms 
	 2:reg_data<=24'h300842;// software power down, bit[6]
	 3:reg_data<=24'h310303;// system clock from PLL, bit[1]
	 4:reg_data<=24'h3017ff;// FREX, Vsync, HREF, PCLK, D[9:6] output enable
	 5:reg_data<=24'h3018ff;// D[5:0], GPIO[1:0] output enable
	 6:reg_data<=24'h30341A;// MIPI 10-bit
	 7:reg_data<=24'h303713;// PLL root divider, bit[4], PLL pre-divider, bit[3:0]
	 8:reg_data<=24'h310801;// PCLK root divider, bit[5:4], SCLK2x root divider, bit[3:2] // SCLK root divider, bit[1:0] 
	 9:reg_data<=24'h363036;
	 10:reg_data<=24'h36310e;
	 11:reg_data<=24'h3632e2;
	 12:reg_data<=24'h363312;
	 13:reg_data<=24'h3621e0;
	 14:reg_data<=24'h3704a0;
	 15:reg_data<=24'h37035a;
	 16:reg_data<=24'h371578;
	 17:reg_data<=24'h371701;
	 18:reg_data<=24'h370b60;
	 19:reg_data<=24'h37051a;
	 20:reg_data<=24'h390502;
	 21:reg_data<=24'h390610;
	 22:reg_data<=24'h39010a;
	 23:reg_data<=24'h373112;
	 24:reg_data<=24'h360008;// VCM control
	 25:reg_data<=24'h360133;// VCM control
	 26:reg_data<=24'h302d60;// system control
	 27:reg_data<=24'h362052;
	 28:reg_data<=24'h371b20;
	 29:reg_data<=24'h471c50;
	 30:reg_data<=24'h3a1343;// pre-gain = 1.047x
	 31:reg_data<=24'h3a1800;// gain ceiling
	 32:reg_data<=24'h3a19f8;// gain ceiling = 15.5x
	 33:reg_data<=24'h363513;
	 34:reg_data<=24'h363603;
	 35:reg_data<=24'h363440;
	 36:reg_data<=24'h362201; // 50/60Hz detection     50/60Hz �ƹ����ƹ���
	 37:reg_data<=24'h3c0134;// Band auto, bit[7]
	 38:reg_data<=24'h3c0428;// threshold low sum	 
	 39:reg_data<=24'h3c0598;// threshold high sum
	 40:reg_data<=24'h3c0600;// light meter 1 threshold[15:8]
	 41:reg_data<=24'h3c0708;// light meter 1 threshold[7:0]
	 42:reg_data<=24'h3c0800;// light meter 2 threshold[15:8]
	 43:reg_data<=24'h3c091c;// light meter 2 threshold[7:0]
	 44:reg_data<=24'h3c0a9c;// sample number[15:8]
	 45:reg_data<=24'h3c0b40;// sample number[7:0]
	 46:reg_data<=24'h381000;// Timing Hoffset[11:8]
	 47:reg_data<=24'h381110;// Timing Hoffset[7:0]
	 48:reg_data<=24'h381200;// Timing Voffset[10:8] 
	 49:reg_data<=24'h370864;
	 50:reg_data<=24'h400102;// BLC start from line 2
	 51:reg_data<=24'h40051a;// BLC always update
	 52:reg_data<=24'h300000;// enable blocks
	 53:reg_data<=24'h3004ff;// enable clocks 
	 54:reg_data<=24'h300e58;// MIPI power down, DVP enable
	 55:reg_data<=24'h302e00;
	 56:reg_data<=24'h4300A1;// RGB444   A1
	 57:reg_data<=24'h501f01;// ISP RGB 
	 58:reg_data<=24'h440e00;
	 59:reg_data<=24'h5000a7; // Lenc on, raw gamma on, BPC on, WPC on, CIP on // AEC target    �Զ��ع����
	 60:reg_data<=24'h3a0f30;// stable range in high
	 61:reg_data<=24'h3a1028;// stable range in low
	 62:reg_data<=24'h3a1b30;// stable range out high
	 63:reg_data<=24'h3a1e26;// stable range out low
	 64:reg_data<=24'h3a1160;// fast zone high
	 65:reg_data<=24'h3a1f14;// fast zone low// Lens correction for ?   ��ͷ����
	 66:reg_data<=24'h580023;
	 67:reg_data<=24'h580114;
	 68:reg_data<=24'h58020f;
	 69:reg_data<=24'h58030f;
	 70:reg_data<=24'h580412;
	 71:reg_data<=24'h580526;
	 72:reg_data<=24'h58060c;
	 73:reg_data<=24'h580708;
	 74:reg_data<=24'h580805;
	 75:reg_data<=24'h580905;
	 76:reg_data<=24'h580a08;
	 77:reg_data<=24'h580b0d;
	 78:reg_data<=24'h580c08;
	 79:reg_data<=24'h580d03;
	 80:reg_data<=24'h580e00;
	 81:reg_data<=24'h580f00;
	 82:reg_data<=24'h581003;
	 83:reg_data<=24'h581109;
	 84:reg_data<=24'h581207;
	 85:reg_data<=24'h581303;
	 86:reg_data<=24'h581400;
	 87:reg_data<=24'h581501;
	 88:reg_data<=24'h581603;
	 89:reg_data<=24'h581708;
	 90:reg_data<=24'h58180d;
	 91:reg_data<=24'h581908;
	 92:reg_data<=24'h581a05;
	 93:reg_data<=24'h581b06;
	 94:reg_data<=24'h581c08;
	 95:reg_data<=24'h581d0e;
	 96:reg_data<=24'h581e29;
	 97:reg_data<=24'h581f17;
	 98:reg_data<=24'h582011;
	 99:reg_data<=24'h582111;
	 100:reg_data<=24'h582215;
	 101:reg_data<=24'h582328;
	 102:reg_data<=24'h582446;
	 103:reg_data<=24'h582526;
	 104:reg_data<=24'h582608;
	 105:reg_data<=24'h582726;
	 106:reg_data<=24'h582864;
	 107:reg_data<=24'h582926;
	 108:reg_data<=24'h582a24;
	 109:reg_data<=24'h582b22;
	 110:reg_data<=24'h582c24;
	 111:reg_data<=24'h582d24;
	 112:reg_data<=24'h582e06;
	 113:reg_data<=24'h582f22;
	 114:reg_data<=24'h583040;
	 115:reg_data<=24'h583142;
	 116:reg_data<=24'h583224;
	 117:reg_data<=24'h583326;
	 118:reg_data<=24'h583424;
	 119:reg_data<=24'h583522;
	 120:reg_data<=24'h583622;
	 121:reg_data<=24'h583726;
	 122:reg_data<=24'h583844;
	 123:reg_data<=24'h583924;
	 124:reg_data<=24'h583a26;
	 125:reg_data<=24'h583b28;
	 126:reg_data<=24'h583c42;
	 127:reg_data<=24'h583dce;// lenc BR offset // AWB   �Զ���ƽ��
	 128:reg_data<=24'h5180ff;// AWB B block
	 129:reg_data<=24'h5181f2;// AWB control 
	 130:reg_data<=24'h518200;// [7:4] max local counter, [3:0] max fast counter
	 131:reg_data<=24'h518314;// AWB advanced 
	 132:reg_data<=24'h518425;
	 133:reg_data<=24'h518524;
	 134:reg_data<=24'h518609;
	 135:reg_data<=24'h518709;
	 136:reg_data<=24'h518809;
	 137:reg_data<=24'h518975;
	 138:reg_data<=24'h518a54;
	 139:reg_data<=24'h518be0;
	 140:reg_data<=24'h518cb2;
	 141:reg_data<=24'h518d42;
	 142:reg_data<=24'h518e3d;
	 143:reg_data<=24'h518f56;
	 144:reg_data<=24'h519046;
	 145:reg_data<=24'h5191f8;// AWB top limit
	 146:reg_data<=24'h519204;// AWB bottom limit
	 147:reg_data<=24'h519370;// red limit
	 148:reg_data<=24'h5194f0;// green limit
	 149:reg_data<=24'h5195f0;// blue limit
	 150:reg_data<=24'h519603;// AWB control
	 151:reg_data<=24'h519701;// local limit 
	 152:reg_data<=24'h519804;
	 153:reg_data<=24'h519912;
	 154:reg_data<=24'h519a04;
	 155:reg_data<=24'h519b00;
	 156:reg_data<=24'h519c06;
	 157:reg_data<=24'h519d82;
	 158:reg_data<=24'h519e38;// AWB control // Gamma    ٤������
	 159:reg_data<=24'h548001;// Gamma bias plus on, bit[0] 
	 160:reg_data<=24'h548108;
	 161:reg_data<=24'h548214;
	 162:reg_data<=24'h548328;
	 163:reg_data<=24'h548451;
	 164:reg_data<=24'h548565;
	 165:reg_data<=24'h548671;
	 166:reg_data<=24'h54877d;
	 167:reg_data<=24'h548887;
	 168:reg_data<=24'h548991;
	 169:reg_data<=24'h548a9a;
	 170:reg_data<=24'h548baa;
	 171:reg_data<=24'h548cb8;
	 172:reg_data<=24'h548dcd;
	 173:reg_data<=24'h548edd;
	 174:reg_data<=24'h548fea;
	 175:reg_data<=24'h54901d;// color matrix   ɫ�ʾ���
	 176:reg_data<=24'h53811e;// CMX1 for Y
	 177:reg_data<=24'h53825b;// CMX2 for Y
	 178:reg_data<=24'h538308;// CMX3 for Y
	 179:reg_data<=24'h53840a;// CMX4 for U
	 180:reg_data<=24'h53857e;// CMX5 for U
	 181:reg_data<=24'h538688;// CMX6 for U
	 182:reg_data<=24'h53877c;// CMX7 for V
	 183:reg_data<=24'h53886c;// CMX8 for V
	 184:reg_data<=24'h538910;// CMX9 for V
	 185:reg_data<=24'h538a01;// sign[9]
	 186:reg_data<=24'h538b98; // sign[8:1] // UV adjust   UVɫ�ʱ��Ͷȵ���
	 187:reg_data<=24'h558006;// saturation on, bit[1]
	 188:reg_data<=24'h558340;
	 189:reg_data<=24'h558410;
	 190:reg_data<=24'h558910;
	 191:reg_data<=24'h558a00;
	 192:reg_data<=24'h558bf8;
	 193:reg_data<=24'h501d40;// enable manual offset of contrast// CIP  �񻯺ͽ��� 
	 194:reg_data<=24'h530008;// CIP sharpen MT threshold 1
	 195:reg_data<=24'h530130;// CIP sharpen MT threshold 2
	 196:reg_data<=24'h530210;// CIP sharpen MT offset 1
	 197:reg_data<=24'h530300;// CIP sharpen MT offset 2
	 198:reg_data<=24'h530408;// CIP DNS threshold 1
	 199:reg_data<=24'h530530;// CIP DNS threshold 2
	 200:reg_data<=24'h530608;// CIP DNS offset 1
	 201:reg_data<=24'h530716;// CIP DNS offset 2 
	 202:reg_data<=24'h530908;// CIP sharpen TH threshold 1
	 203:reg_data<=24'h530a30;// CIP sharpen TH threshold 2
	 204:reg_data<=24'h530b04;// CIP sharpen TH offset 1
	 205:reg_data<=24'h530c06;// CIP sharpen TH offset 2
	 206:reg_data<=24'h502500;
	 207:reg_data<=24'h300802; // wake up from standby, bit[6]
	 //640x480 30֡/��, night mode 5fps, input clock =24Mhz, PCLK =56Mhz
	 208:reg_data<=24'h303511;// PLL 11
	 209:reg_data<=24'h303646;// PLL
	 210:reg_data<=24'h3c0708;// light meter 1 threshold [7:0]
	 211:reg_data<=24'h382041;// Sensor flip off, ISP flip on
	 212:reg_data<=24'h382100;// Sensor mirror on, ISP mirror on, H binning on
	 213:reg_data<=24'h381431;// X INC 
	 214:reg_data<=24'h381531;// Y INC
	 215:reg_data<=24'h380000;// HS: X address start high byte
	 216:reg_data<=24'h380100;// HS: X address start low byte
	 217:reg_data<=24'h380200;// VS: Y address start high byte
	 218:reg_data<=24'h380304;// VS: Y address start high byte 
	 219:reg_data<=24'h38040a;// HW (HE)         
	 220:reg_data<=24'h38053f;// HW (HE)
	 221:reg_data<=24'h380607;// VH (VE)         
	 222:reg_data<=24'h38079b;// VH (VE)      
	 223:reg_data<=24'h380803;// DVPHO  
	 224:reg_data<=24'h380920;// DVPHO
	 225:reg_data<=24'h380a02;// DVPVO
	 226:reg_data<=24'h380b58;// DVPVO
	 227:reg_data<=24'h380c07;// HTS            //Total horizontal size 1896 07 68
	 228:reg_data<=24'h380d68;// HTS
	 229:reg_data<=24'h380e03;// VTS            //total vertical size 984  03 d8
	 230:reg_data<=24'h380fd8;// VTS 
	 231:reg_data<=24'h381306;// Timing Voffset 06
	 232:reg_data<=24'h361800;
	 233:reg_data<=24'h361229;
	 234:reg_data<=24'h370952;
	 235:reg_data<=24'h370c03; 
	 236:reg_data<=24'h3a0217;// 60Hz max exposure, night mode 5fps
	 237:reg_data<=24'h3a0310;// 60Hz max exposure // banding filters are calculated automatically in camera driver
	 238:reg_data<=24'h3a1417;// 50Hz max exposure, night mode 5fps
	 239:reg_data<=24'h3a1510;// 50Hz max exposure     
	 240:reg_data<=24'h400402;// BLC 2 lines 
	 241:reg_data<=24'h30021c;// reset JFIFO, SFIFO, JPEG
	 242:reg_data<=24'h3006c3;// disable clock of JPEG2x, JPEG
	 243:reg_data<=24'h471303;// JPEG mode 3
	 244:reg_data<=24'h440704;// Quantization scale 
	 245:reg_data<=24'h460b35;
	 246:reg_data<=24'h460c22;
	 247:reg_data<=24'h483722; // DVP CLK divider
	 248:reg_data<=24'h382402; // DVP CLK divider 
	 249:reg_data<=24'h5001a3; // SDE on, scale on, UV average off, color matrix on, AWB on
	 250:reg_data<=24'h350300; // AEC/AGC on 
	 300:reg_data<=24'h301602; //Strobe output enable
	 301:reg_data<=24'h3b070a; //FREX strobe mode1	
//	 //strobe flash and frame exposure 	 
	 302:reg_data<=24'h3b0083;              //STROBE CTRL: strobe request ON, Strobe mode: LED3 
	 
	 default:reg_data<=24'h000000;
    endcase      
end	 
endmodule
module signalrl(
    input clk,
    input rst,
    input  [19:0]middle_pixel_count,
    input  [19:0]left_pixel_count,
    input  [19:0]right_pixel_count,
    output reg [1:0] lr
);
       always @(posedge clk or posedge rst) begin
        if (rst)
            lr <= 2'b00; 
        else
        if (right_pixel_count  > left_pixel_count + 20'd1000 )
            lr <= 2'b01;
        else if (left_pixel_count > right_pixel_count + 20'd1000 )
            lr <= 2'b10;
        else
            lr <= 2'b11;
    end
endmodule
module vga (
    input clk25,
    output reg [3:0] vga_red,
    output reg [3:0] vga_green,
    output reg [3:0] vga_blue,
    output reg vga_hsync,
    output reg vga_vsync,
    output  [17:0] frame_addr,
    input [11:0] frame_pixel,
    output reg [19:0] left_pixel_count,
    output reg [19:0] middle_pixel_count,
    output reg [19:0] right_pixel_count
);

// Timing constants
parameter hRez = 640+160;
parameter hStartSync = 640+16+160;
parameter hEndSync = 640+16+96+160;
parameter hMaxCount = 800+160;

parameter vRez = 480;
parameter vStartSync = 480+10;
parameter vEndSync = 480+10+2;
parameter vMaxCount = 480+10+2+33;

parameter hsync_active = 1'b0;
parameter vsync_active = 1'b0;

reg [9:0] hCounter = 10'b0;
reg [9:0] vCounter = 10'b0;
reg [18:0] address = 19'b0;
reg blank = 1'b1;

reg [19:0] left_count = 20'b0;
reg [19:0] middle_count = 20'b0;
reg [19:0] right_count = 20'b0;

assign frame_addr = address[18:1];

always @(posedge clk25) begin
    // Count the lines and rows
    if (hCounter == hMaxCount-1) begin
        hCounter <= 10'b0;
        if (vCounter == vMaxCount-1) begin
            vCounter <= 10'b0;
            
            // Output the pixel counts at the end of a frame
            left_pixel_count <= left_count;
            middle_pixel_count <= middle_count;
            right_pixel_count <= right_count;
            
            // Reset the counts for the next frame
            left_count <= 20'b0;
            middle_count <= 20'b0;
            right_count <= 20'b0;
        end else begin
            vCounter <= vCounter + 1;
        end
    end else begin
        hCounter <= hCounter + 1;
    end

    if (blank == 1'b0) begin
        vga_red <= frame_pixel[11:8];
        vga_green <= frame_pixel[7:4];
        vga_blue <= frame_pixel[3:0];
        
        // Count pixels in the three sections
        if (hCounter < hRez *1/3 ) begin
            if (vga_green - 4'b0011 > vga_red && vga_green - 4'b0011 > vga_blue && vga_green > 4'b0101)
                begin
                    left_count <= left_count + 1;
                    vga_red <= 4'b0;
                    vga_green <= 4'b0;
                    vga_blue <= 4'b0;
                end

        end else if (hCounter < hRez*2/3) begin
            if (vga_green - 4'b0011 > vga_red && vga_green - 4'b0011 > vga_blue && vga_green > 4'b0101)
               begin
                    middle_count <= middle_count + 1;
                    vga_red <= 4'b0;
                    vga_green <= 4'b0;
                    vga_blue <= 4'b0;
                end
        end else begin
            if (vga_green - 4'b0011 > vga_red && vga_green - 4'b0011 > vga_blue && vga_green > 4'b0101)
                begin
                    right_count <= right_count + 1;
                    vga_red <= 4'b0;
                    vga_green <= 4'b0;
                    vga_blue <= 4'b0;
                end
        end
    end else begin
        vga_red <= 4'b0;
        vga_green <= 4'b0;
        vga_blue <= 4'b0;
    end

    if (vCounter >= vRez) begin
        address <= 19'b0;
        blank <= 1'b1;
    end else begin
        if (hCounter < hRez) begin
            blank <= 1'b0;
            address <= address + 1;
        end else begin
            blank <= 1'b1;
        end
    end

    // hSync pulse?
    if (hCounter >= hStartSync && hCounter <= hEndSync) begin
        vga_hsync <= hsync_active;
    end else begin
        vga_hsync <= ~hsync_active;
    end

    // vSync pulse?
    if (vCounter >= vStartSync && vCounter < vEndSync) begin
        vga_vsync <= vsync_active;
    end else begin
        vga_vsync <= ~vsync_active;
    end
end



endmodule
//camera power on timing requirement
module power_on_delay(clk_50m,reset_n,camera1_rstn,camera_pwnd,initial_en);                  
input clk_50m;
input reset_n;
output camera1_rstn;
output camera_pwnd;
output initial_en;
reg [18:0]cnt1;
reg [15:0]cnt2;
reg [19:0]cnt3;
reg initial_en;
reg camera_rstn_reg;
reg camera_pwnd_reg;

assign camera1_rstn=camera_rstn_reg;
assign camera2_rstn=camera_rstn_reg;
assign camera_pwnd=camera_pwnd_reg;

//5ms
always@(posedge clk_50m)
begin
  if(reset_n==1'b0) begin
	    cnt1<=0;
		 camera_pwnd_reg<=1'b1;  
  end
  else if(cnt1<18'd40000) begin
       cnt1<=cnt1+1'b1;
       camera_pwnd_reg<=1'b1;
  end
  else
     camera_pwnd_reg<=1'b0;         
end

//1.3ms
always@(posedge clk_50m)
begin
  if(camera_pwnd_reg==1)  begin
	    cnt2<=0;
		 camera_rstn_reg<=1'b0;  
  end
  else if(cnt2<16'hffff) begin
       cnt2<=cnt2+1'b1;
       camera_rstn_reg<=1'b0;
  end
  else
     camera_rstn_reg<=1'b1;         
end

//21ms
always@(posedge clk_50m)
begin

  if(camera_rstn_reg==0) begin
         cnt3<=0;
         initial_en<=1'b0;
  end
  else if(cnt3<20'hfffff) begin
        cnt3<=cnt3+1'b1;
        initial_en<=1'b0;
  end
  else
       initial_en<=1'b1;    
end
endmodule
module car_run_or_stop (
    input [19:0] right_pixel_count,
    input [19:0] middle_pixel_count,
    input [19:0] left_pixel_count,
    input clk,
    input rst,
    output reg  [1:0] speed
);
 wire [21:0] total_pixel_count;
    assign  total_pixel_count[21:0] = {1'b0,right_pixel_count }+ {1'b0,middle_pixel_count} + {1'b0,left_pixel_count};
    always @(posedge clk or posedge rst) begin
        if (rst)
            speed <= 2'b00; 
        else if (total_pixel_count > 22'd800000)
            speed <= 2'b00;
        else if (total_pixel_count > 22'd500000)
            speed <= 2'b00;
        else if (total_pixel_count > 22'd100000)
            speed <= 2'b01;
        else if (total_pixel_count > 22'd50000)
            speed <= 2'b01;
        else if (total_pixel_count > 22'd10000)
            speed <= 2'b10;
        else if (total_pixel_count > 22'd1000)
            speed <= 2'b11;
        else if (total_pixel_count > 22'd500)
            speed <= 2'b11;
        else if (total_pixel_count > 22'd100)
            speed <= 2'b11;
        else
            speed <= 2'b00;
    end
endmodule