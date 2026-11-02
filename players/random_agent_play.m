function [action, meta] = random_agent_play(obs, ~, ~)
%RANDOM_AGENT_PLAY 随机 agent：从合法动作中均匀随机选一个。

legal = obs.legal_actions;
if isempty(legal)
    error('AgentError:NoLegalAction', ...
        'random_agent_play received an empty legal action list while the game is still ongoing.');
end

if ~ismatrix(legal) || size(legal, 2) ~= 2
    error('AgentError:InvalidLegalActions', ...
        'obs.legal_actions must be an N-by-2 matrix of [row, col].');
end

idx = randi(size(legal, 1));       % 均匀随机选择
action.row = legal(idx, 1);
action.col = legal(idx, 2);
meta = struct('type', 'random', 'candidate_count', size(legal, 1));
end
