function run_game()
%RUN_GAME 程序入口。
%   设置路径、加载配置后启动主循环。

this_file = mfilename('fullpath');
app_dir = fileparts(this_file);
project_root = fileparts(app_dir);
addpath(genpath(project_root));  % 将所有子目录加入搜索路径

config = load_config();
config.runtime.project_root = project_root;
config.logging.save_dir = fullfile(project_root, config.logging.save_dir);  % 转为绝对路径
main_loop(config);
end
