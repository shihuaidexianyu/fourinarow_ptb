function draw_result_screen(ui, layout, state, config)
%DRAW_RESULT_SCREEN 绘制结果页：棋盘（含高亮）、结果文字、自动进入下一局提示。

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);
draw_pieces(ui, layout, state);   % 含胜利高亮

% ---- 结果标题 ----
switch state.result
    case 'black_win'
        title = config.ui.black_win_text;
    case 'white_win'
        title = config.ui.white_win_text;
    case 'draw'
        title = config.ui.draw_text;
    otherwise
        title = config.ui.game_over_text;
end

draw_text(ui.win, title, 'center', layout.title_y, ui.colors.text);

hint = config.ui.result_hint_text;
draw_text(ui.win, hint, 'center', layout.status_y, ui.colors.text);
end
