function main_loop(config)
%MAIN_LOOP 按顺序运行实验：开始页、每局对弈、结果页、保存日志。
%   ESC 可在等待或对弈时中止；函数退出时会关闭 PTB 窗口。

% 检查 Psychtoolbox 是否可用
if ~exist('Screen', 'file')
    error('DependencyError:PsychtoolboxMissing', ...
        'Psychtoolbox Screen function is not available.');
end

trial_log = [];
cleanup_obj = onCleanup(@safe_cleanup);  % 函数退出时自动释放 PTB 资源

try
    ui = open_window_and_init_ui(config);           % 打开 PTB 窗口
    layout = compute_visual_layout(ui, config);     % 计算棋盘/按钮布局
    total_trials = config.game.num_trials;
    experiment_id = next_experiment_id();

    % ===== 开始页：仅键盘控制 =====
    draw_start_screen(ui, config);
    [~, start_stimulus_time] = Screen('Flip', ui.win); % 记录开始页呈现完成的时刻
    start_choice = wait_start_choice(config.controls);

    if strcmp(start_choice, 'abort')
        payload = struct('result', 'aborted', 'phase', 'start_screen');
        emit_marker(config, 'game_abort_esc', GetSecs(), payload);
        return;
    end

    key_release_guard_sec = config.timing.key_release_guard_sec; % 防止开始页按键残留到首手

    emit_marker(config, 'session_enter_game', start_stimulus_time, ...
        struct('experiment_id', experiment_id, 'total_trials', total_trials));

    % ===== 固定 trials 主循环 =====
    for trial_index = 1:total_trials
        state = init_game(config); % 初始化空棋盘和先手
        trial_log = init_trial_log(config, ui, layout, experiment_id, trial_index, total_trials);
        human_cursor = init_cursor_from_board(state.board); % 从第一个空格开始选

        % 每局先显示注视点，再开始记录棋盘反应时。
        draw_fixation_screen(ui, config, layout);
        Screen('Flip', ui.win);
        aborted_on_fixation = wait_duration_or_abort( ...
            config.timing.pre_trial_fixation_sec, config.controls.abort);
        if aborted_on_fixation
            trial_log = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), ...
                struct('result', 'aborted', 'phase', 'pre_trial_fixation', 'trial_index', trial_index));
            state.result = 'aborted';
            state.game_over = true;
            trial_log = finalize_trial_log(trial_log, state);
            save_trial_log(trial_log, config);
            break;
        end

        % 防止注视点阶段按键残留到首手
        wait_until_no_key_down(key_release_guard_sec);

        trial_log = emit_and_log(config, trial_log, 'game_start', GetSecs(), ...
            struct('experiment_id', experiment_id, 'trial_index', trial_index, 'total_trials', total_trials));

        transient_ui = struct('illegal_until', -inf, 'status_text', '', 'selected_cell', []);

        while ~state.game_over
            % 显示当前玩家和人类玩家的光标位置。
            if state.current_player == 1
                transient_ui.status_text = config.ui.turn_black_text;
            else
                transient_ui.status_text = config.ui.turn_white_text;
            end

            if state.current_player == config.game.human_player
                transient_ui.selected_cell = [human_cursor.row, human_cursor.col];
            else
                transient_ui.selected_cell = [];
            end

            draw_game_screen(ui, layout, state, transient_ui, config);
            [~, board_ready_time] = Screen('Flip', ui.win);

            % 电脑策略只需要当前棋盘和可走位置；人类输入也共用这份局面信息。
            obs.board = state.board;
            obs.current_player = state.current_player;
            obs.legal_actions = get_legal_actions(state);
            obs.last_action = state.last_action;
            obs.move_count = state.move_count;
            obs.game_over = state.game_over;

            response_t0 = board_ready_time;  % 反应时从棋盘呈现完成时开始计算

            % 调用当前玩家
            if state.current_player == config.game.human_player
                runtime_context = struct('ui', ui, 'layout', layout, 'state', state, ...
                    'transient_ui', transient_ui, 'config', config, 'cursor', human_cursor);
                [action, meta, human_cursor] = human_keyboard_player_play( ...
                    obs, config.controls, runtime_context);
                actor = 'human';
            else
                % agent 通过函数句柄选择，默认是随机落子。
                action = config.agent.player_fn(obs);
                if config.agent.move_delay_sec > 0
                    WaitSecs(config.agent.move_delay_sec);
                end
                actor = 'agent';
            end

            % ---- 空动作处理（中止或非法输入）----
            if isempty(action)
                if strcmp(actor, 'human')
                    if meta.aborted
                        payload = struct('result', 'aborted', 'trial_index', trial_index);
                        trial_log = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), payload);
                        state.result = 'aborted';
                        state.game_over = true;
                        break;
                    end

                    if meta.is_illegal
                        trial_log = log_illegal_click(trial_log, state.current_player, ...
                            meta.illegal_row, meta.illegal_col, meta.illegal_time, state.move_count);
                        if config.marker.enable_illegal_click_marker
                            payload = struct('player', state.current_player, ...
                                'row', meta.illegal_row, 'col', meta.illegal_col, ...
                                'move_count', state.move_count, 'is_illegal', true, ...
                                'trial_index', trial_index);
                            trial_log = emit_and_log(config, trial_log, ...
                                'response_illegal_click', meta.illegal_time, payload);
                        end
                        transient_ui.status_text = config.ui.illegal_text;
                        transient_ui.illegal_until = GetSecs() + config.ui.illegal_message_duration_sec;
                        continue;
                    end

                    error('InputError:EmptyHumanAction', ...
                        'Human input returned no action.');
                end

                error('AgentError:EmptyAction', ...
                    'Agent player returned an empty action while the game is still ongoing.');
            end

            % ---- 合法落子：记响应时刻、更新棋盘、呈现新棋盘 ----
            response_time = GetSecs();
            rt = response_time - response_t0;

            response_event = ['response_' actor '_move'];
            move_payload = struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                'move_count', state.move_count + 1, 'rt', rt, ...
                'result', 'ongoing', 'trial_index', trial_index);
            trial_log = emit_and_log(config, trial_log, response_event, response_time, move_payload);

            % 先记下落子方，再更新状态；下一位玩家已写入新的 state。
            move_player = state.current_player;
            state = apply_action(state, action);

            if state.current_player == 1
                transient_ui.status_text = config.ui.turn_black_text;
            else
                transient_ui.status_text = config.ui.turn_white_text;
            end
            if state.current_player == config.game.human_player
                transient_ui.selected_cell = [human_cursor.row, human_cursor.col];
            else
                transient_ui.selected_cell = [];
            end
            draw_game_screen(ui, layout, state, transient_ui, config);
            [~, stimulus_time] = Screen('Flip', ui.win);

            stimulus_event = ['stimulus_' actor '_move_shown'];
            payload = struct('trial_index', trial_index);
            trial_log = emit_and_log(config, trial_log, stimulus_event, stimulus_time, payload);

            trial_log = log_move(trial_log, state, move_player, action, rt, response_time, stimulus_time);

            if state.game_over
                break;
            end
        end

        % 结果页（自动推进，支持 ESC 中止）
        if any(strcmp(state.result, {'black_win', 'white_win', 'draw'}))
            result_event = ['game_end_' state.result];
            payload = struct('result', state.result, ...
                'move_count', state.move_count, 'trial_index', trial_index);
            trial_log = emit_and_log(config, trial_log, result_event, GetSecs(), payload);
        end

        draw_result_screen(ui, layout, state, config);
        [~, result_stim_time] = Screen('Flip', ui.win);
        trial_log = emit_and_log(config, trial_log, 'stimulus_result_shown', result_stim_time, ...
            struct('result', state.result, 'trial_index', trial_index));

        aborted_on_result = wait_duration_or_abort( ...
            config.ui.result_display_duration_sec, config.controls.abort);
        if aborted_on_result
            trial_log = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), ...
                struct('result', 'aborted', 'phase', 'result', 'trial_index', trial_index));
            state.result = 'aborted';
            state.game_over = true;
        end

        trial_log = finalize_trial_log(trial_log, state);
        save_trial_log(trial_log, config);
        trial_log = [];

        if strcmp(state.result, 'aborted')
            break;
        end

        % 局间间隔（最后一局后不等待）
        if trial_index < total_trials
            Screen('FillRect', ui.win, ui.colors.bg);
            Screen('Flip', ui.win);
            aborted_on_iti = wait_duration_or_abort( ...
                config.timing.inter_trial_interval_sec, config.controls.abort);
            if aborted_on_iti
                emit_marker(config, 'game_abort_esc', GetSecs(), ...
                    struct('result', 'aborted', 'phase', 'inter_trial_interval', 'trial_index', trial_index));
                break;
            end
            wait_until_no_key_down(key_release_guard_sec);
        end
    end

