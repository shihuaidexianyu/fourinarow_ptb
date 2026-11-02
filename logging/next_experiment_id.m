function experiment_id = next_experiment_id()
%NEXT_EXPERIMENT_ID 生成一次 run_game 使用的实验 ID（字符串）。
%   策略：使用当前时间戳（毫秒精度）。

experiment_id = char(datetime('now', 'Format', 'yyMMddHHmmssSSS'));
end
