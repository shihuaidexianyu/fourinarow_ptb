function draw_board(ui, layout)
%DRAW_BOARD 绘制棋盘网格线。

rect = layout.board_rect;
Screen('FrameRect', ui.win, ui.colors.grid, rect, 2);  % 外框

rows = size(layout.cell_rects, 1);
cols = size(layout.cell_rects, 2);

% 竖线
for c = 1:(cols-1)
    x = rect(1) + c * layout.cell_size_px;
    Screen('DrawLine', ui.win, ui.colors.grid, x, rect(2), x, rect(4), 2);
end
% 横线
for r = 1:(rows-1)
    y = rect(2) + r * layout.cell_size_px;
    Screen('DrawLine', ui.win, ui.colors.grid, rect(1), y, rect(3), y, 2);
end
end
