function layout = compute_visual_layout(ui, config)
%COMPUTE_VISUAL_LAYOUT 根据视觉角度计算棋盘与按钮的像素布局。
%   流程：获取屏幕物理尺寸 → 视角换算 → 棋盘/按钮矩形 → 安全显示检查

screen_w_px = ui.screen_rect(3);
screen_h_px = ui.screen_rect(4);

% ---- 获取屏幕物理尺寸 ----
if config.display.use_manual_screen_size
    screen_w_cm = config.display.manual_screen_width_cm;
    screen_h_cm = config.display.manual_screen_height_cm;
else
    [screen_w_mm, screen_h_mm] = Screen('DisplaySize', config.display.screen_index);
    screen_w_cm = screen_w_mm / 10;
    screen_h_cm = screen_h_mm / 10;
end

if isempty(screen_w_cm) || isempty(screen_h_cm) || screen_w_cm <= 0 || screen_h_cm <= 0
    error('DisplayError:ScreenPhysicalSizeInvalid', ...
        'Invalid physical screen size: width=%.4fcm height=%.4fcm', screen_w_cm, screen_h_cm);
end

% ---- 像素密度（取较小值避免形变）----
px_per_cm_x = screen_w_px / screen_w_cm;
px_per_cm_y = screen_h_px / screen_h_cm;
px_per_cm = min(px_per_cm_x, px_per_cm_y);

% ---- 视角 → 像素 ----
cell_cm = deg2cm(config.display.cell_deg, config.display.viewing_distance_cm);
cell_px = cm2px(cell_cm, px_per_cm);
piece_diameter_px = max(6, round(config.display.piece_ratio * cell_px));

board_w_px = config.game.cols * cell_px;   % 棋盘总宽
board_h_px = config.game.rows * cell_px;   % 棋盘总高

% ---- UI 预留高度 ----
title_h  = 80;     % 标题区
status_h = 90;     % 状态文字区（含说明/提示）
margin_h = 90;     % 边距
reserved_h = title_h + status_h + margin_h;

% ---- 安全显示检查 ----
assert_display_fits(screen_w_px, screen_h_px, board_w_px, board_h_px, reserved_h, struct( ...
    'screen_w_cm', screen_w_cm, ...
    'screen_h_cm', screen_h_cm, ...
    'distance_cm', config.display.viewing_distance_cm, ...
    'cell_deg', config.display.cell_deg));

% ---- 棋盘居中 ----
board_left = round((screen_w_px - board_w_px) / 2);
board_top  = round((screen_h_px - board_h_px) / 2);
board_rect = [board_left, board_top, board_left + board_w_px, board_top + board_h_px];

% ---- 每个格子的屏幕矩形 ----
cell_rects = zeros(config.game.rows, config.game.cols, 4);
for r = 1:config.game.rows
    for c = 1:config.game.cols
        l = board_left + (c - 1) * cell_px;
        t = board_top  + (r - 1) * cell_px;
        cell_rects(r, c, :) = [l, t, l + cell_px, t + cell_px];
    end
end

% ---- 输出 ----
layout.screen_width_cm  = screen_w_cm;
layout.screen_height_cm = screen_h_cm;
layout.px_per_cm        = px_per_cm;
layout.cell_size_px     = cell_px;
layout.piece_diameter_px = piece_diameter_px;
layout.board_rect       = board_rect;
layout.cell_rects       = cell_rects;
layout.title_y          = board_rect(2) - 90;   % 标题 Y 坐标（棋盘上方）
layout.status_y         = board_rect(4) + 40;   % 状态文字 Y 坐标（棋盘下方）
end
