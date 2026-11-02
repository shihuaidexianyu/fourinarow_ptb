function [action, meta, cursor] = human_keyboard_player_play(obs, controls, runtime_context)
%HUMAN_KEYBOARD_PLAYER_PLAY 方向键移动光标，确认键落子，ESC 中止。
%   返回值：
%     action - 落子位置；按 ESC 或确认已占用格时为空
%     meta   - 说明空动作是中止还是非法输入
%     cursor - 当前光标位置

ui = runtime_context.ui;
layout = runtime_context.layout;
state = runtime_context.state;
transient_ui = runtime_context.transient_ui;
config = runtime_context.config;

action = [];
meta = struct('aborted', false, 'is_illegal', false);
cursor = runtime_context.cursor;

[~, ~, last_key_code] = KbCheck(-1);

while true
    [is_down, key_time, key_code] = KbCheck(-1);
    if ~is_down
        last_key_code = false(size(key_code));
        WaitSecs(0.005);
        continue;
    end

    pressed_edge = key_code & ~last_key_code; % 只处理新按下的键，按住不会重复移动

    % ESC 中止
    if any(pressed_edge(controls.abort))
        meta.aborted = true;
        return;
    end

    moved = false;

    % 确认落子
    if any(pressed_edge(controls.confirm))
        row = cursor.row;
        col = cursor.col;
        if obs.board(row, col) == 0
            action.row = row;
            action.col = col;
        else
            meta.is_illegal = true;
            meta.illegal_row = row;
            meta.illegal_col = col;
            meta.illegal_time = key_time;
        end
        return;
    end

    % 光标移动
    if any(pressed_edge(controls.up))
        cursor.row = max(1, cursor.row - 1);
        moved = true;
    elseif any(pressed_edge(controls.down))
        cursor.row = min(size(obs.board, 1), cursor.row + 1);
        moved = true;
    elseif any(pressed_edge(controls.left))
        cursor.col = max(1, cursor.col - 1);
        moved = true;
    elseif any(pressed_edge(controls.right))
        cursor.col = min(size(obs.board, 2), cursor.col + 1);
        moved = true;
    end

    if moved
        transient_ui.selected_cell = [cursor.row, cursor.col];
        draw_game_screen(ui, layout, state, transient_ui, config);
        Screen('Flip', ui.win);
    end
    last_key_code = key_code;
end
end
