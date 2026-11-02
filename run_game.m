function run_game()
%RUN_GAME 运行 Psychtoolbox 四子棋实验。
%   在 MATLAB 当前目录为项目根目录时运行 run_game。

project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'hardware', 'io64'));

config = load_config();
config.logging.save_dir = fullfile(project_root, config.logging.save_dir);
main_loop(config);
end

%% Settings and event codes
function config = load_config()
%LOAD_CONFIG 硬编码的配置。
%   所有实验参数集中在此文件中修改。

% ---- 游戏规则 ----
config.game.rows = 4;                  % 棋盘行数
config.game.cols = 9;                  % 棋盘列数
config.game.connect_n = 4;             % 连几子获胜
config.game.first_player = 1;          % 先手：1=黑方, 2=白方
config.game.human_player = 1;          % 人类执子
config.game.agent_player = 2;          % 电脑执子
config.game.num_trials = 10;           % 固定试次数（每次 run_game 连续完成）

if config.game.human_player == config.game.agent_player
    error('ConfigError:PlayerColorConflict', ...
        'human_player and agent_player must be different.');
end

% ---- 显示参数 ----
config.display.cell_deg = 2.0;                     % 每格视角大小（度）
config.display.piece_ratio = 0.85;                  % 棋子直径占格子边长比例
config.display.viewing_distance_cm = 60;            % 观察距离（厘米）
config.display.use_manual_screen_size = false;       % 是否手动指定屏幕物理尺寸
config.display.manual_screen_width_cm = [];          % 手动屏幕宽度（厘米）
config.display.manual_screen_height_cm = [];         % 手动屏幕高度（厘米）
if exist('Screen', 'file')
    config.display.screen_index = max(Screen('Screens')); % 使用的屏幕编号
else
    config.display.screen_index = 0;                     % 延迟到运行期再校验 PTB
end
config.display.fullscreen = true;                    % 是否全屏
config.display.ptb_skip_sync_tests = true;           % 正式实验时建议改为 false

% ---- 界面文本 ----
config.ui.illegal_message_duration_sec = 0.8;       % 非法动作提示时长（秒）
config.ui.title_text = '四子棋';
config.ui.instruction_text = ['实验说明：\n' ...
    '1) 使用方向键移动光标（上下左右）\n' ...
    '2) 使用确认键落子\n' ...
    '3) 共进行固定试次，对局将自动推进\n' ...
    '4) 按 ESC 可中止实验'];
config.ui.turn_black_text = '轮到：黑方';
config.ui.turn_white_text = '轮到：白方';
config.ui.illegal_text = '非法动作，请重试';
config.ui.black_win_text = '黑方获胜';
config.ui.white_win_text = '白方获胜';
config.ui.draw_text = '平局';
config.ui.game_over_text = '游戏结束';
config.ui.start_hint_text = '按确认键开始实验，按 ESC 退出';
config.ui.result_hint_text = '结果将自动进入下一局（或按 ESC 退出）';
config.ui.result_display_duration_sec = 1.0;        % 结果页自动停留时长（秒）
config.ui.fixation_deg = 0.8;                       % 注视点总长度视角（度）
config.ui.fixation_thickness_deg = 0.08;            % 注视点线宽视角（度）

% ---- 时序配置 ----
config.timing.pre_trial_fixation_sec = 0.8;         % 每局开始前注视点时长（秒）
config.timing.inter_trial_interval_sec = 0.0;       % 结果页之后额外等待的时间
config.timing.key_release_guard_sec = 0.15;         % 等待按键释放，避免按键残留

% ---- 键盘交互配置（硬编码 keycode，统一在 config 管理） ----
KbName('UnifyKeyNames');
config.controls.up = KbName('UpArrow');
config.controls.down = KbName('DownArrow');
config.controls.left = KbName('LeftArrow');
config.controls.right = KbName('RightArrow');
config.controls.confirm = unique([KbName('Return'), KbName('space')]);
config.controls.abort = KbName('ESCAPE');

