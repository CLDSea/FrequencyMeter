module Freq_Meas_Gate
       #
       (
           // 预置闸门默认计数次数
           parameter [31: 0]CNT_MAX = 32'd50_000_000
       )
       (
           // 时钟信号
           input clk,
           // 复位信号
           input rst_n,
           
           // 测量复位
           input meas_rst,
           
           // 输入信号
           input sig,
           
           // 标准信号计数值
           output reg [31: 0]cnt_s,
           // 待测信号计数值
           output reg [31: 0]cnt_x,
           
           // 测量中断
           output reg irq
       );
       
// 等精度测频，设置预置闸门并根据待测信号调整实际闸门，分别对标准信号和待测信号进行计数
// 对于高频信号，测量时间约为预置闸门时间
// 对于低频信号，测量时间约为低频信号一周期的时间

// wire

// reg
reg sig_pre;

reg [31: 0]cnt;

reg [31: 0]cnt_s_temp;
reg [31: 0]cnt_x_temp;

// reg irq_temp;

// 标准信号和待测信号计数
always@(posedge clk or posedge meas_rst or negedge rst_n)
begin
	if (!rst_n || meas_rst)
	begin
		sig_pre <= 1'd1;
		
		cnt <= 1'd0;
		
		cnt_s_temp <= 1'd0;
		cnt_x_temp <= 1'd0;
		
		cnt_s <= 1'd0;
		cnt_x <= 1'd0;
		
		irq <= 1'd0;
	end
	else
	begin
		sig_pre <= sig;
		
		if (cnt != CNT_MAX)
		begin
			cnt <= cnt + 1'd1;
		end
		
		if (!sig_pre && sig)
		begin
			if (cnt == CNT_MAX)
			begin
				cnt <= 1'd0;
				
				cnt_s_temp <= 1'd1; // 标准信号计数
				cnt_x_temp <= 1'd1; // 待测信号计数
				
				cnt_s <= cnt_s_temp;
				cnt_x <= cnt_x_temp;
				
				irq <= 1'd1;
			end
			else
			begin
				cnt_x_temp <= cnt_x_temp + 1'd1; // 待测信号计数
				cnt_s_temp <= cnt_s_temp + 1'd1; // 标准信号计数
			end
		end
		else
		begin
			cnt_s_temp <= cnt_s_temp + 1'd1; // 标准信号计数
			
			irq <= 1'd0;
		end
	end
end

// // irq延迟一个周期
// always@(posedge clk or negedge rst_n)
// begin
// 	if (!rst_n)
// 	begin
// 		irq <= 1'd0;
// 	end
// 	else
// 	begin
// 		irq <= irq_temp;
// 	end
// end

endmodule
