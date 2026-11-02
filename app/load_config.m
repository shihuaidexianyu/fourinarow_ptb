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
config.display.ptb_skip_sync_tests = true;           % 是否跳过 PTB 同步测试（开发机默认 true，正式实验建议改回 false）
config.display.ptb_vbl_timestamping_mode = [];       % PTB VBLTimestampingMode（空=使用 PTB 默认）

% ---- 界面文本 ----
config.ui.illegal_message_duration_sec = 0.8;       % 非法动作提示时长（秒）
config.ui.title_text = '四子棋';
config.ui.instruction_text = ['实验说明：\n' ...
    '1) 使用方向键移动光标（上下左右）\n' ...
    '2) 使用确认键落子\n' ...
    '3) 共进行固定试次，对局将自动推进\n' ...
    '4) 按 ESC 可中止实验'];
config.ui.show_config_summary = true;               % 开始页是否显示配置摘要
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
config.timing.inter_trial_interval_sec = 0.0;       % 局间间隔（秒）:在结果页停留时间基础上额外增加的间隔
config.timing.key_release_guard_sec = 0.15;         % 防连按释放等待上限（秒）:用于过滤过快的连续按键，避免误操作被识别为多次输入

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
config.marker.callback = @(event_code, event_name, timestamp, payload) ...
    send_marker(event_code, event_name, timestamp, payload, config.marker); % marker 回调函数（并口发码）

% ---- Agent ----
config.agent.player_fn = @random_agent_play;        % 可替换 agent：函数句柄或函数名字符串
config.agent.move_delay_sec = 0.0;                  % 电脑落子后额外延迟（秒）:推荐在agent内部实现更自然的思考时间，此处为全局额外延迟。

% ---- 日志 ----
config.logging.enable = true;
config.logging.save_dir = 'logs';                   % 日志保存目录（相对路径，run_game 会转为绝对）

% ---- 事件码映射表 ----
config.events = marker_name_to_code();
end