% ---- Marker / EEG 打标 ----
config.marker.enable = false;                        % 是否启用 marker
config.marker.enable_illegal_click_marker = true;   % 非法点击是否打 marker
config.marker.parallel_port_address = '0FF8';       % 并口地址（十六进制字符串）
config.marker.pulse_width_sec = 0.004;              % 脉冲宽度（秒）

% ---- Agent ----
config.agent.player_fn = @random_agent_play;        % 电脑策略；函数接收 obs 并返回 action
config.agent.move_delay_sec = 0.0;                  % 电脑落子前的额外等待时间（秒）

% ---- 日志 ----
config.logging.enable = true;
config.logging.save_dir = 'logs';                   % 日志目录；run_game 会转为绝对路径

% ---- 事件码映射表 ----
config.events = marker_name_to_code();
end

function event_map = marker_name_to_code()
%MARKER_NAME_TO_CODE 固定的事件名到事件码映射表。

% eeg为8位输入端口，事件码范围为0-255，0通常用作复位信号，因此事件码从1开始编号。
% 事件码的具体数值没有特殊意义，但必须保持一致以确保数据分析

event_map = containers.Map();

% 状态类
event_map('session_enter_game') = 1;
event_map('game_start')         = 2;
event_map('game_abort_esc')     = 3;

% 行为响应类
event_map('response_human_move')    = 4;
event_map('response_illegal_click') = 5;
event_map('response_agent_move')    = 6;

% 视觉呈现类
event_map('stimulus_human_move_shown') = 7;
event_map('stimulus_agent_move_shown') = 8;
event_map('stimulus_result_shown')     = 9;

% 结局类
event_map('game_end_black_win') = 10;
event_map('game_end_white_win') = 11;
event_map('game_end_draw')      = 12;
end

%% Main experiment flow and keyboard input
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
    experiment_id = char(datetime('now', 'Format', 'yyMMddHHmmssSSS'));

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

%% Game rules and computer move
function state = init_game(config)
%INIT_GAME 初始化游戏状态。
%   创建空棋盘并设定初始字段。

rows = config.game.rows;
cols = config.game.cols;

state.board = zeros(rows, cols);            % 棋盘矩阵：0=空, 1=黑, 2=白
state.connect_n = config.game.connect_n;    % 连几子获胜
state.current_player = config.game.first_player;
state.move_count = 0;                       % 已完成的合法落子数
state.last_action = [];                     % 上一步动作 struct 或空
state.game_over = false;
state.result = 'ongoing';                   % 'ongoing'|'black_win'|'white_win'|'draw'|'aborted'
state.winning_cells = zeros(0, 2);          % 胜利连线上的坐标 [row, col]
state.winning_line = struct('start_row', [], 'start_col', [], 'end_row', [], 'end_col', []);
end

function legal_actions = get_legal_actions(state)
%GET_LEGAL_ACTIONS 返回所有空格位置，格式固定为 N×2 矩阵 [row, col]。
%   约定：
%   - 第 1 列是 row，第 2 列是 col；
%   - N=0 时返回 0×2 空矩阵；
%   - 调用方（如 agent）应按该契约解析。

[r, c] = find(state.board == 0);
legal_actions = [r, c];
end

function is_valid = is_valid_action(state, action)
%IS_VALID_ACTION 检查动作合法性。
%   必须满足：游戏未结束、行列范围合法、目标格为空。

if state.game_over
    is_valid = false;
    return;
end

if ~isstruct(action) || ~isfield(action, 'row') || ~isfield(action, 'col')
    is_valid = false;
    return;
end

row = action.row;
col = action.col;

% 必须为标量整数
if ~isscalar(row) || ~isscalar(col) || row ~= floor(row) || col ~= floor(col)
    is_valid = false;
    return;
end

