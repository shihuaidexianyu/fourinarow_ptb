function config_io()
%CONFIG_IO 初始化 IO64 并检查并口驱动是否可用。

global cogent;

% IO64 使用全局对象供 inp.m 和 outp.m 读取。
cogent.io.ioObj = io64();

cogent.io.status = io64(cogent.io.ioObj);
if cogent.io.status ~= 0
    error('IO64:InitializationFailed', 'Could not initialize the parallel-port driver.');
end
end
