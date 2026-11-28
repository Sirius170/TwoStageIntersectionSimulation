% export_data.m - 從指定 Run 的保存檔匯出，不重新模擬
clear; clc;

% 1. 指定要匯出的原始 Run（請依實際檔名修改）
runDetailsFile = 'CPODE_40_Pop20_Convergence_Curve_Run010_Details.mat';

currentFolder = fileparts(mfilename('fullpath'));
detailsDir = fullfile(currentFolder, 'CPODE');
detailsPath = fullfile(detailsDir, runDetailsFile);

if ~exist(detailsPath, 'file')
    error('export_data:RunFileNotFound', ...
        ['找不到指定 Run 的原始資料檔：', detailsPath, newline, ...
         '請先確認檔名，或使用新版 run_cpo.m 產生包含逐車資料的 MAT 檔。', newline, ...
         '本程式不會重新模擬來代替缺失的原始資料。']);
end

loadedData = load(detailsPath, 'runData');
if ~isfield(loadedData, 'runData') || ...
   ~isfield(loadedData.runData, 'BestDetails')
    error('export_data:InvalidRunFile', ...
        '指定 MAT 檔沒有 runData.BestDetails，無法確認其中包含逐車原始資料。');
end

runData = loadedData.runData;
if ~isfield(runData, 'RandomSeed') || isempty(runData.RandomSeed)
    error('export_data:MissingRandomSeed', ...
        '指定 MAT 檔沒有 runData.RandomSeed；請勿猜測或補填種子值。');
end
d = runData.BestDetails;

requiredFields = {'VehicleID','VehicleStatus','HasMotionStrategy', ...
    'EnteredNetwork','WaitTime_sec','AvgSpeed_mps', ...
    'OptimizerPenalty_sec','SpeedHistory_mps'};
for k = 1:numel(requiredFields)
    if ~isfield(d, requiredFields{k})
        error('export_data:MissingField', ...
            '原始資料缺少必要欄位：%s', requiredFields{k});
    end
end

% 2. 整理逐車摘要與原始速度歷程
speedHistoryText = strings(numel(d.VehicleID), 1);
for i = 1:numel(d.VehicleID)
    speedHistoryText(i) = string(mat2str(d.SpeedHistory_mps{i}));
end

resultsTable = table( ...
    d.VehicleID(:), ...
    d.VehicleStatus(:), ...
    d.HasMotionStrategy(:), ...
    d.EnteredNetwork(:), ...
    d.WaitTime_sec(:), ...
    d.AvgSpeed_mps(:), ...
    d.OptimizerPenalty_sec(:), ...
    'VariableNames', {'VehicleID','VehicleStatus','HasMotionStrategy', ...
    'EnteredNetwork','WaitTime_sec','AvgSpeed_mps','OptimizerPenalty_sec'});

speedTable = table(d.VehicleID(:), speedHistoryText, ...
    'VariableNames', {'VehicleID','SpeedHistory_mps'});

% 3. 建立 Run 設定與統計
Setting_Names = {
    'Source_MAT_File';
    'Run_ID';
    'Algorithm';
    'Max_Iterations';
    'Population_Size';
    'RandomSeed';
    'Best_Phases';
    'Best_Cost_sec';
    'Initial_Phases';
    'Initial_Cost_sec';
    'Inflow';
    'Turn_Weights';
    'Simulation_Time_sec';
    'Sample_Time_sec';
    'Penalty_Time_sec';
    'Total_Generated_Cars';
    'Entered_Cars';
    'Virtual_Queue_Cars';
    'No_MotionStrategy_Cars';
    'Real_Total_Wait_Time_sec';
    'Optimizer_Cost_sec';
    'Total_Elapsed_sec';
    'Record_Source'
    };

Setting_Values = {
    runDetailsFile;
    char(string(runData.RunID));
    char(string(runData.Algorithm));
    num2str(runData.MaxIterations);
    num2str(runData.PopulationSize);
    num2str(runData.RandomSeed);
    mat2str(runData.BestPhases);
    num2str(runData.BestCost, '%.10g');
    mat2str(runData.InitialPhases);
    num2str(runData.InitialCost, '%.10g');
    mat2str(d.Inflow);
    mat2str(d.TurnWeights);
    num2str(d.SimulationSeconds);
    num2str(d.SampleTime);
    num2str(d.PenaltyTime);
    num2str(d.TotalGeneratedCars);
    num2str(d.EnteredCount);
    num2str(d.VirtualQueueCount);
    num2str(d.NoMotionStrategyCount);
    num2str(d.RealTotalWaitTime_sec, '%.10g');
    num2str(d.OptimizerCost_sec, '%.10g');
    num2str(runData.TotalElapsedSeconds, '%.10g');
    'Captured during the selected optimization Run; no re-simulation'
    };

settingsTable = table(Setting_Names, Setting_Values, ...
    'VariableNames', {'Parameter','Value'});

% 4. 匯出 Excel；既有檔案一律保留，不覆蓋
saveDir = detailsDir;
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

baseName = [char(string(runData.Algorithm)), '_', ...
    num2str(runData.MaxIterations), '_Pop', ...
    num2str(runData.PopulationSize), '_', ...
    char(string(runData.RunID)), '_Best_Simulation_Data'];

runNum = 1;
reservePath = '';
while true
    if runNum == 1
        fileName = [baseName, '.xlsx'];
    else
        fileName = [baseName, '_v', num2str(runNum), '.xlsx'];
    end
    savePath = fullfile(saveDir, fileName);
    reservePath = fullfile(saveDir, [fileName, '.reserve']);

    if ~exist(savePath, 'file') && ~exist(reservePath, 'file')
        reserveFile = javaObject('java.io.File', reservePath);
        if reserveFile.createNewFile()
            break;
        end
    end
    runNum = runNum + 1;
end

try
    writetable(resultsTable, savePath, 'Sheet', 'Detailed_Data');
    writetable(speedTable, savePath, 'Sheet', 'Speed_History');
    writetable(settingsTable, savePath, 'Sheet', 'Basic_Settings');

    disp('匯出完成：使用已保存的 Run 原始資料，沒有重新模擬。');
    disp(['來源 MAT 檔：', detailsPath]);
    disp(['Excel 檔案：', savePath]);
    disp(['Run ID：', char(string(runData.RunID)), ...
        ' | RandomSeed：', num2str(runData.RandomSeed)]);
    disp(['生成車輛數：', num2str(d.TotalGeneratedCars), ...
        ' | 成功進場：', num2str(d.EnteredCount), ...
        ' | 虛擬排隊：', num2str(d.VirtualQueueCount)]);

    if exist(reservePath, 'file')
        delete(reservePath);
    end
catch ME
    if exist(reservePath, 'file')
        delete(reservePath);
    end
    rethrow(ME);
end