% 范围检查
rows = size(state.board, 1);
cols = size(state.board, 2);
if row < 1 || row > rows || col < 1 || col > cols
    is_valid = false;
    return;
end

% 目标格必须为空
is_valid = (state.board(row, col) == 0);
end

function next_state = apply_action(state, action)
%APPLY_ACTION 应用一步合法动作并更新终局标志。
%   判定顺序：先检查胜利，再检查平局，否则切换玩家。

if ~is_valid_action(state, action)
    if isstruct(action) && isfield(action, 'row') && isfield(action, 'col')
        error('GameError:InvalidAction', ...
            'Invalid action row=%s col=%s', mat2str(action.row), mat2str(action.col));
    end
    error('GameError:InvalidAction', 'Invalid action.');
end

next_state = state;
player = state.current_player;
next_state.board(action.row, action.col) = player;  % 落子
next_state.last_action = action;
next_state.move_count = state.move_count + 1;

% 1) 检查胜利
[is_win, winning_cells, winning_line] = check_winner(next_state, action);
if is_win
    next_state.game_over = true;
    if player == 1
        next_state.result = 'black_win';
    else
        next_state.result = 'white_win';
    end
    next_state.winning_cells = winning_cells;
    next_state.winning_line = winning_line;
    return;
end

% 2) 检查平局
% 棋盘没有空格且无人获胜时，判为平局。
is_draw = ~any(next_state.board(:) == 0);
if is_draw
    next_state.game_over = true;
    next_state.result = 'draw';
else
    % 3) 未结束 → 切换玩家
    next_state.current_player = 3 - state.current_player;
end

end

function [is_win, winning_cells, winning_line] = check_winner(state, action)
%CHECK_WINNER 只需围绕最新落子检查四个方向是否连成足够的棋子。
%   返回胜利格坐标和连线两端；没有获胜时返回空坐标。

board = state.board;
row0 = action.row;
col0 = action.col;
player = board(row0, col0);
connect_n = state.connect_n;

% 四个方向：水平、垂直、主对角线、副对角线
dirs = [0, 1; 1, 0; 1, 1; 1, -1];
best_cells = zeros(0, 2);

for i = 1:size(dirs, 1)
    dr = dirs(i, 1);
    dc = dirs(i, 2);

    % 向正、反两个方向延伸
    cells_pos = walk_direction(board, row0, col0, dr, dc, player);
    cells_neg = walk_direction(board, row0, col0, -dr, -dc, player);

    % 拼接成完整连线（去除重复的原点）
    cells_neg = flipud(cells_neg);
    cells = [cells_neg(1:end-1, :); cells_pos];

    if size(cells, 1) >= connect_n && size(cells, 1) > size(best_cells, 1)
        best_cells = cells;
    end
end

is_win = ~isempty(best_cells);
if is_win
    winning_cells = best_cells;
    winning_line = struct( ...
        'start_row', best_cells(1, 1), ...
        'start_col', best_cells(1, 2), ...
        'end_row', best_cells(end, 1), ...
        'end_col', best_cells(end, 2));
else
    winning_cells = zeros(0, 2);
    winning_line = struct('start_row', [], 'start_col', [], 'end_row', [], 'end_col', []);
end
end

function cells = walk_direction(board, row0, col0, dr, dc, player)
%WALK_DIRECTION 从 (row0,col0) 沿 (dr,dc) 方向收集同色棋子坐标。
rows = size(board, 1);
cols = size(board, 2);

cells = [row0, col0];
r = row0 + dr;
c = col0 + dc;
while r >= 1 && r <= rows && c >= 1 && c <= cols && board(r, c) == player
    cells = [cells; r, c]; %#ok<AGROW>
    r = r + dr;
    c = c + dc;
end
end

function action = random_agent_play(obs)
%RANDOM_AGENT_PLAY 随机 agent：从合法动作中均匀随机选一个。

legal = obs.legal_actions;
if isempty(legal)
    error('AgentError:NoLegalAction', ...
        'random_agent_play received an empty legal action list while the game is still ongoing.');
