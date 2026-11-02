function [is_win, winning_cells, winning_line] = check_winner(state, action)
%CHECK_WINNER 围绕最新落子检查四个方向是否形成连线。
%   若连续长度 >= connect_n，返回整段连续棋子坐标。
%   若多个方向均满足，返回最长的一条。

board = state.board;
row0 = action.row;
col0 = action.col;
player = board(row0, col0);
connect_n = state.connect_n;

% 四个方向：水平、垂直、主对角线、副对角线
dirs = [0, 1; 1, 0; 1, 1; 1, -1];
best_cells = zeros(0, 2);

for i = 1:size(dirs, 1)
    dr = dirs(i, 1);
    dc = dirs(i, 2);

    % 向正、反两个方向延伸
    cells_pos = walk_direction(board, row0, col0, dr, dc, player);
    cells_neg = walk_direction(board, row0, col0, -dr, -dc, player);

    % 拼接成完整连线（去除重复的原点）
    cells_neg = flipud(cells_neg);
    cells = [cells_neg(1:end-1, :); cells_pos];

    if size(cells, 1) >= connect_n && size(cells, 1) > size(best_cells, 1)
        best_cells = cells;
    end
end

is_win = ~isempty(best_cells);
if is_win
    winning_cells = best_cells;
    winning_line = struct( ...
        'start_row', best_cells(1, 1), ...
        'start_col', best_cells(1, 2), ...
        'end_row', best_cells(end, 1), ...
        'end_col', best_cells(end, 2));
else
    winning_cells = zeros(0, 2);
    winning_line = struct('start_row', [], 'start_col', [], 'end_row', [], 'end_col', []);
end
end

function cells = walk_direction(board, row0, col0, dr, dc, player)
%WALK_DIRECTION 从 (row0,col0) 沿 (dr,dc) 方向收集同色棋子坐标。
rows = size(board, 1);
cols = size(board, 2);

cells = [row0, col0];
r = row0 + dr;
c = col0 + dc;
while r >= 1 && r <= rows && c >= 1 && c <= cols && board(r, c) == player
    cells = [cells; r, c]; %#ok<AGROW>
    r = r + dr;
    c = c + dc;
end
end
