function trial = log_move(trial, state, player, action, rt, response_time, stimulus_time)
%LOG_MOVE 追加一条合法动作记录。

entry.player        = player;
entry.row           = action.row;
entry.col           = action.col;
entry.rt            = rt;                % 反应时（秒）
entry.response_time = response_time;     % 动作被接受的绝对时刻
entry.stimulus_time = stimulus_time;     % 棋盘刷新完成的绝对时刻
entry.move_count    = state.move_count;
entry.board_after   = state.board;       % 落子后棋盘快照

if isempty(trial.moves)
    trial.moves = entry;
else
    trial.moves(end + 1) = entry;
end
end