end

if ~ismatrix(legal) || size(legal, 2) ~= 2
    error('AgentError:InvalidLegalActions', ...
        'obs.legal_actions must be an N-by-2 matrix of [row, col].');
end

idx = randi(size(legal, 1));
action.row = legal(idx, 1);
action.col = legal(idx, 2);
end

%% Psychtoolbox window and screens
function ui = open_window_and_init_ui(config)
%OPEN_WINDOW_AND_INIT_UI 打开 PTB 窗口并初始化视觉样式。
%   设置文本渲染器、字体、颜色、按钮样式等。

PsychDefaultSetup(2);                                   % 归一化颜色范围为 0~1
KbName('UnifyKeyNames');                                % 统一跨平台键名映射
Screen('Preference', 'SkipSyncTests', double(logical(config.display.ptb_skip_sync_tests)));

Screen('Preference', 'TextRenderer', 1);                % 启用高质量渲染器，支持 CJK

% ---- 颜色定义（归一化 RGB）----
bg       = [0.5, 0.5, 0.5];       % 背景色：中性灰
white    = [1, 1, 1];
black    = [0, 0, 0];
line_col = [0.08, 0.08, 0.08];    % 网格线：深灰
accent   = [1.0, 0.31, 0.0];      % 胜利高亮：橙红

% ---- 打开窗口 ----
screen_idx = config.display.screen_index;
if config.display.fullscreen
    [win, rect] = PsychImaging('OpenWindow', screen_idx, bg);
else
    [win, rect] = PsychImaging('OpenWindow', screen_idx, bg, [100, 100, 1200, 900]);
end

% ---- 光标：实验期间隐藏 ----
HideCursor;

% ---- 字体 ----
Screen('TextFont', win, 'Microsoft YaHei UI');   % 支持中文的字体
Screen('TextSize', win, 28);

% ---- 输出 UI 结构体 ----
ui.win = win;
ui.screen_rect = rect;
ui.colors.bg = bg;
ui.colors.white = white;
ui.colors.black = black;
ui.colors.grid = line_col;
ui.colors.highlight = accent;
ui.colors.text = [0.04, 0.04, 0.04];

Priority(MaxPriority(win));   % 提升进程优先级以减少时序抖动
end

function layout = compute_visual_layout(ui, config)
%COMPUTE_VISUAL_LAYOUT 根据视觉角度计算棋盘与按钮的像素布局。
%   流程：获取屏幕物理尺寸 → 视角换算 → 棋盘/按钮矩形 → 安全显示检查

screen_w_px = ui.screen_rect(3);
screen_h_px = ui.screen_rect(4);

% ---- 获取屏幕物理尺寸 ----
if config.display.use_manual_screen_size
    screen_w_cm = config.display.manual_screen_width_cm;
    screen_h_cm = config.display.manual_screen_height_cm;
else
    [screen_w_mm, screen_h_mm] = Screen('DisplaySize', config.display.screen_index);
    screen_w_cm = screen_w_mm / 10;
    screen_h_cm = screen_h_mm / 10;
end

if isempty(screen_w_cm) || isempty(screen_h_cm) || screen_w_cm <= 0 || screen_h_cm <= 0
    error('DisplayError:ScreenPhysicalSizeInvalid', ...
        'Invalid physical screen size: width=%.4fcm height=%.4fcm', screen_w_cm, screen_h_cm);
end

% ---- 像素密度（取较小值避免形变）----
px_per_cm_x = screen_w_px / screen_w_cm;
px_per_cm_y = screen_h_px / screen_h_cm;
px_per_cm = min(px_per_cm_x, px_per_cm_y);

% ---- 视角 → 像素 ----
cell_cm = deg2cm(config.display.cell_deg, config.display.viewing_distance_cm);
cell_px = cm2px(cell_cm, px_per_cm);
piece_diameter_px = max(6, round(config.display.piece_ratio * cell_px));

