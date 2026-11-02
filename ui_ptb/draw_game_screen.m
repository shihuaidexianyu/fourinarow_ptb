function draw_game_screen(ui, layout, state, transient_ui, config)
%DRAW_GAME_SCREEN 绘制对局界面：棋盘、棋子、状态提示文字。

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);

% 只有人类玩家操作时才显示光标。
if ~isempty(transient_ui.selected_cell)
    sel = transient_ui.selected_cell;
    rect = squeeze(layout.cell_rects(sel(1), sel(2), :))';
    Screen('FrameRect', ui.win, ui.colors.highlight, rect, 4);
end

draw_pieces(ui, layout, state);

% 非法落子提示暂时覆盖当前玩家提示。
status_text = transient_ui.status_text;
if GetSecs() <= transient_ui.illegal_until
    status_text = config.ui.illegal_text;
end

draw_text(ui.win, status_text, 'center', layout.status_y, ui.colors.text);
end
