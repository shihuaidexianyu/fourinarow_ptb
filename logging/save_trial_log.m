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
