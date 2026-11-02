# 四子棋 PTB 实验

这是一个 MATLAB + Psychtoolbox 的四子棋实验程序。游戏流程、规则、界面和日志代码集中在 `run_game.m`；并口发码和独立 trigger 测试各有一个文件。

## 运行游戏

在 MATLAB 中将当前目录切换到仓库根目录，然后运行：

```matlab
run_game
```

需要 MATLAB、Psychtoolbox。游戏默认是 4×9 棋盘，人类使用方向键选择位置、按 Return 或空格落子，电脑随机落子。按 ESC 可退出。

## 程序流程

`run_game.m` 顶部是启动入口和实验设置。主流程依次显示开始页、每局注视点、对弈棋盘和结果页；每次落子都会更新棋盘、记录行为，并按设置发送 marker。该文件后面的本地函数实现规则、按键、绘图和日志，阅读时可以从上往下跟着流程看。

## 文件

- `run_game.m`：游戏入口、配置、主流程及所有游戏辅助函数。
- `send_marker.m`：初始化 IO64，并发送一个短并口脉冲；硬件不可用时会打印 fallback 事件。
- `test_trigger.m`：独立测试程序，每秒发送事件码 1–100，每个脉冲持续 4 ms。
- `hardware/io64/`：原有的 64 位 Windows IO64 MEX 文件和并口 DLL。

## 常用设置

在 `run_game.m` 开头的 `load_config` 函数中修改棋盘、人机方、试次数、按键、屏幕尺寸和时间参数。marker 默认关闭；要在游戏中发码，将 `config.marker.enable` 改为 `true`，并按实验机修改并口地址和脉冲宽度。电脑策略通过 `config.agent.player_fn` 设置，函数接收局面 `obs` 并返回包含 `row`、`col` 的动作。

每局日志保存到 `logs/`。该目录由程序自动创建，生成的 `.mat` 文件不会纳入 Git。

## 独立 trigger 测试

在运行前先按设备管理器中的实际地址修改 `test_trigger.m` 里的 `parallel_port_address`，然后在仓库根目录运行：

```matlab
test_trigger
```

它会依次发送 100 个脉冲，可按 Ctrl+C 中止。请在已连接采集设备的实验机上运行；本仓库只保存驱动文件，不执行驱动安装。
