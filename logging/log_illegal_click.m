function trial = log_illegal_click(trial, player, row, col, t, move_count)
%LOG_ILLEGAL_CLICK 追加一条非法点击记录。

entry.player     = player;
entry.row        = row;
entry.col        = col;
entry.time       = t;            % 非法点击发生的绝对时刻
entry.move_count = move_count;   % 当前已完成的合法落子数

if isempty(trial.illegal_clicks)
    trial.illegal_clicks = entry;
else
    trial.illegal_clicks(end + 1) = entry;
end

trial.illegal_click_count = trial.illegal_click_count + 1;
end
