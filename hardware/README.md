# 并口 trigger 支持

此目录从原四子棋实验资料的 `io64.zip` 中整理而来，保留原接口与独立发码脚本，
将压缩包内重复嵌套的目录整理为 `io64/`。游戏逻辑位于仓库根目录的
`app/`、`core/`、`players/` 和 `ui_ptb/`；游戏通过 `markers/send_marker.m`
调用这里的 `config_io`、`outp` 接口。

| 文件 | 用途 |
| --- | --- |
| `io64/test.m` | 独立发码联调：每秒发送一个码，依次为 1–100，保持 4 ms 后归零 |
| `io64/config_io.m` | 初始化 IO64，并将接口对象及状态写入全局变量 `cogent` |
| `io64/outp.m` | 向指定并口地址写入事件码 |
| `io64/inp.m` | 从指定并口地址读取数值 |
| `io64/io64.mexw64` | 原包中的 64 位 Windows MATLAB MEX 文件 |
| `io64/inpoutx64.dll` | 原包中的 Windows 并口支持 DLL |

## 独立联调

在已配置并口硬件、MATLAB 和 Psychtoolbox 的 Windows 实验机上：

1. 根据设备管理器中并口的实际 I/O 资源地址修改 `io64/test.m` 中的 `address`。
   原脚本保留的地址为 `hex2dec('0FF8')`。
2. 确保 IO64 所需的 DLL/驱动按实验机原有方式安装，并能被 MATLAB 加载。
   本仓库只保存原包中的文件，不执行安装。
3. 将 MATLAB 当前目录切换到仓库根目录，运行：

```matlab
addpath(fullfile(pwd, 'hardware', 'io64'));
run(fullfile(pwd, 'hardware', 'io64', 'test.m'));
```

脚本会检查 IO64 初始化是否成功；成功后每秒发送一个事件码，按 Ctrl+C 中断。
应在采集端核对收到的事件码及脉冲。

## 游戏中发码

在 `app/load_config.m` 中设置 `config.marker.enable = true`，并设置
`config.marker.parallel_port_address`、`config.marker.pulse_width_sec`。
`app/run_game.m` 会自动将此硬件目录与其他程序目录加入 MATLAB 路径。
游戏的事件名与码值映射保留在 `markers/marker_name_to_code.m`。

两个二进制文件与原压缩包内容保持一致；MATLAB 文件整理了缩进和注释。
尚未在实验机上运行游戏或验证实际并口输出。
