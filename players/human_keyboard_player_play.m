function [action, meta, cursor] = human_keyboard_player_play(obs, player_config, runtime_context)
%HUMAN_KEYBOARD_PLAYER_PLAY 人类键盘输入适配器。
%   方向键移动选中格，确认键提交落子，ESC 中止。
%   返回值：
%     action  - 合法动作 struct(.row,.col)，非法或中止时为 []
%     meta    - .aborted=true 表示 ESC 中止；.is_illegal=true 表示确认到已占用格
%     cursor  - 本次输入结束后的光标位置 struct('row',r,'col',c)

ui = runtime_context.ui;
layout = runtime_context.layout;
state = runtime_context.state;
transient_ui = runtime_context.transient_ui;
config = runtime_context.config;

action = [];
meta = struct('aborted', false, 'is_illegal', false);
cursor = runtime_context.cursor;

keycodes = build_keycode_map(player_config);
[~, ~, last_key_code] = KbCheck(-1);

while true
    [is_down, key_time, key_code] = KbCheck(-1);
    if ~is_down
        last_key_code = false(size(key_code));
        WaitSecs(0.005);
        continue;
    end

    pressed_edge = key_code & ~last_key_code;

    % ESC 中止
    if any(pressed_edge(keycodes.abort))
        meta.aborted = true;
        return;
    end

    moved = false;

    % 确认落子
    if any(pressed_edge(keycodes.confirm))
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
    if any(pressed_edge(keycodes.up))
        cursor.row = max(1, cursor.row - 1);
        moved = true;
    elseif any(pressed_edge(keycodes.down))
        cursor.row = min(size(obs.board, 1), cursor.row + 1);
        moved = true;
    elseif any(pressed_edge(keycodes.left))
        cursor.col = max(1, cursor.col - 1);
        moved = true;
    elseif any(pressed_edge(keycodes.right))
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

function keycodes = build_keycode_map(controls)
%BUILD_KEYCODE_MAP 从配置读取 PTB 键码索引数组。
keycodes = struct();
keycodes.up = controls.up;
keycodes.down = controls.down;
keycodes.left = controls.left;
keycodes.right = controls.right;
keycodes.confirm = controls.confirm;
keycodes.abort = controls.abort;
end
