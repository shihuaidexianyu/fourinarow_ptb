function draw_start_screen(ui, config)
%DRAW_START_SCREEN 绘制开始页：标题、实验说明、配置摘要与键盘提示。

Screen('FillRect', ui.win, ui.colors.bg);

% 使用顺序布局避免多行文本重叠
y = 60;
[~, y_after_title] = draw_text(ui.win, config.ui.title_text, 'center', y, ui.colors.text);

y = y_after_title + 18;
[~, y_after_instruction] = draw_text(ui.win, config.ui.instruction_text, 'center', y, ui.colors.text);

% 玩家编号 1/2 分别对应黑方/白方。
player_color = {'黑方', '白方'};

summary = sprintf(['棋盘：%d×%d（自由落点）\n' ...
    '人类：%s    电脑：%s\n' ...
    '先手：%s'], ...
    config.game.rows, config.game.cols, ...
    player_color{config.game.human_player}, ...
    player_color{config.game.agent_player}, ...
    player_color{config.game.first_player});
y = y_after_instruction + 20;
[~, y_after_summary] = draw_text(ui.win, summary, 'center', y, ui.colors.text);

y = y_after_summary + 22;
draw_text(ui.win, config.ui.start_hint_text, 'center', y, ui.colors.text);
end
