function state = init_game(config)
%INIT_GAME 初始化游戏状态。
%   创建空棋盘并设定初始字段。

rows = config.game.rows;
cols = config.game.cols;

state.board = zeros(rows, cols);            % 棋盘矩阵：0=空, 1=黑, 2=白
state.connect_n = config.game.connect_n;    % 连几子获胜
state.current_player = config.game.first_player;
state.first_player = config.game.first_player;
state.move_count = 0;                       % 已完成的合法落子数
state.last_action = [];                     % 上一步动作 struct 或空
state.game_over = false;
state.result = 'ongoing';                   % 'ongoing'|'black_win'|'white_win'|'draw'|'aborted'
state.winning_cells = zeros(0, 2);          % 胜利连线上的坐标 [row, col]
state.winning_line = struct('start_row', [], 'start_col', [], 'end_row', [], 'end_col', []);
end
