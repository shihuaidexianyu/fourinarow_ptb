function draw_pieces(ui, layout, state)
%DRAW_PIECES 绘制所有棋子及胜利高亮（边框 + 连线）。

board = state.board;
rows = size(board, 1);
cols = size(board, 2);

radius = layout.piece_diameter_px / 2;

% ---- 绘制棋子 ----
for r = 1:rows
    for c = 1:cols
        val = board(r, c);
        if val == 0
            continue;
        end

        rect = squeeze(layout.cell_rects(r, c, :))';
        cx = (rect(1) + rect(3)) / 2;
        cy = (rect(2) + rect(4)) / 2;
        oval = [cx-radius, cy-radius, cx+radius, cy+radius];

        if val == 1   % 黑子：实心圆
            Screen('FillOval', ui.win, ui.colors.black, oval);
        else          % 白子：实心圆 + 深色描边
            Screen('FillOval', ui.win, ui.colors.white, oval);
            Screen('FrameOval', ui.win, ui.colors.grid, oval, 2);
        end
    end
end

% ---- 胜利高亮 ----
if ~isempty(state.winning_cells)
    % 边框高亮
    for i = 1:size(state.winning_cells, 1)
        rr = state.winning_cells(i, 1);
        cc = state.winning_cells(i, 2);
        rect = squeeze(layout.cell_rects(rr, cc, :))';
        Screen('FrameRect', ui.win, ui.colors.highlight, rect, 4);
    end

    % 中心连线高亮
    if ~isempty(state.winning_line.start_row)
        p0 = cell_center(layout, state.winning_line.start_row, state.winning_line.start_col);
        p1 = cell_center(layout, state.winning_line.end_row,   state.winning_line.end_col);
        Screen('DrawLine', ui.win, ui.colors.highlight, p0(1), p0(2), p1(1), p1(2), 6);
    end
end
end

function p = cell_center(layout, row, col)
%CELL_CENTER 返回指定格子的屏幕中心坐标 [x, y]。
rect = squeeze(layout.cell_rects(row, col, :))';
p = [(rect(1)+rect(3))/2, (rect(2)+rect(4))/2];
end
