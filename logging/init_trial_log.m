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
