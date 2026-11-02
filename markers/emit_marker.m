function emit_marker(config, event_name, timestamp, payload)
%EMIT_MARKER 统一 marker 发射接口。
%   根据事件名查找事件码，再交给并口发送函数。

if ~config.marker.enable
    return;
end

if ~isKey(config.events, event_name)
    error('MarkerError:UnknownEvent', 'Unknown marker event: %s', event_name);
end

event_code = config.events(event_name);
send_marker(event_code, event_name, timestamp, payload, config.marker);
end
