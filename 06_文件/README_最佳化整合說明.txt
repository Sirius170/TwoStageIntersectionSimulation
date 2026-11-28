Wu V4 + PSO / SA 整合說明
===========================

本次整合基準
------------
1. 唯一模擬核心：02_模擬核心/runWuProjectV2Simulation.m
2. 固定週期：78 秒。
3. 黃燈：每個相位 3 秒；全紅：每個相位 1.5 秒。
4. 四相位綠燈總和：78 - 4*(3+1.5) = 60 秒。
5. 四相位綠燈上下界：每相位 10 至 30 秒。
6. 號誌順序：[EW直行, EW保護左轉, NS直行, NS保護左轉]。
7. 目前 Cost：Wu V4 回傳的 totalWaitSeconds（汽車與機車累積停等）。
8. 行人尚未在此核心中模擬；evaluateSignalPlan 的 details 預留
   pedestrianWaitSeconds 欄位，但不納入目前 Cost。

新增檔案
--------
04_評分與計算/getSignalOptimizationConfig.m
    PSO、SA 共用的週期、綠燈上下界、初始解及模擬條件。
    未來若決定變動週期，優先從這個設定介面擴充。

04_評分與計算/evaluateSignalPlan.m
    PSO、SA 共用目標函數。檢查四相位綠燈總和與上下界，
    呼叫 Wu V4 核心，回傳單一 Cost。
    保存並還原 MATLAB 全域亂數狀態，避免模擬核心 rng(7)
    重設最佳化演算法使用的全域亂數序列。

修改檔案
--------
02_模擬核心/runWuProjectV2Simulation.m
    新增第 9 個參數 enableVisualization，預設 true。
    enableVisualization=false 時不建立/更新圖形，但仍執行車流生成、
    號誌判斷、車輛移動、跟車及等待時間計算。
    舊有 8 個參數呼叫方式仍有效。

Optimization/PSO/run_pso.m
    改呼叫 evaluateSignalPlan，不再呼叫舊版 START_HERE2。
    PSO 保留 particleswarm、SwarmSize、MaxIterations、OutputFcn。
    為維持固定週期，PSO 使用 3 個連續決策變數，第四相位由
    60 - sum前三相位推導；第四相位不在 [10,30] 時施加大懲罰。
    PSO 仍允許小數秒，沒有在搜尋過程中 round。

Optimization/SA/run_sa.m
    改呼叫 evaluateSignalPlan，不再呼叫舊版 START_HERE2。
    保留 simulannealbnd、初始溫度、再退火間隔、評估上限、
    接受機制及收斂輸出。
    SA 鄰域由獨立改動各相位，調整為相位間整數秒數轉移，
    每次轉移均維持四相位綠燈總和 60 秒及各相位上下界。
    這是固定週期限制所需的鄰域適配，不更改 SA 接受機率或退火排程。

檢查方式
--------
在 MATLAB 執行：
    05_檢查工具/CHECK_OPTIMIZATION_INTEGRATION.m

通過後再分別執行：
    Optimization/PSO/run_pso.m
    Optimization/SA/run_sa.m

重要限制
--------
- 本環境未安裝 MATLAB，無法在此直接執行 MATLAB/Optimization Toolbox。
  因此本次完成程式碼整合與靜態檢查，尚不能宣稱已通過 MATLAB 實機測試。
- PSO 的 3 維參數化保留連續 PSO 搜尋機制，但搜尋空間表示方式有改變。
- SA 的鄰域必須改成時間轉移，否則每次提案會破壞固定週期。
- 當前 Cost 不包含行人等待時間。
- 模擬核心內的交通邏輯、汽機車路徑與兩段式左轉判斷未為配合最佳化而改寫。
- 原本 START_HERE2.m 及 run_START_HERE2.m 保留，僅不再作為 PSO/SA 的目標函數。
