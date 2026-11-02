function send_marker(event_code, event_name, timestamp, ~, marker_cfg)
%SEND_MARKER 通过并口发送 EEG marker。
%   按 test.m 的硬件流程发码：outp(address, code) -> 短脉冲 -> outp(address, 0)。

event_code = round(double(event_code));
persistent io_ready address pulse_width_sec

if isempty(io_ready)
    address = hex2dec(char(marker_cfg.parallel_port_address));
    pulse_width_sec = double(marker_cfg.pulse_width_sec);

    try
        config_io;
        io_ready = true;
    catch ME
        warning('MarkerWarning:IOUnavailable', ...
            'Marker I/O init failed (%s). Falling back to console print.', ME.message);
        io_ready = false;
    end
end

if ~io_ready
    fprintf('[MARKER:FALLBACK] code=%d name=%s time=%.6f\n', event_code, event_name, timestamp);
    return;
end

outp(address, event_code);
WaitSecs(pulse_width_sec);
outp(address, 0);

end
