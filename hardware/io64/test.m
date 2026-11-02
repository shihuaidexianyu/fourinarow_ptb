config_io();

address = hex2dec('0FF8'); % 按设备管理器中的实际并口地址修改。

% 每秒发送 1–100，单次脉冲持续 4 ms；按 Ctrl+C 可停止。
for event_code = 1:100
    WaitSecs(1);

    outp(address, event_code);
    WaitSecs(0.004);
    outp(address, 0);

    disp(event_code);
end
