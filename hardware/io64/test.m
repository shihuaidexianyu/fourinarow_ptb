config_io;
global cogent;
if( cogent.io.status ~= 0 )
   error('inp/outp installation failed');
end

address = hex2dec('0FF8');
%单引号内为并口地址， 需要根据个人电脑的实际地址添加。 打开设备管理器，找到并口，查看属性→资源 即可看到。

%下方代码可以每秒发送一个mark， mark值从1开始逐次增加到100
for i=1:100;
WaitSecs(1);

outp(address,i);
WaitSecs(0.004);
outp(address,0);

disp(i);

end


%脚本运行后 按ctrl+c可中断程序
