% CHECK_OPTIMIZATION_INTEGRATION
% Integration smoke test for the fixed-cycle Wu V4 + PSO/SA interface.
% Run this script before launching a full optimization.

clear; clc;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));

config = getSignalOptimizationConfig();

fprintf('固定週期：%.1f 秒\n',config.cycleSeconds);
fprintf('四相位綠燈總和：%.1f 秒\n',config.totalGreenSeconds);
fprintf('單一相位綠燈範圍：[%.1f, %.1f] 秒\n', ...
    config.minGreenSeconds,config.maxGreenSeconds);

% Baseline must satisfy the fixed-cycle constraints.
baseline = config.initialPhases;
assert(abs(sum(baseline)-config.totalGreenSeconds)<1e-9);
assert(all(baseline>=config.minGreenSeconds & ...
           baseline<=config.maxGreenSeconds));

% A second feasible continuous plan confirms decimal seconds are accepted.
decimalPlan = [14.5 15.5 14.0 16.0];
assert(abs(sum(decimalPlan)-config.totalGreenSeconds)<1e-9);
decimalCost = evaluateSignalPlan(decimalPlan);
assert(isfinite(decimalCost) && decimalCost>=0);

% Invalid plan must be rejected before starting the traffic simulation.
invalidRejected = false;
try
    evaluateSignalPlan([15 15 15 16]);
catch ME
    invalidRejected = strcmp(ME.identifier,'evaluateSignalPlan:FixedCycle');
end
assert(invalidRejected,'An invalid fixed-cycle plan was not rejected.');

% Execute one full headless baseline simulation through the same objective
% function used by PSO and SA.
[cost,details] = evaluateSignalPlan(baseline);
assert(isfinite(cost) && cost>=0);
assert(details.pedestrianIncluded==false);
assert(isnan(details.pedestrianWaitSeconds));

fprintf('\n整合測試通過。\n');
fprintf('Baseline phases: %s\n',mat2str(baseline));
fprintf('Baseline Cost: %.3f seconds\n',cost);
fprintf('Decimal-plan Cost: %.3f seconds\n',decimalCost);
fprintf('Two-stage waiting: %.3f seconds\n',details.twoStageWaitSeconds);
fprintf('Pedestrian waiting: reserved, not included yet.\n');