catch ME
    % 异常退出时尝试保存日志
    if ~isempty(trial_log)
        try
            trial_log.aborted = true;
            trial_log.result = 'aborted';
            trial_log.error = ME.message;
            save_trial_log(trial_log, config);
        catch log_error
            warning('LoggingWarning:SaveFailedDuringException', ...
                'Failed to save trial log while handling another error: %s', log_error.message);
        end
    end

    rethrow(ME);
end
end

%% ---- 内部辅助函数 ----

function safe_cleanup()
%SAFE_CLEANUP 确保 PTB 资源被释放（优先级、光标、窗口）。
% 窗口可能在初始化中途打开失败，所以每一步清理都单独尝试。
try
    Priority(0);
catch
end
try
    ShowCursor;
catch
end
try
    sca;
catch
end
end

function trial_log = emit_and_log(config, trial_log, event_name, timestamp, payload)
%EMIT_AND_LOG 同时发送 marker 并写入日志。
emit_marker(config, event_name, timestamp, payload);

if ~isempty(trial_log)
    code = config.events(event_name);
    trial_log = log_marker_event(trial_log, code, event_name, timestamp, payload);
end
end

function choice = wait_start_choice(controls)
%WAIT_START_CHOICE 开始页等待按键：确认开始 / ESC 中止。
[~, ~, last_key_code] = KbCheck(-1);

