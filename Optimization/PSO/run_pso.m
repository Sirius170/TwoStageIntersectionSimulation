% run_pso.m
% PSO on the Wu V4 simulation core, with a fixed 78-second signal cycle.
% The PSO update mechanism and continuous-valued search are retained.
clear; clc;

% 1. Project path: resolve from this script, not MATLAB's Current Folder.
currentFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(currentFolder));
addpath(genpath(projectRoot));

config = getSignalOptimizationConfig();

% 2. Fixed-cycle decision-variable mapping.
% PSO still searches continuously. It searches three green times; the
% fourth is derived so that all four green times sum to 60 seconds.
% This is a constraint parameterization, not a replacement PSO algorithm.
numVars = 3;
lb = config.minGreenSeconds * ones(1,numVars);
ub = config.maxGreenSeconds * ones(1,numVars);
maxIter = 40;
popSize = 20;
paramTag = ['_Pop', num2str(popSize)];

global pso_history;
pso_history = [];

options = optimoptions('particleswarm', ...
    'SwarmSize', popSize, ...
    'MaxIterations', maxIter, ...
    'Display', 'off', ...
    'OutputFcn', @psoOutput);

disp('開始執行 PSO 最佳化（Wu V4，固定週期 78 秒）...');
totalTimer = tic;
[bestX, optimizerBestCost] = particleswarm( ...
    @psoObjective, numVars, lb, ub, options);

% Decode the optimizer's 3 continuous variables into the 4-phase plan.
[bestPhases, isFeasible] = decodePsoPlan(bestX,config);
if ~isFeasible
    error('run_pso:NoFeasibleBestPlan', ...
        ['PSO returned no feasible 78-second plan. ' ...
         'Check the objective penalty and search settings.']);
end

% Re-evaluate through the same deterministic traffic conditions.
bestCost = evaluateSignalPlan(bestPhases);
initialPhases = config.initialPhases;
initialCost = evaluateSignalPlan(initialPhases);
totalElapsed = toc(totalTimer);

% 3. Results
disp('============= PSO 最佳化完成 =============');
disp(['最佳號誌秒數 [EW直行 EW左轉 NS直行 NS左轉]: ', num2str(bestPhases)]);
disp(['該組合的總停等時間 (Cost): ', num2str(bestCost), ' 秒']);
disp(['固定週期: ', num2str(config.cycleSeconds), ' 秒']);
disp(['PSO 最佳目標值（搜尋結束時）: ', num2str(optimizerBestCost)]);
disp(['總執行時間: ', num2str(totalElapsed, '%.2f'), ' 秒']);

disp(newline);
disp('----------------------------------------');
disp(['初始號誌 [15 15 15 15] 總停等時間: ', num2str(initialCost), ' 秒']);
if abs(initialCost) > eps
    improvement = ((initialCost-bestCost)/initialCost)*100;
else
    improvement = NaN;
end
disp(['總停等時間改善比例: ', num2str(improvement, '%.2f'), ' %']);
disp('========================================');

% 4. Export convergence history and elapsed time.
if ~isempty(pso_history)
    historyTable = table( ...
        pso_history(:,1), pso_history(:,2), ...
        repmat(totalElapsed,size(pso_history,1),1), ...
        'VariableNames',{'Iteration','BestCost','TotalElapsedSeconds'});

    baseName = ['PSO_',num2str(maxIter),paramTag,'_Convergence_Curve'];
    runNum = 1;
    reservePath = '';
    while true
        runTag = sprintf('_Run%03d',runNum);
        fileName = [baseName,runTag,'.xlsx'];
        savePath = fullfile(currentFolder,fileName);
        reservePath = fullfile(currentFolder,[baseName,runTag,'.reserve']);
        if ~exist(savePath,'file')
            reserveFile = javaObject('java.io.File',reservePath);
            if reserveFile.createNewFile(), break; end
        end
        runNum = runNum+1;
    end

    fprintf('本次模擬編號：第 %d 次\n',runNum);
    try
        writetable(historyTable,savePath);
        disp(['收斂曲線已匯出至： ',savePath]);
        if exist(reservePath,'file'), delete(reservePath); end
    catch ME
        if exist(reservePath,'file'), delete(reservePath); end
        rethrow(ME);
    end
end

% -------------------------------------------------------------------------
% PSO objective adapter: 3 continuous variables -> 4-phase fixed-cycle plan.
% -------------------------------------------------------------------------
function cost = psoObjective(x)
config = getSignalOptimizationConfig();
[phasePlan,isFeasible,violation] = decodePsoPlan(x,config);

if ~isFeasible
    % A large finite penalty keeps particleswarm running while steering
    % particles back into the feasible simplex. No simulation is run.
    cost = 1e9 + 1e7*(violation^2);
    return;
end

cost = evaluateSignalPlan(phasePlan);
end

function [phasePlan,isFeasible,violation] = decodePsoPlan(x,config)
x = reshape(x,1,[]);
phasePlan = [x, config.totalGreenSeconds-sum(x)];
violation = max(0,config.minGreenSeconds-phasePlan(4)) + ...
            max(0,phasePlan(4)-config.maxGreenSeconds);
isFeasible = numel(x)==3 && all(isfinite(phasePlan)) && ...
    all(phasePlan(1:3)>=config.minGreenSeconds-1e-8) && ...
    all(phasePlan(1:3)<=config.maxGreenSeconds+1e-8) && ...
    phasePlan(4)>=config.minGreenSeconds-1e-8 && ...
    phasePlan(4)<=config.maxGreenSeconds+1e-8;
if isFeasible
    % Remove floating-point residue without rounding continuous PSO values.
    phasePlan(4) = config.totalGreenSeconds-sum(phasePlan(1:3));
end
end

% --- Existing convergence listener retained ---
function stop = psoOutput(optimValues,state)
global pso_history;
if strcmp(state,'iter')
    pso_history = [pso_history; optimValues.iteration,optimValues.bestfval];
    fprintf('代數 (Iteration): %2d | 目前最佳總停等時間: %7.2f 秒\n', ...
        optimValues.iteration,optimValues.bestfval);
end
stop = false;
end
