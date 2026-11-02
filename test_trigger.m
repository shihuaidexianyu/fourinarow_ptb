function test_trigger()
%TEST_TRIGGER 独立联调并口：每秒发送 1–100，每个脉冲持续 4 ms。

project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'hardware', 'io64'));
marker_cfg.parallel_port_address = '0FF8'; % 按设备管理器中的实际并口地址修改
marker_cfg.pulse_width_sec = 0.004;

for event_code = 1:100
    WaitSecs(1);
    send_marker(event_code, sprintf('manual_test_%03d', event_code), GetSecs(), marker_cfg);
    disp(event_code);
end
end
