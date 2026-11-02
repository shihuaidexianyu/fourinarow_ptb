function [nx, ny, textbounds] = draw_text(win, text, x, y, color, varargin)
%DRAW_TEXT 支持中文的文本绘制函数。
%   使用 Screen('DrawText') 逐行渲染，避免 DrawFormattedText 对 CJK
%   double 数组的字宽计算问题。支持 'center' 定位和 \n 多行文本。

% 转为 double 数组（PTB 以 Unicode 码点渲染中文）
if ischar(text)
    text_chars = double(text);
else
    text_chars = text;
end

% 按换行符拆分为多行
lines = split_lines(text_chars);

rect  = Screen('Rect', win);
win_w = rect(3);
win_h = rect(4);

% ---- 测量每行宽高 ----
n_lines      = numel(lines);
line_bounds  = cell(n_lines, 1);
line_widths  = zeros(n_lines, 1);
line_heights = zeros(n_lines, 1);
for i = 1:n_lines
    b = Screen('TextBounds', win, lines{i});
    line_bounds{i} = b;
    line_widths(i)  = b(3) - b(1);
    line_heights(i) = b(4) - b(2);
end

line_spacing = 1.2;              % 行距倍率
single_h = max(line_heights);
if single_h == 0
    single_h = Screen('TextSize', win);
end
total_h = single_h * n_lines + single_h * (line_spacing - 1) * (n_lines - 1);
step_h  = single_h * line_spacing;

% ---- 计算起始 Y ----
if ischar(y) && strcmp(y, 'center')
    start_y = round((win_h - total_h) / 2);
else
    start_y = y;
end

% ---- 逐行绘制 ----
nx = 0;
ny = start_y;
textbounds = [inf, inf, -inf, -inf];

for i = 1:n_lines
    cur_y = start_y + (i - 1) * step_h;

    if ischar(x) && strcmp(x, 'center')
        cur_x = round((win_w - line_widths(i)) / 2);
    else
        cur_x = x;
    end

    Screen('DrawText', win, lines{i}, cur_x, cur_y, color);

    nx = cur_x + line_widths(i);
    ny = cur_y + single_h;
    textbounds = [min(textbounds(1), cur_x), min(textbounds(2), cur_y), ...
                  max(textbounds(3), nx), max(textbounds(4), ny)];
end
end

function lines = split_lines(chars)
%SPLIT_LINES 将 double 数组按换行符（code 10）或字面 \n 序列拆分。
nl     = 10;
bs     = double('\');
n_char = double('n');

% 将字面 \n 替换为真正的换行符
expanded = [];
i = 1;
while i <= numel(chars)
    if i < numel(chars) && chars(i) == bs && chars(i+1) == n_char
        expanded = [expanded, nl]; %#ok<AGROW>
        i = i + 2;
    else
        expanded = [expanded, chars(i)]; %#ok<AGROW>
        i = i + 1;
    end
end

% 按换行符分割
idx = find(expanded == nl);
if isempty(idx)
    lines = {expanded};
    return;
end

lines = {};
prev = 1;
for k = 1:numel(idx)
    lines{end+1} = expanded(prev:idx(k)-1); %#ok<AGROW>
    prev = idx(k) + 1;
end
lines{end+1} = expanded(prev:end);
end
