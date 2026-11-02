function event_map = marker_name_to_code()
%MARKER_NAME_TO_CODE 固定的事件名到事件码映射表。

% eeg为8位输入端口，事件码范围为0-255，0通常用作复位信号，因此事件码从1开始编号。
% 事件码的具体数值没有特殊意义，但必须保持一致以确保数据分析

event_map = containers.Map();

% 状态类
event_map('session_enter_game') = 1;
event_map('game_start')         = 2;
event_map('game_abort_esc')     = 3;

% 行为响应类
event_map('response_human_move')    = 4;
event_map('response_illegal_click') = 5;
event_map('response_agent_move')    = 6;

% 视觉呈现类
event_map('stimulus_human_move_shown') = 7;
event_map('stimulus_agent_move_shown') = 8;
event_map('stimulus_result_shown')     = 9;

% 结局类
event_map('game_end_black_win') = 10;
event_map('game_end_white_win') = 11;
event_map('game_end_draw')      = 12;
end