board_w_px = config.game.cols * cell_px;   % 棋盘总宽
board_h_px = config.game.rows * cell_px;   % 棋盘总高

% ---- UI 预留高度 ----
title_h  = 80;     % 标题区
status_h = 90;     % 状态文字区（含说明/提示）
margin_h = 90;     % 边距
reserved_h = title_h + status_h + margin_h;

% ---- 安全显示检查 ----
assert_display_fits(screen_w_px, screen_h_px, board_w_px, board_h_px, reserved_h, struct( ...
    'screen_w_cm', screen_w_cm, ...
    'screen_h_cm', screen_h_cm, ...
    'distance_cm', config.display.viewing_distance_cm, ...
    'cell_deg', config.display.cell_deg));

% ---- 棋盘居中 ----
board_left = round((screen_w_px - board_w_px) / 2);
board_top  = round((screen_h_px - board_h_px) / 2);
board_rect = [board_left, board_top, board_left + board_w_px, board_top + board_h_px];

% ---- 每个格子的屏幕矩形 ----
cell_rects = zeros(config.game.rows, config.game.cols, 4);
for r = 1:config.game.rows
    for c = 1:config.game.cols
        l = board_left + (c - 1) * cell_px;
        t = board_top  + (r - 1) * cell_px;
        cell_rects(r, c, :) = [l, t, l + cell_px, t + cell_px];
    end
end

% ---- 输出 ----
layout.screen_width_cm  = screen_w_cm;
layout.screen_height_cm = screen_h_cm;
layout.px_per_cm        = px_per_cm;
layout.cell_size_px     = cell_px;
layout.piece_diameter_px = piece_diameter_px;
layout.board_rect       = board_rect;
layout.cell_rects       = cell_rects;
layout.title_y          = board_rect(2) - 90;   % 标题 Y 坐标（棋盘上方）
layout.status_y         = board_rect(4) + 40;   % 状态文字 Y 坐标（棋盘下方）
end

function draw_start_screen(ui, config)
%DRAW_START_SCREEN 绘制开始页：标题、实验说明、配置摘要与键盘提示。

Screen('FillRect', ui.win, ui.colors.bg);

% 使用顺序布局避免多行文本重叠
y = 60;
[~, y_after_title] = draw_text(ui.win, config.ui.title_text, 'center', y, ui.colors.text);

y = y_after_title + 18;
[~, y_after_instruction] = draw_text(ui.win, config.ui.instruction_text, 'center', y, ui.colors.text);

% 玩家编号 1/2 分别对应黑方/白方。
player_color = {'黑方', '白方'};

summary = sprintf(['棋盘：%d×%d（自由落点）\n' ...
    '人类：%s    电脑：%s\n' ...
    '先手：%s'], ...
    config.game.rows, config.game.cols, ...
    player_color{config.game.human_player}, ...
    player_color{config.game.agent_player}, ...
    player_color{config.game.first_player});
y = y_after_instruction + 20;
[~, y_after_summary] = draw_text(ui.win, summary, 'center', y, ui.colors.text);

y = y_after_summary + 22;
draw_text(ui.win, config.ui.start_hint_text, 'center', y, ui.colors.text);
end

function draw_fixation_screen(ui, config, layout)
%DRAW_FIXATION_SCREEN 绘制注视点页面（居中）。
%   按视觉角度绘制十字注视点。

Screen('FillRect', ui.win, ui.colors.bg);
draw_angle_cross_fixation(ui, config, layout);
end

function draw_angle_cross_fixation(ui, config, layout)
%DRAW_ANGLE_CROSS_FIXATION 按视觉角度绘制十字注视点。

len_cm = deg2cm(config.ui.fixation_deg, config.display.viewing_distance_cm);
thick_cm = deg2cm(config.ui.fixation_thickness_deg, config.display.viewing_distance_cm);

