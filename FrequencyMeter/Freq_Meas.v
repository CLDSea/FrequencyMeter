module Freq_Meas
       #
       (
           parameter [31: 0]CNT_THRESH = 32'd10_000_000
       )
       (
           input clk_100M,
           input rst_n,

           // 测量复位
           input meas_rst,

           // 0-700MHz
           input sig_in,

           // 滤波窗口长度
           input [31: 0]win_len,

           // 标准信号计数值
           output reg [31: 0]cnt_s,
           // 待测信号计数值
           output reg [31: 0]cnt_x,

           //上升沿测量完成
           output reg irq,

           // 触发信号
           output reg sig_out
       );


// 频率计，等精度测频，freq = cnt_x * 100e+06 / cnt_s
// 最高可测到700MHz
// 如果频率突然减小，可能需要很久才能从分频档切换到不分频档(约64个低频信号周期)
// 此时会很长一段时间没有irq信号，可以判断如果一段时间没有irq信号，则meas_rst(仅分频档rst)

// 调整win_len可以测带噪方波频率
// 测带噪方波频率时，如果频率突然增大，可能高频信号跳变被当做噪声抑制
// 此时没有irq信号，可以判断如果一段时间没有irq信号，则重置win_len为0

// wire
wire sig_undiv_sync;
wire sig_div_sync;

wire sig_undiv_filter;
wire sig_div_filter;

wire [31: 0]cnt_s_undiv;
wire [31: 0]cnt_x_undiv;
wire meas_gate_undiv;

wire [31: 0]cnt_s_div;
wire [31: 0]cnt_x_div;
wire meas_gate_div;

// reg
reg [4: 0]cnt_div;
reg sig_div;

reg irq_reg;

// 32分频
// 需要对最高700MHz的信号进行分频，因此分频需要最简，cnt_div直接自增到溢出
always@(posedge sig_in)
begin
	if (cnt_div == 5'd31)
	begin
		cnt_div <= 1'd0;
	end
	else
	begin
		cnt_div <= cnt_div + 1;
	end
end
always@(posedge sig_in)
begin
	if (cnt_div == 1'd0)
	begin
		sig_div <= 1'd1;
	end
	else if (cnt_div == 5'd15)
	begin
		sig_div <= 1'd0;
	end
end

// 输入信号同步链
Sync_Chain Sync_Chain_inst
           (
               .clk_100M(clk_100M) ,
               .rst_n(rst_n) ,
               .sig(sig_in) ,
               .sig_sync(sig_undiv_sync)
           );

// 输入信号分频后同步链
Sync_Chain Sync_Chain_inst2
           (
               .clk_100M(clk_100M) ,
               .rst_n(rst_n) ,
               .sig(sig_div) ,
               .sig_sync(sig_div_sync)
           );

// 输入信号滤波
Sq_Sig_Filter Sq_Sig_Filter_inst
              (
                  .clk_100M(clk_100M) ,
                  .rst_n(rst_n) ,
                  .sq_sig(sig_undiv_sync) ,
                  .win_len(win_len) ,
                  .sq_sig_filter(sig_undiv_filter)
              );

// 输入信号分频后滤波
Sq_Sig_Filter Sq_Sig_Filter_inst2
              (
                  .clk_100M(clk_100M) ,
                  .rst_n(rst_n) ,
                  .sq_sig(sig_div_sync) ,
                  .win_len({win_len[26: 0], 5'd0}) ,
                  .sq_sig_filter(sig_div_filter)
              );

// 输入信号测频
Freq_Meas_Gate #(CNT_THRESH)Freq_Meas_Gate_inst
               (
                   .clk_100M(clk_100M) ,
                   .rst_n(rst_n) ,
		   .meas_rst(1'd0) ,
                   .sig(sig_undiv_filter) ,
                   .cnt_s(cnt_s_undiv) ,
                   .cnt_x(cnt_x_undiv) ,
                   .meas_gate(meas_gate_undiv)
               );

// 输入信号分频后测频
// 可以meas_rst
Freq_Meas_Gate #(CNT_THRESH)Freq_Meas_Gate_inst2
               (
                   .clk_100M(clk_100M) ,
                   .rst_n(rst_n) ,
                   .meas_rst(meas_rst) ,
                   .sig(sig_div_filter) ,
                   .cnt_s(cnt_s_div) ,
                   .cnt_x(cnt_x_div) ,
                   .meas_gate(meas_gate_div)
               );

// 25M以上使用32分频测频，以下使用默认测频
always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		cnt_s <= 1'd0;
		cnt_x <= 1'd0;

		irq_reg <= 1'd0;
		irq <= 1'd0;

		sig_out <= 1'd0;
	end
	else
	begin
		if (cnt_x_div > CNT_THRESH[31: 7]) //分频后的待测信号计数值大于CNT_THRESH / 4 / 32则视为高频信号
		begin
			cnt_s <= cnt_s_div;
			cnt_x <= {cnt_x_div[26: 0], 5'd0};

			irq_reg <= ~meas_gate_div;

			sig_out <= sig_div_filter;
		end
		else
		begin
			cnt_s <= cnt_s_undiv;
			cnt_x <= cnt_x_undiv;

			irq_reg <= ~meas_gate_undiv;

			sig_out <= sig_undiv_filter;
		end

		irq <= irq_reg;
	end
end

endmodule
