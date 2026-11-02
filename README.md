# 四子棋实验（MATLAB + Psychtoolbox）

一个用于行为/神经实验场景的四子棋任务框架（默认 `4×9` 棋盘，human vs random agent）。

项目目标是：**可快速联调、配置集中、流程稳定、日志可追溯**。

---

## 功能概览

- 固定 trial 数自动运行（每次 `run_game` 连续完成 `num_trials` 局）
- 人类键盘操作 + agent 自动落子
- 完整实验流程界面（开始页 / 注视点 / 对局页 / 结果页）
- 非法按键/非法落子处理
- Marker 统一发射接口（支持并口发码，失败自动降级打印）
- 每局日志保存为 `.mat`，包含行为与 marker 事件
- 参数集中在 `app/load_config.m`（包括按键 keycode）

---

## 环境要求

- MATLAB（建议 R2021a+）
- Psychtoolbox（建议 3.0.19+）
- Windows 实验机（当前项目在 Windows 环境开发与使用）

---

## 快速开始

1. 打开 MATLAB，并将当前目录切换到项目根目录。
2. 运行：

```matlab
addpath('app');
run_game;
```

程序会自动：

- 把项目子目录加入 MATLAB 路径
- 加载 `app/load_config.m`
- 进入主循环 `app/main_loop.m`

---

## 按键配置（统一在 config）

按键不再通过额外解析文件转换，**直接在 `app/load_config.m` 中硬编码 keycode**：

```matlab
KbName('UnifyKeyNames');
config.controls.up = KbName('UpArrow');
config.controls.down = KbName('DownArrow');
config.controls.left = KbName('LeftArrow');
config.controls.right = KbName('RightArrow');
config.controls.confirm = unique([KbName('Return'), KbName('space')]);
config.controls.abort = KbName('ESCAPE');
```

说明：

- `confirm` 可以配置多个键（如 `Return + space`）
- `abort` 建议保留 `ESCAPE`

---

## 按键联调工具

提供独立联调程序：`app/debug_key_name_probe.m`

在 MATLAB 运行：

```matlab
debug_key_name_probe
```

行为：

- 每次按键按下沿都会打印 PTB 键名
- 支持同时按多个键
- 按 `ESC` 退出

适合在正式实验前快速核对键盘映射是否与预期一致。

---

## 主要配置项

集中于 `app/load_config.m`：

- `config.game.*`：棋盘尺寸、先手、人机方、试次数
- `config.display.*`：视角、观察距离、屏幕选择、全屏、PTB 时序参数
- `config.ui.*`：文本提示、结果页停留时长、注视点参数
- `config.timing.*`：注视点时长、ITI、按键释放保护
- `config.controls.*`：键盘 keycode
- `config.marker.*`：是否启用 marker、并口地址、脉冲宽度、回调
- `config.agent.*`：agent 函数入口与延时
- `config.logging.*`：日志保存开关与目录

---

## Marker 机制

- 事件名与事件码映射：`markers/marker_name_to_code.m`
- 统一发射入口：`markers/emit_marker.m`
- 默认并口发送：`markers/send_marker.m`
- 并口接口与独立 trigger 联调程序：`hardware/io64/`（见 [硬件说明](hardware/README.md)）

原有配置默认 `config.marker.enable = false`。需要在游戏中发码时，在
`app/load_config.m` 中启用 marker，并根据实验机设置并口地址和脉冲宽度。
独立联调程序为 `hardware/io64/test.m`；它不启动游戏，按原脚本每秒发送
一个递增事件码（1–100），每次保持 4 ms 后归零。

`send_marker.m` 的默认流程：

1. `outp(address, code)`
2. 保持 `pulse_width_sec`
3. `outp(address, 0)` 复位

如果硬件接口初始化失败，会自动降级为控制台打印 marker，避免主流程中断。

---

## 日志输出

- 每局 trial 都会初始化并持续记录行为/事件
- 结束后通过 `logging/save_trial_log.m` 写入 `.mat`
- 默认保存目录：`logs/`（运行时转为项目根目录下绝对路径）

---

## 目录结构（当前版本）

```text
fourinarow_ptb/ (repository root)
  app/
    run_game.m
    main_loop.m
    load_config.m
    debug_key_name_probe.m

  core/
    init_game.m
    get_legal_actions.m
    is_valid_action.m
    apply_action.m
    check_winner.m
    check_draw.m

  players/
    human_keyboard_player_play.m
    random_agent_play.m

  ui_ptb/
    open_window_and_init_ui.m
    compute_visual_layout.m
    draw_start_screen.m
    draw_fixation_screen.m
    draw_game_screen.m
    draw_result_screen.m
    draw_board.m
    draw_pieces.m
    draw_text.m

  markers/
    marker_name_to_code.m
    emit_marker.m
    send_marker.m

  hardware/
    README.md
    io64/
      test.m
      config_io.m
      inp.m
      outp.m
      io64.mexw64
      inpoutx64.dll

  logging/
    init_trial_log.m
    log_move.m
    log_illegal_click.m
    log_marker_event.m
    finalize_trial_log.m
    next_experiment_id.m
    save_trial_log.m

  utils/
    deg2cm.m
    cm2px.m
    assert_display_fits.m
```
