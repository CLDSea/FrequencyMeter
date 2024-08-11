module Freq_Meas_Gate
       #
       (
           parameter [31: 0]CNT_THRESH = 32'd10_000_000
       )
       (
           input clk_100M,
           input rst_n,

           // 测量复位
           input meas_rst,

           input sig,
           // 标准信号计数值
           output reg [31: 0]cnt_s,
           //待测信号计数值
           output reg [31: 0]cnt_x,
           //实际闸门
           output reg meas_gate

       );

// 等精度测频，设置预置闸门并根据待测信号调整实际闸门，分别对标准信号和待测信号进行计数
// 对于高频信号，测量时间约为预置闸门时间
// 对于低频信号，测量时间约为低频信号两周期的时间

// wire
wire preset_meas_gate; //预置闸门

// reg
reg[1: 0]state;

reg preset_meas_gate_pre;
reg sig_pre;

reg[31: 0]s; //标准信号实时计数值
reg[31: 0]x; //待测信号实时计数值

// 预置闸门默认计数次数为CNT_THRESH
Clk_Div #(CNT_THRESH * 101 / 100, CNT_THRESH)Clk_Div_inst
        (
            .clk(clk_100M) ,
            .rst_n(rst_n) ,
            .phase_rst(1'd0) ,
            .clk_div(preset_meas_gate) ,
            .cnt()
        );

always@(posedge clk_100M or posedge meas_rst or negedge rst_n)
begin
	if (!rst_n || meas_rst)
	begin
		state <= 1'd0;

		preset_meas_gate_pre <= 1'd0;
		sig_pre <= 1'd0;

		meas_gate <= 1'd0;

		s <= 1'd0;
		x <= 1'd0;

		cnt_s <= 1'd0;
		cnt_x <= 1'd0;
	end
	else
	begin
		preset_meas_gate_pre <= preset_meas_gate;
		sig_pre <= sig;

		case (state)
			//等待预置闸门上升沿
			2'd0:
			begin
				if (!preset_meas_gate_pre && preset_meas_gate)
				begin
					state <= 2'd1;
				end
			end
			//等待待测信号上升沿
			2'd1:
			begin
				if (!sig_pre && sig)
				begin
					s <= 1'd1;
					x <= 1'd1;

					meas_gate <= 1'd1;

					state <= 2'd2;
				end
			end
			//等待预置闸门下降沿
			2'd2:
			begin
				s <= s + 1'd1; //标准信号计数

				if (!sig_pre && sig)
				begin
					x <= x + 1'd1; //待测信号计数
				end

				if (preset_meas_gate_pre && !preset_meas_gate)
				begin
					state <= 2'd3;
				end
			end
			//等待待测信号上升沿
			2'd3:
			begin
				s <= s + 1'd1; //标准信号计数

				if (!sig_pre && sig)
				begin
					cnt_s <= s;
					cnt_x <= x;

					meas_gate <= 1'd0;

					state <= 2'd0;
				end
			end
			default:
				;
		endcase
	end
end

endmodule
