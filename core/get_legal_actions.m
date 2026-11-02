function legal_actions = get_legal_actions(state)
%GET_LEGAL_ACTIONS 返回所有空格位置，格式固定为 N×2 矩阵 [row, col]。
%   约定：
%   - 第 1 列是 row，第 2 列是 col；
%   - N=0 时返回 0×2 空矩阵；
%   - 调用方（如 agent）应按该契约解析。

[r, c] = find(state.board == 0);
legal_actions = [r, c];
end
