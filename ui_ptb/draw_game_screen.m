function draw_game_screen(ui, layout, state, transient_ui, config)
%DRAW_GAME_SCREEN 绘制对局界面：棋盘、棋子、状态提示文字。

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);

% 键盘模式下的当前选中格高亮
if isfield(transient_ui, 'selected_cell') && ~isempty(transient_ui.selected_cell)
    sel = transient_ui.selected_cell;
    if numel(sel) == 2
        r = sel(1);
        c = sel(2);
        if r >= 1 && r <= size(layout.cell_rects, 1) && c >= 1 && c <= size(layout.cell_rects, 2)
            rect = squeeze(layout.cell_rects(r, c, :))';
            Screen('FrameRect', ui.win, ui.colors.highlight, rect, 4);
        end
    end
end

draw_pieces(ui, layout, state);

% ---- 决定状态栏文字 ----
status_text = '';

% 1) 来自调用方的临时文字
if isfield(transient_ui, 'status_text')
    status_text = transient_ui.status_text;
end

% 2) 非法提示期间覆盖
if isfield(transient_ui, 'illegal_until') && GetSecs() <= transient_ui.illegal_until
    status_text = config.ui.illegal_text;
end

% 3) 兜底：显示当前轮次
if isempty(status_text)
    if state.current_player == 1
        status_text = config.ui.turn_black_text;
    else
        status_text = config.ui.turn_white_text;
    end
end

draw_text(ui.win, status_text, 'center', layout.status_y, ui.colors.text);
end
