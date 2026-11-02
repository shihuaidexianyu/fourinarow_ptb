function debug_key_name_probe()
%DEBUG_KEY_NAME_PROBE 键盘联调小工具：按键后打印 PTB 键名。
%   使用方式：在 MATLAB 命令行执行 debug_key_name_probe
%   说明：
%     1) 按任意键，会打印按下沿对应的键名
%     2) 支持一次同时识别多个按键
%     3) 按 ESC 退出

if ~exist('KbCheck', 'file') || ~exist('KbName', 'file')
    error('DependencyError:PsychtoolboxMissing', ...
        'Psychtoolbox keyboard functions (KbCheck/KbName) are not available.');
end

KbName('UnifyKeyNames');
esc_code = KbName('ESCAPE');

fprintf('\n=== Key Probe Started ===\n');
fprintf('按任意键查看 PTB 键名；按 ESC 退出。\n\n');

[~, ~, last_key_code] = KbCheck(-1);

while true
    [is_down, key_time, key_code] = KbCheck(-1);

    if ~is_down
        last_key_code = false(size(key_code));
        WaitSecs(0.005);
        continue;
    end

    pressed_edge = key_code & ~last_key_code;
    pressed_idx = find(pressed_edge);

    if ~isempty(pressed_idx)
        key_names = KbName(pressed_idx);
        if ischar(key_names)
            key_names = {key_names};
        end

        fprintf('[%.6f] 按下: %s\n', key_time, strjoin(key_names, ', '));

        if any(pressed_idx == esc_code)
            fprintf('\n收到 ESC，退出 key probe。\n');
            break;
        end
    end

    last_key_code = key_code;
    WaitSecs(0.005);
end
end
