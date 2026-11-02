function emit_marker(config, event_name, timestamp, payload)
%EMIT_MARKER 统一 marker 发射接口。
%   根据事件名查找事件码，通过 config.marker.callback 发送。

if ~config.marker.enable
    return;
end

if ~isKey(config.events, event_name)
    error('MarkerError:UnknownEvent', 'Unknown marker event: %s', event_name);
end

event_code = config.events(event_name);
config.marker.callback(event_code, event_name, timestamp, payload);
end