len_px = max(6, cm2px(len_cm, layout.px_per_cm));
thick_px = max(2, cm2px(thick_cm, layout.px_per_cm));

rect = ui.screen_rect;
cx = round((rect(1) + rect(3)) / 2);
cy = round((rect(2) + rect(4)) / 2);
half_len = round(len_px / 2);

Screen('DrawLine', ui.win, ui.colors.text, cx - half_len, cy, cx + half_len, cy, thick_px);
Screen('DrawLine', ui.win, ui.colors.text, cx, cy - half_len, cx, cy + half_len, thick_px);
end

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

function draw_board(ui, layout)
%DRAW_BOARD 绘制棋盘网格线。

rect = layout.board_rect;
Screen('FrameRect', ui.win, ui.colors.grid, rect, 2);  % 外框

rows = size(layout.cell_rects, 1);
cols = size(layout.cell_rects, 2);

% 竖线
for c = 1:(cols-1)
    x = rect(1) + c * layout.cell_size_px;
    Screen('DrawLine', ui.win, ui.colors.grid, x, rect(2), x, rect(4), 2);
end
% 横线
for r = 1:(rows-1)
    y = rect(2) + r * layout.cell_size_px;
    Screen('DrawLine', ui.win, ui.colors.grid, rect(1), y, rect(3), y, 2);
end
end

function draw_pieces(ui, layout, state)
%DRAW_PIECES 绘制所有棋子及胜利高亮（边框 + 连线）。

board = state.board;
rows = size(board, 1);
cols = size(board, 2);

radius = layout.piece_diameter_px / 2;

% ---- 绘制棋子 ----
for r = 1:rows
    for c = 1:cols
        val = board(r, c);
        if val == 0
            continue;
        end

        rect = squeeze(layout.cell_rects(r, c, :))';
        cx = (rect(1) + rect(3)) / 2;
        cy = (rect(2) + rect(4)) / 2;
        oval = [cx-radius, cy-radius, cx+radius, cy+radius];

        if val == 1   % 黑子：实心圆
            Screen('FillOval', ui.win, ui.colors.black, oval);
        else          % 白子：实心圆 + 深色描边
            Screen('FillOval', ui.win, ui.colors.white, oval);
            Screen('FrameOval', ui.win, ui.colors.grid, oval, 2);
        end
    end
end

% ---- 胜利高亮 ----
if ~isempty(state.winning_cells)
    % 边框高亮
    for i = 1:size(state.winning_cells, 1)
        rr = state.winning_cells(i, 1);
        cc = state.winning_cells(i, 2);
        rect = squeeze(layout.cell_rects(rr, cc, :))';
        Screen('FrameRect', ui.win, ui.colors.highlight, rect, 4);
    end

    % 中心连线高亮
    if ~isempty(state.winning_line.start_row)
        rect0 = squeeze(layout.cell_rects(state.winning_line.start_row, state.winning_line.start_col, :))';
        rect1 = squeeze(layout.cell_rects(state.winning_line.end_row, state.winning_line.end_col, :))';
        p0 = [(rect0(1) + rect0(3)) / 2, (rect0(2) + rect0(4)) / 2];
        p1 = [(rect1(1) + rect1(3)) / 2, (rect1(2) + rect1(4)) / 2];
        Screen('DrawLine', ui.win, ui.colors.highlight, p0(1), p0(2), p1(1), p1(2), 6);
    end
end
end

function [nx, ny] = draw_text(win, text, x, y, color)
%DRAW_TEXT 支持中文的文本绘制函数。
%   使用 Screen('DrawText') 逐行渲染，避免 DrawFormattedText 对 CJK
%   double 数组的字宽计算问题。支持 'center' 定位和 \n 多行文本。

% 转为 double 数组（PTB 以 Unicode 码点渲染中文）
if ischar(text)
    text_chars = double(text);
else
    text_chars = text;
end

% 按换行符拆分为多行
lines = split_lines(text_chars);

