function trial = finalize_trial_log(trial, state)
%FINALIZE_TRIAL_LOG 填写结束时间与最终结果。

trial.end_datetime = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
trial.result  = state.result;
trial.aborted = strcmp(state.result, 'aborted');
end
