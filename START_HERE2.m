% 隔離本次模擬對全域亂數串流的影響；函數結束時自動恢復
rngState = rng;
rngCleanup = onCleanup(@() rng(rngState)); 

function [totalWaitTime, details] = START_HERE2(testPhases)
% START_HERE2.m - 計算總停等 Cost，並可選擇回傳同一次模擬的逐車資料
% 舊用法仍相容：cost = START_HERE2(phases)
% 新用法：[cost, details] = START_HERE2(phases)

% 1. 動態路徑
currentFolder = fileparts(mfilename('fullpath'));
otlRoot = fileparts(currentFolder);
addpath(otlRoot, fullfile(otlRoot, 'Testing'));

% 2. 模擬設定（維持現行設定）
inflow = [800 800 500 500];
turnWeights = [20 60 20];
phaseSeconds = testPhases;
simulationSeconds = 100;
penaltyTime = 500;
sampleTime = 0.05;

% 3. 輸入檢查
assert(numel(inflow) == 4 && all(isfinite(inflow)) && all(inflow >= 0), ...
    'inflow 必須是 4 個非負有限數值。');
assert(numel(phaseSeconds) == 4 && all(isfinite(phaseSeconds)) && all(phaseSeconds > 0), ...
    'testPhases 必須是 4 個正的有限數值。');
assert(numel(turnWeights) == 3 && all(turnWeights >= 0) && sum(turnWeights) > 0, ...
    'turnWeights 必須是 3 個非負數值，且總和大於 0。');

% 4. 建立並執行模擬
s = createFourWayJunctionScenario();
s.StopTime = simulationSeconds;
s.SampleTime = sampleTime;

net = createFourWayJunctionNetwork(s);
cars = createVehiclesForFourWayJunction(s, net, inflow, turnWeights);

traffic = trafficControl.TrafficLight(net(9:end), ...
    'Cliques', [1 1 1 2 2 2 3 3 3 4 4 4], ...
    'Cycle', [0 cumsum(phaseSeconds)]); %#ok<NASGU>

initializeOTLScenario(s);
while advance(s)
end

% 5. 擷取所有生成車輛的紀錄；不改變原有 Cost 規則
numCars = length(cars);
vehicleIDs = (1:numCars)';
hasMotionStrategy = false(numCars, 1);
enteredNetwork = false(numCars, 1);
waitTimes = nan(numCars, 1);
avgSpeeds = nan(numCars, 1);
optimizerPenalty = zeros(numCars, 1);
vehicleStatus = strings(numCars, 1);
speedHistory = cell(numCars, 1);
totalWaitTime = 0;

for i = 1:numCars
    if isempty(cars(i).MotionStrategy)
        % 原有 Cost 規則：MotionStrategy 為空的車不計入 Cost。
        % 仍保留該車的 ID 與狀態，避免逐車清單漏掉生成車輛。
        vehicleStatus(i) = "NoMotionStrategy";
        speedHistory{i} = [];
        continue;
    end

    hasMotionStrategy(i) = true;
    thisSpeed = cars(i).MotionStrategy.Data.Speed;
    speedHistory{i} = thisSpeed(:)';

    if isempty(thisSpeed)
        % 場外虛擬排隊車：維持原有 penaltyTime 懲罰
        waitTimes(i) = simulationSeconds;
        avgSpeeds(i) = 0;
        optimizerPenalty(i) = penaltyTime;
        vehicleStatus(i) = "VirtualQueue";
        totalWaitTime = totalWaitTime + penaltyTime;
    else
        % 有速度歷程的車：依原有規則計算停等時間
        waitSteps = sum(thisSpeed < 0.5);
        waitTimes(i) = waitSteps * s.SampleTime;
        avgSpeeds(i) = mean(thisSpeed);
        enteredNetwork(i) = true;
        vehicleStatus(i) = "EnteredNetwork";
        totalWaitTime = totalWaitTime + waitTimes(i);
    end
end

% 6. 第二輸出：保留同一次模擬的逐車原始速度歷程與統計
details = struct();
details.PhaseSeconds = phaseSeconds(:)';
details.Inflow = inflow;
details.TurnWeights = turnWeights;
details.SimulationSeconds = simulationSeconds;
details.SampleTime = s.SampleTime;
details.PenaltyTime = penaltyTime;
details.VehicleID = vehicleIDs;
details.VehicleStatus = vehicleStatus;
details.HasMotionStrategy = hasMotionStrategy;
details.EnteredNetwork = enteredNetwork;
details.WaitTime_sec = waitTimes;
details.AvgSpeed_mps = avgSpeeds;
details.OptimizerPenalty_sec = optimizerPenalty;
details.SpeedHistory_mps = speedHistory;
details.TotalGeneratedCars = numCars;
details.EnteredCount = sum(enteredNetwork);
details.VirtualQueueCount = sum(vehicleStatus == "VirtualQueue");
details.NoMotionStrategyCount = sum(vehicleStatus == "NoMotionStrategy");
details.RealTotalWaitTime_sec = sum(waitTimes(~isnan(waitTimes)));
details.OptimizerCost_sec = totalWaitTime;

fprintf('testPhases: [%s] | totalWaitTime: %.2f s | cars: %d\n', ...
    num2str(phaseSeconds), totalWaitTime, numCars);
end