module Freq_Meas
       #
       (
           // 时钟频率
           parameter [31: 0]CLK_FREQ = 32'd100_000_000,
           // 测量次数
           parameter [31: 0]MEAS_TIMES = 32'd2
       )
       (
           //时钟信号
           input clk,
           //复位信号
           input rst_n,
           
           // 测量复位
           input meas_rst,
           
           //输入信号
           input sig,
           
           //窗长
           input [31: 0]win_len,
           
           // 标准信号计数值
           output reg [31: 0]cnt_s,
           // 待测信号计数值
           output reg [31: 0]cnt_x,
           
           // 测量中断
           output reg irq,
           
           // 同步信号
           output reg sig_sync
       );
       
// 频率计，等精度测频，freq = cnt_x * CLK_FREQ / cnt_s
// 最高可测到700MHz？
// 如果频率突然减小，可能需要很久才能从分频档切换到不分频档(约32个低频信号周期)
// 此时一段时间没有irq信号，可以meas_rst(仅分频档rst)

// 调整win_len可以测带噪脉冲波频率
// 经验取值: win_len = (CLK_FREQ / 50) / freq
// 测带噪脉冲波频率时，如果频率突然增大，可能导致高频信号被滤除
// 此时没有irq信号，需要重置win_len为0

// 预置闸门默认计数次数
localparam [31: 0]CNT_MAX = (CLK_FREQ + MEAS_TIMES / 2 ) / MEAS_TIMES;

// wire
wire sig_undiv_sync;
wire sig_undiv_filter;

wire [31: 0]cnt_s_undiv;
wire [31: 0]cnt_x_undiv;

wire irq_undiv;

wire sig_div_sync;
wire sig_div_filter;

wire [31: 0]cnt_s_div;
wire [31: 0]cnt_x_div;

wire irq_div;

// reg
reg [4: 0]sig_div;

reg irq_temp;

// 32分频
genvar i;

generate
	for (i = 0;i <= 4;i <= i + 1'd1)
	begin
		if (i == 1'd0)
		begin
			always@(posedge sig)
			begin
				sig_div[i] <= ~sig_div[i];
			end
		end
		else
		begin
			always@(posedge sig_div[i - 1])
			begin
				sig_div[i] <= ~sig_div[i];
			end
		end
	end
endgenerate

// 输入信号同步链
Sync_Chain Sync_Chain_inst
           (
               .clk(clk) ,
               .rst_n(rst_n) ,
               .sig(sig) ,
               .sig_sync(sig_undiv_sync)
           );
// 分频信号同步链
Sync_Chain Sync_Chain_inst2
           (
               .clk(clk) ,
               .rst_n(rst_n) ,
               .sig(sig_div[4]) ,
               .sig_sync(sig_div_sync)
           );
           
// 输入信号滤波
Glitch_Filter Glitch_Filter_inst
              (
                  .clk(clk) ,
                  .rst_n(rst_n) ,
                  .sig(sig_undiv_sync) ,
                  .win_len(win_len) ,
                  .sig_filter(sig_undiv_filter)
              );
// 分频信号滤波
Glitch_Filter Glitch_Filter_inst2
              (
                  .clk(clk) ,
                  .rst_n(rst_n) ,
                  .sig(sig_div_sync) ,
                  .win_len({win_len[26: 0], 5'd0}) ,
                  .sig_filter(sig_div_filter)
              );
              
// 输入信号测频
Freq_Meas_Gate #(CNT_MAX)Freq_Meas_Gate_inst
               (
                   .clk(clk) ,
                   .rst_n(rst_n) ,
                   .meas_rst(1'd0) ,
                   .sig(sig_undiv_filter) ,
                   .cnt_s(cnt_s_undiv) ,
                   .cnt_x(cnt_x_undiv) ,
                   .irq(irq_undiv)
               );
// 分频信号测频
// 可以meas_rst//？
Freq_Meas_Gate #(CNT_MAX)Freq_Meas_Gate_inst2
               (
                   .clk(clk) ,
                   .rst_n(rst_n) ,
                   .meas_rst(meas_rst) ,
                   .sig(sig_div_filter) ,
                   .cnt_s(cnt_s_div) ,
                   .cnt_x(cnt_x_div) ,
                   .irq(irq_div)
               );
               
// 高频信号使用分频信号测频，低频信号使用输入信号测频
always@(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		cnt_s <= 1'd0;
		cnt_x <= 1'd0;
		
		irq_temp <= 1'd0;
		
		sig_sync <= 1'd0;
	end
	else
	begin
		if (cnt_x_div > CNT_MAX[31: 7]) //cnt_x_div > CNT_MAX / 4 / 32则视为高频信号
		begin
			cnt_s <= cnt_s_div;
			cnt_x <= {cnt_x_div[26: 0], 5'd0};
			
			irq_temp <= irq_div;
			
			sig_sync <= sig_div_filter;
		end
		else
		begin
			cnt_s <= cnt_s_undiv;
			cnt_x <= cnt_x_undiv;
			
			irq_temp <= irq_undiv;
			
			sig_sync <= sig_undiv_filter;
		end
	end
end

// irq延迟一个周期
always@(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		irq <= 1'd0;
	end
	else
	begin
		irq <= irq_temp;
	end
end

endmodule