rect  = Screen('Rect', win);
win_w = rect(3);
win_h = rect(4);

% ---- 测量每行宽高 ----
n_lines      = numel(lines);
line_bounds  = cell(n_lines, 1);
line_widths  = zeros(n_lines, 1);
line_heights = zeros(n_lines, 1);
for i = 1:n_lines
    b = Screen('TextBounds', win, lines{i});
    line_bounds{i} = b;
    line_widths(i)  = b(3) - b(1);
    line_heights(i) = b(4) - b(2);
end

line_spacing = 1.2;              % 行距倍率
single_h = max(line_heights);
if single_h == 0
    single_h = Screen('TextSize', win);
end
total_h = single_h * n_lines + single_h * (line_spacing - 1) * (n_lines - 1);
step_h  = single_h * line_spacing;

% ---- 计算起始 Y ----
if ischar(y) && strcmp(y, 'center')
    start_y = round((win_h - total_h) / 2);
else
    start_y = y;
end

% ---- 逐行绘制 ----
nx = 0;
ny = start_y;

for i = 1:n_lines
    cur_y = start_y + (i - 1) * step_h;

    if ischar(x) && strcmp(x, 'center')
        cur_x = round((win_w - line_widths(i)) / 2);
    else
        cur_x = x;
    end

    Screen('DrawText', win, lines{i}, cur_x, cur_y, color);

    nx = cur_x + line_widths(i);
    ny = cur_y + single_h;
end
end

