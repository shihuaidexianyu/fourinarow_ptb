function main_loop(config)
%MAIN_LOOP 程序主循环 / 状态机驱动。
%   键盘模式流程：start_screen -> fixed_trials -> auto_result -> cleanup。
%   ESC 可在任意阶段中止。

% 检查 Psychtoolbox 是否可用
if ~exist('Screen', 'file')
    error('DependencyError:PsychtoolboxMissing', ...
        'Psychtoolbox Screen function is not available.');
end

trial_log = [];
cleanup_obj = onCleanup(@safe_cleanup);  % 异常退出时确保 PTB 资源释放

try
    ui = open_window_and_init_ui(config);           % 打开 PTB 窗口
    layout = compute_visual_layout(ui, config);     % 计算棋盘/按钮布局
    total_trials = config.game.num_trials;
    experiment_id = next_experiment_id();

    % ===== 开始页：仅键盘控制 =====
    draw_start_screen(ui, layout, config);
    [~, start_stimulus_time] = Screen('Flip', ui.win); % 实验开始时刻 = 开始页刺激呈现完成时刻
    start_choice = wait_start_choice(config.controls);

    if strcmp(start_choice, 'abort')
        emit_marker(config, 'game_abort_esc', GetSecs(), struct('result', 'aborted', 'phase', 'start_screen'));
        return;
    end

    key_release_guard_sec = config.timing.key_release_guard_sec; % 防止开始页按键残留到首手

    emit_marker(config, 'session_enter_game', start_stimulus_time, ...
        struct('experiment_id', experiment_id, 'total_trials', total_trials));

    % ===== 固定 trials 主循环 =====
    for trial_index = 1:total_trials
        state = init_game(config); % 主要通过传递state来驱动状态机，其他变量如 transient_ui 仅用于界面显示，不参与游戏逻辑
        trial_log = init_trial_log(config, ui, layout, experiment_id, trial_index, total_trials);
        human_cursor = init_cursor_from_board(state.board); % 人类玩家的键盘光标位置（初始为第一个空格）

        % 每局开始前展示注视点页面
        draw_fixation_screen(ui, config, layout);
        Screen('Flip', ui.win);
        aborted_on_fixation = wait_duration_or_abort(config.timing.pre_trial_fixation_sec, config.controls.abort);
        if aborted_on_fixation
            [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), ...
                struct('result', 'aborted', 'phase', 'pre_trial_fixation', 'trial_index', trial_index));
            state.result = 'aborted';
            state.game_over = true;
            trial_log = finalize_trial_log(trial_log, state);
            save_trial_log(trial_log, config);
            break;
        end

        % 防止注视点阶段按键残留到首手
        wait_until_no_key_down(key_release_guard_sec);

        [config, trial_log] = emit_and_log(config, trial_log, 'game_start', GetSecs(), ...
            struct('experiment_id', experiment_id, 'trial_index', trial_index, 'total_trials', total_trials));

        transient_ui = struct();
        transient_ui.illegal_until = -inf;  % 非法提示过期时刻（初始无提示）

        while ~state.game_over
            % 根据player选择要显示的提示词
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

            % 构造传给 player 的观察量
            obs.board = state.board;
            obs.current_player = state.current_player;
            obs.legal_actions = get_legal_actions(state);
            obs.last_action = state.last_action;
            obs.move_count = state.move_count;
            obs.game_over = state.game_over;

            response_t0 = board_ready_time;  % 反应时起点 = 棋盘刷新完成时刻

            % 调用当前玩家
            if state.current_player == config.game.human_player
                runtime_context = struct('ui', ui, 'layout', layout, 'state', state, ...
                    'transient_ui', transient_ui, 'config', config, 'cursor', human_cursor);
                [action, meta, human_cursor] = human_keyboard_player_play(obs, config.controls, runtime_context);
                actor = 'human';
            else
                [action, meta] = call_agent_player(obs, config.agent, struct());
                if config.agent.move_delay_sec > 0
                    WaitSecs(config.agent.move_delay_sec);
                end
                actor = 'agent';
            end

            % ---- 空动作处理（中止或非法输入）----
            if isempty(action)
                if strcmp(actor, 'human')
                    if meta.aborted
                        [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), struct('result', 'aborted', 'trial_index', trial_index));
                        state.result = 'aborted';
                        state.game_over = true;
                        break;
                    end

                    if meta.is_illegal
                        trial_log = log_illegal_click(trial_log, state.current_player, ...
                            meta.illegal_row, meta.illegal_col, meta.illegal_time, state.move_count);
                        if config.marker.enable_illegal_click_marker
                            payload = struct('player', state.current_player, 'row', meta.illegal_row, 'col', meta.illegal_col, ...
                                'move_count', state.move_count, 'is_illegal', true, 'trial_index', trial_index);
                            [config, trial_log] = emit_and_log(config, trial_log, 'response_illegal_click', meta.illegal_time, payload);
                        end
                        transient_ui.status_text = config.ui.illegal_text;
                        transient_ui.illegal_until = GetSecs() + config.ui.illegal_message_duration_sec;
                        continue;
                    end

                    error('InputError:EmptyHumanAction', ...
                        'human_keyboard_player_play returned an empty action without aborted/is_illegal metadata.');
                end

                error('AgentError:EmptyAction', ...
                    'Agent player returned an empty action while the game is still ongoing.');
            end

            % ---- 合法落子 ----
            response_time = GetSecs();
            rt = response_time - response_t0;

            if strcmp(actor, 'human')
                [config, trial_log] = emit_and_log(config, trial_log, 'response_human_move', response_time, ...
                    struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                    'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing', 'trial_index', trial_index));
            else
                [config, trial_log] = emit_and_log(config, trial_log, 'response_agent_move', response_time, ...
                    struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                    'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing', 'trial_index', trial_index));
            end

            [next_state, apply_info] = apply_action(state, action);
            move_player = state.current_player;
            state = next_state;

            if state.current_player == config.game.human_player
                transient_ui.selected_cell = [human_cursor.row, human_cursor.col];
            else
                transient_ui.selected_cell = [];
            end
            draw_game_screen(ui, layout, state, transient_ui, config);
            [~, stimulus_time] = Screen('Flip', ui.win);

            if strcmp(actor, 'human')
                [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_human_move_shown', stimulus_time, struct('trial_index', trial_index));
            else
                [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_agent_move_shown', stimulus_time, struct('trial_index', trial_index));
            end

            trial_log = log_move(trial_log, state, move_player, action, rt, response_time, stimulus_time);

            if apply_info.is_win || apply_info.is_draw
                break;
            end
        end

        % 结果页（自动推进，支持 ESC 中止）
        if strcmp(state.result, 'black_win')
            [config, trial_log] = emit_and_log(config, trial_log, 'game_end_black_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count, 'trial_index', trial_index));
        elseif strcmp(state.result, 'white_win')
            [config, trial_log] = emit_and_log(config, trial_log, 'game_end_white_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count, 'trial_index', trial_index));
        elseif strcmp(state.result, 'draw')
            [config, trial_log] = emit_and_log(config, trial_log, 'game_end_draw', GetSecs(), struct('result', state.result, 'move_count', state.move_count, 'trial_index', trial_index));
        end

        draw_result_screen(ui, layout, state, config);
        [~, result_stim_time] = Screen('Flip', ui.win);
        [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_result_shown', result_stim_time, ...
            struct('result', state.result, 'trial_index', trial_index));

        aborted_on_result = wait_duration_or_abort(config.ui.result_display_duration_sec, config.controls.abort);
        if aborted_on_result
            [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), ...
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
            aborted_on_iti = wait_duration_or_abort(config.timing.inter_trial_interval_sec, config.controls.abort);
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
try Priority(0); catch, end
try ShowCursor;   catch, end
try sca;          catch, end
end

function [config_out, trial_log] = emit_and_log(config_in, trial_log, event_name, timestamp, payload)
%EMIT_AND_LOG 同时发送 marker 并写入日志。
config_out = config_in;
emit_marker(config_in, event_name, timestamp, payload);

if ~isempty(trial_log)
    code = config_in.events(event_name);
    trial_log = log_marker_event(trial_log, code, event_name, timestamp, payload);
end
end

function choice = wait_start_choice(controls)
%WAIT_START_CHOICE 开始页等待按键：确认开始 / ESC 中止。
keycodes = build_control_keycodes(controls);
[~, ~, last_key_code] = KbCheck(-1);

while true
    [is_down, ~, key_code] = KbCheck(-1);
    if is_down
        pressed_edge = key_code & ~last_key_code;
        if any(pressed_edge(keycodes.abort))
            choice = 'abort';
            return;
        end
        if any(pressed_edge(keycodes.confirm))
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

abort_codes = abort_keys;
t_end = GetSecs() + duration_sec;

while GetSecs() < t_end
    [is_down, ~, key_code] = KbCheck(-1);
    if is_down && any(key_code(abort_codes))
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

function keycodes = build_control_keycodes(controls)
%BUILD_CONTROL_KEYCODES 从配置读取控制键 keycode。
keycodes = struct();
keycodes.confirm = controls.confirm;
keycodes.abort = controls.abort;
end

function [action, meta] = call_agent_player(obs, agent_config, runtime_context)
%CALL_AGENT_PLAYER 统一可替换 agent 调用入口。
% 支持：
%   1) agent_config.player_fn = @your_agent_play
%   2) agent_config.player_fn = 'your_agent_play'

fn = agent_config.player_fn;
if isempty(fn)
    error('AgentError:NoAgentConfigured', ...
        'Agent is not configured. Set config.agent.player_fn to a valid agent function.');
end

if ischar(fn) || isstring(fn)
    fn_name = char(fn);
    if ~(exist(fn_name, 'file') == 2 || exist(fn_name, 'builtin') == 5)
        error('AgentError:FunctionNotFound', ...
            'Agent function not found on MATLAB path: %s', fn_name);
    end
    fn = str2func(fn_name);
end

if ~isa(fn, 'function_handle')
    error('AgentError:InvalidFunction', ...
        'config.agent.player_fn must be a function handle or function name string.');
end

[action, meta] = fn(obs, agent_config, runtime_context);
end
