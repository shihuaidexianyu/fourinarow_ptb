function ui = open_window_and_init_ui(config)
%OPEN_WINDOW_AND_INIT_UI 打开 PTB 窗口并初始化视觉样式。
%   设置文本渲染器、字体、颜色、按钮样式等。

PsychDefaultSetup(2);                                   % 归一化颜色范围为 0~1
KbName('UnifyKeyNames');                                % 统一跨平台键名映射
Screen('Preference', 'SkipSyncTests', double(logical(config.display.ptb_skip_sync_tests)));

if ~isempty(config.display.ptb_vbl_timestamping_mode)
    Screen('Preference', 'VBLTimestampingMode', config.display.ptb_vbl_timestamping_mode);
end

Screen('Preference', 'TextRenderer', 1);                % 启用高质量渲染器，支持 CJK

% ---- 颜色定义（归一化 RGB）----
bg       = [0.5, 0.5, 0.5];       % 背景色：中性灰
white    = [1, 1, 1];
black    = [0, 0, 0];
line_col = [0.08, 0.08, 0.08];    % 网格线：深灰
accent   = [1.0, 0.31, 0.0];      % 胜利高亮：橙红

% ---- 打开窗口 ----
screen_idx = config.display.screen_index;
if config.display.fullscreen
    [win, rect] = PsychImaging('OpenWindow', screen_idx, bg);
else
    [win, rect] = PsychImaging('OpenWindow', screen_idx, bg, [100, 100, 1200, 900]);
end

% ---- 光标：实验期间隐藏 ----
HideCursor;

% ---- 字体 ----
Screen('TextFont', win, 'Microsoft YaHei UI');   % 支持中文的字体
Screen('TextSize', win, 28);

% ---- 输出 UI 结构体 ----
ui.win = win;
ui.screen_rect = rect;
ui.colors.bg = bg;
ui.colors.white = white;
ui.colors.black = black;
ui.colors.grid = line_col;
ui.colors.highlight = accent;
ui.colors.text = [0.04, 0.04, 0.04];

ui.button_style.fill   = [0.82, 0.82, 0.82];    % 按钮填充色
ui.button_style.border = [0.2, 0.2, 0.2];        % 按钮边框色
ui.button_style.text   = [0.08, 0.08, 0.08];     % 按钮文字色

Priority(MaxPriority(win));   % 提升进程优先级以减少时序抖动
end
