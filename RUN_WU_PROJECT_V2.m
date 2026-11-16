% RUN_WU_PROJECT_V2.m
% One-click integration demo: Wu V4 road + Project_v2 car/motorcycle logic.
clearvars;
close all;
clc;

root = fileparts(mfilename('fullpath'));
addpath(root);

% [東西直行, 東西保護左轉, 南北直行, 南北保護左轉] seconds
phaseSeconds = [20 8 20 8];     % 四種號誌相位秒數
simulationSeconds = 120;        % 模擬總時間
inflow = [300 300 300 300];     % vehicles/hour, order: W E N S
turnWeights = [20 60 20];       % left / straight / right
playbackSpeed = 5;              % 播放速度
motorcycleShare = 0.35;         % 機車比例
showPaths = false;              % 是否顯示兩段式路線
carFollowingModel = 'Gipps';    % 車輛跟車模型'Gipps' or 'IDM'

result = runWuProjectV2Simulation(phaseSeconds,simulationSeconds, ...
    inflow,turnWeights,playbackSpeed,motorcycleShare,showPaths,carFollowingModel);
