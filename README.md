# FrequencyMeter
本频率计设计基于FPGA。常用于电赛中的频率测量。

## 项目概述

**需要和有浮点运算功能、中断功能、定时器功能的MCU配合使用，计算freq并根据freq和irq信号控制win_len和meas_rst信号**

- 频率计，等精度测频，freq = cnt_x * 100e+06 / cnt_s

- 最高可测到700MHz

如果频率突然减小，可能需要很久才能从分频档切换到不分频档(约64个低频信号周期)

此时会很长一段时间没有irq信号，可以判断如果一段时间没有irq信号，则meas_rst(仅分频档rst)

- 调整win_len可以测带噪方波频率(win_len一般可取2e+06 / freq)

测带噪方波频率时，如果频率突然增大，可能高频信号跳变被当做噪声抑制

此时没有irq信号，可以判断如果一段时间没有irq信号，则重置win_len为0

## 文件说明

顶层文件为[Freq_Meas.v](FrequencyMeter/Freq_Meas.v)

模块连接方式见FrequencyMeter RTL.pdf

详见代码注释

## 联系方式

如有任何问题或建议，请联系2530626334@qq.com。
