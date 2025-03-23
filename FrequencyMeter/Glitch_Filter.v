module Glitch_Filter
       (
           //时钟信号
           input clk,
           //复位信号
           input rst_n,
           
           //输入信号
           input sig,
           
           //窗长
           input [31: 0]win_len,
           
           //滤波信号
           output reg sig_filter
       );
       
// 对带噪脉冲波进行滤波，当连续出现win_len个1/0才视为出现1/0
// win_len为0不进行滤波
// win_len偏小可能导致滤波不充分
// win_len偏大可能导致高频信号被滤除
// 经验取值: win_len = (clk_freq / 50) / freq

// wire

// reg
reg [31: 0]cnt_h; //连续1的个数
reg [31: 0]cnt_l; //连续0的个数

always@(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		cnt_h <= 1'd0;
		cnt_l <= 1'd0;
		
		sig_filter <= 1'd0;
	end
	else
	begin
		if (sig)
		begin
			cnt_l <= 1'd0;
			
			if (cnt_h == win_len) //连续win_len个1
			begin
				sig_filter <= 1'd1;
			end
			else
			begin
				cnt_h <= cnt_h + 1'd1;
			end
		end
		else
		begin
			cnt_h <= 1'd0;
			
			if (cnt_l == win_len) //连续win_len个0
			begin
				sig_filter <= 1'd0;
			end
			else
			begin
				cnt_l <= cnt_l + 1'd1;
			end
		end
	end
end

endmodule
