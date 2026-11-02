function is_valid = is_valid_action(state, action)
%IS_VALID_ACTION 检查动作合法性。
%   必须满足：游戏未结束、行列范围合法、目标格为空。

if state.game_over
    is_valid = false;
    return;
end

if ~isstruct(action) || ~isfield(action, 'row') || ~isfield(action, 'col')
    is_valid = false;
    return;
end

row = action.row;
col = action.col;

% 必须为标量整数
if ~isscalar(row) || ~isscalar(col) || row ~= floor(row) || col ~= floor(col)
    is_valid = false;
    return;
end

% 范围检查
rows = size(state.board, 1);
cols = size(state.board, 2);
if row < 1 || row > rows || col < 1 || col > cols
    is_valid = false;
    return;
end

% 目标格必须为空
is_valid = (state.board(row, col) == 0);
end
