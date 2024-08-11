module Sync_Chain
       (
           input clk_100M,
           input rst_n,

           input sig,

           output reg sig_sync
       );

// 同步链，锁存输入两次，防止亚稳态
// 多用于随机产生的异步信号

// wire

// reg
reg sig_reg;

always@(posedge clk_100M or negedge rst_n)
begin
	if (!rst_n)
	begin
		sig_reg <= 1'd0;
		sig_sync <= 1'd0;
	end
	else
	begin
		sig_reg <= sig;
		sig_sync <= sig_reg;
	end
end

endmodule
