function is_draw = check_draw(state)
%CHECK_DRAW 平局检测。
%   棋盘已满且游戏尚未因胜利结束 → 平局。

is_draw = ~any(state.board(:) == 0) && ~state.game_over;
end
