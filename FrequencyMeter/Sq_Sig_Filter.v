module Sq_Sig_Filter
       (
           input clk_100M,
           input rst_n,

           input sq_sig,
           input [31: 0]win_len,

           output reg sq_sig_filter

       );

// 对带噪方波进行滤波，当波形连续出现win_len个1/0才视为波形出现1/0
// win_len为0不进行滤波
// win_len过小可能对噪声的抑制不充分
// win_len过大会导致高频信号跳变被当做噪声抑制
// win_len一般可选取2e+06 / freq

// wire

// reg
reg [31: 0]h_cnt; //连续1的个数
reg [31: 0]l_cnt; //连续0的个数

always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		h_cnt <= 1'd0;
		l_cnt <= 1'd0;

		sq_sig_filter <= 1'd0;
	end
	else
	begin
		if (h_cnt < win_len && sq_sig == 1'd1)
		begin
			h_cnt <= h_cnt + 1'd1;
		end
		else if (sq_sig == 1'd0)
		begin
			h_cnt <= 1'd0;
		end
		else if (h_cnt >= win_len) //连续win_len个1
		begin
			sq_sig_filter <= 1'd1;
		end

		if (l_cnt < win_len && sq_sig == 1'd0)
		begin
			l_cnt <= l_cnt + 1'd1;
		end
		else if (sq_sig == 1'd1)
		begin
			l_cnt <= 1'd0;
		end
		else if (l_cnt >= win_len) //连续win_len个0
		begin
			sq_sig_filter <= 1'd0;
		end
	end
end

endmodule
