function send_marker(event_code, event_name, timestamp, marker_cfg)
%SEND_MARKER 初始化 IO64 并发送一个短并口脉冲。

persistent io_obj io_ready address pulse_width_sec
if isempty(io_ready)
    address = hex2dec(char(marker_cfg.parallel_port_address));
    pulse_width_sec = double(marker_cfg.pulse_width_sec);

    try
        io_obj = io64();
        status = io64(io_obj);
        if status ~= 0
            error('IO64:InitializationFailed', 'Could not initialize the parallel-port driver.');
        end
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

io64(io_obj, address, round(double(event_code)));
WaitSecs(pulse_width_sec);
io64(io_obj, address, 0);
end