function lines = split_lines(chars)
%SPLIT_LINES 将 double 数组按换行符（code 10）或字面 \n 序列拆分。
nl     = 10;
bs     = double('\');
n_char = double('n');

% 将字面 \n 替换为真正的换行符
expanded = [];
i = 1;
while i <= numel(chars)
    if i < numel(chars) && chars(i) == bs && chars(i+1) == n_char
        expanded = [expanded, nl]; %#ok<AGROW>
        i = i + 2;
    else
        expanded = [expanded, chars(i)]; %#ok<AGROW>
        i = i + 1;
    end
end

% 按换行符分割
idx = find(expanded == nl);
if isempty(idx)
    lines = {expanded};
    return;
end

lines = {};
prev = 1;
for k = 1:numel(idx)
    lines{end+1} = expanded(prev:idx(k)-1); %#ok<AGROW>
    prev = idx(k) + 1;
end
lines{end+1} = expanded(prev:end);
end

%% Trial logs
function trial = init_trial_log(config, ui, layout, experiment_id, trial_index, total_trials)
%INIT_TRIAL_LOG 初始化单局日志结构体。
%   包含实验序号、局序号、时间、配置快照、屏幕参数等。

trial = struct();
trial.experiment_id  = experiment_id;               % 一次 run_game 的统一实验序号
trial.game_id        = sprintf('%03d', trial_index);      % 局序号（当前 run 内）
trial.trial_index    = trial_index;                 % 当前是第几局
trial.total_trials   = total_trials;                % 总局数（固定 trials）
trial.start_datetime = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
trial.end_datetime   = '';
trial.result         = 'ongoing';
trial.aborted        = false;

trial.first_player = config.game.first_player;
trial.human_player = config.game.human_player;
trial.agent_player = config.game.agent_player;

% 屏幕信息
trial.screen_info = struct();
trial.screen_info.width_px  = ui.screen_rect(3);
trial.screen_info.height_px = ui.screen_rect(4);
trial.screen_info.width_cm  = layout.screen_width_cm;
trial.screen_info.height_cm = layout.screen_height_cm;
trial.viewing_distance_cm   = config.display.viewing_distance_cm;

trial.config_snapshot   = config;            % 完整配置快照
trial.marker_events     = struct([]);        % marker 事件数组
trial.moves             = struct([]);        % 合法动作数组
trial.illegal_clicks    = struct([]);        % 非法点击数组
trial.illegal_click_count = 0;
end

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

function trial = log_marker_event(trial, event_code, event_name, timestamp, payload)
%LOG_MARKER_EVENT 追加一条 marker 事件记录。

entry.event_code = event_code;
entry.event_name = event_name;
entry.timestamp  = timestamp;
entry.payload    = payload;

if isempty(trial.marker_events)
    trial.marker_events = entry;
else
    trial.marker_events(end + 1) = entry;
end
end

function trial = finalize_trial_log(trial, state)
%FINALIZE_TRIAL_LOG 填写结束时间与最终结果。

trial.end_datetime = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
trial.result  = state.result;
trial.aborted = strcmp(state.result, 'aborted');
end

function save_trial_log(trial, config)
%SAVE_TRIAL_LOG 将单局日志保存为 .mat 文件。
%   文件名格式：trial_<exp>_tXXX.mat

if ~config.logging.enable
    return;
end

% 确保保存目录存在
save_dir = config.logging.save_dir;
if ~isfolder(save_dir)
    [ok, msg] = mkdir(save_dir);
    if ~ok
        error('LoggingError:CreateDirFailed', ...
            'Failed to create log directory: %s (%s)', save_dir, msg);
    end
end

experiment_id_short = regexprep(trial.experiment_id, '[^A-Za-z0-9]', '');
experiment_id_short = lower(experiment_id_short);
if strlength(string(experiment_id_short)) > 12
    experiment_id_short = extractBefore(string(experiment_id_short), 13);
    experiment_id_short = char(experiment_id_short);
end
file_name = sprintf('trial_%s_t%03d.mat', experiment_id_short, trial.trial_index);

save_path = fullfile(save_dir, file_name);
save(save_path, 'trial');
end

%% Small calculations
function cm = deg2cm(theta_deg, distance_cm)
%DEG2CM 视觉角度（度）→ 物理尺寸（厘米）。
%   公式：cm = 2 * d * tan(theta/2)

cm = 2 .* distance_cm .* tan(deg2rad(theta_deg ./ 2));
end

function px = cm2px(cm, px_per_cm)
%CM2PX 厘米 → 像素（四舍五入取整）。

px = round(cm .* px_per_cm);
end

function assert_display_fits(screen_w_px, screen_h_px, board_w_px, board_h_px, reserved_h_px, detail)
%ASSERT_DISPLAY_FITS 检查棋盘 + UI 预留区域是否能在屏幕内安全显示。
%   超出允许范围则报错并给出详细诊断信息。

max_board_w = floor(screen_w_px * 0.95);
max_board_h = floor((screen_h_px - reserved_h_px) * 0.95);

if board_w_px > max_board_w || board_h_px > max_board_h
    msg = sprintf(['棋盘无法安全显示。\n' ...
        '屏幕分辨率: %dx%d px\n' ...
        '物理尺寸: %.2f x %.2f cm\n' ...
        '观察距离: %.2f cm\n' ...
        '格子视角: %.2f deg\n' ...
        '棋盘尺寸: %dx%d px\n' ...
        '最大可用区域(近似): %dx%d px\n' ...
        '建议：减小 cell_deg 或调整 viewing_distance_cm。'], ...
        screen_w_px, screen_h_px, ...
        detail.screen_w_cm, detail.screen_h_cm, ...
        detail.distance_cm, detail.cell_deg, ...
        board_w_px, board_h_px, max_board_w, max_board_h);
    error('DisplayError:BoardTooLarge', '%s', msg);
end
end

%% Marker event dispatch
function emit_marker(config, event_name, timestamp, payload)
%EMIT_MARKER 统一 marker 发射接口。
%   根据事件名查找事件码，再交给并口发送函数。

if ~config.marker.enable
    return;
end

if ~isKey(config.events, event_name)
    error('MarkerError:UnknownEvent', 'Unknown marker event: %s', event_name);
end

event_code = config.events(event_name);
send_marker(event_code, event_name, timestamp, config.marker);
end