while true
    [is_down, ~, key_code] = KbCheck(-1);
    if is_down
        pressed_edge = key_code & ~last_key_code;
        if any(pressed_edge(controls.abort))
            choice = 'abort';
            return;
        end
        if any(pressed_edge(controls.confirm))
            choice = 'start';
            return;
        end
    end

    last_key_code = key_code;
    WaitSecs(0.005);
end
end

function aborted = wait_duration_or_abort(duration_sec, abort_keys)
%WAIT_DURATION_OR_ABORT 停留一段时间；期间若按 ESC 则返回中止。
aborted = false;
if duration_sec <= 0
    return;
end

t_end = GetSecs() + duration_sec;

while GetSecs() < t_end
    [is_down, ~, key_code] = KbCheck(-1);
    if is_down && any(key_code(abort_keys))
        aborted = true;
        return;
    end
    WaitSecs(0.005);
end
end

function wait_until_no_key_down(timeout_sec)
%WAIT_UNTIL_NO_KEY_DOWN 等待所有按键释放（带超时保护）。
t0 = GetSecs();
while true
    [is_down, ~, ~] = KbCheck(-1);
    if ~is_down
        return;
    end
    if GetSecs() - t0 > timeout_sec
        return;
    end
    WaitSecs(0.005);
end
end

function cursor = init_cursor_from_board(board)
%INIT_CURSOR_FROM_BOARD 初始化键盘光标位置。
idx = find(board == 0, 1, 'first');
if isempty(idx)
    error('GameError:NoCursorTarget', ...
        'Cannot initialize the human cursor because the board has no empty cells.');
end
[row, col] = ind2sub(size(board), idx);
cursor = struct('row', row, 'col', col);
end
