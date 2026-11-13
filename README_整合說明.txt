Wu + Project_v2 整合測試版
==============================

目標
----
以 Wu V4 作為唯一道路幾何來源，讓 Project_v2 的汽車與機車縱向行駛邏輯
在 Wu 路口上運作，並完成機車兩段式左轉。

檔案
----
RUN_WU_PROJECT_V2.m
    一鍵執行動畫。

runWuProjectV2Simulation.m
    整合模擬主程式。支援汽車、機車、Poisson 車流、Gipps / IDM、
    停止線、號誌、待轉格保留與兩段式左轉。

intersectionMap_v3_twoStage_v4.mat
    Wu 的道路、車道、路徑、停止線、待轉格資料，保持原始檔案。

showRoadV4.m / roadPoseV4.m / drawRoadVehicleV4.m
    Wu 原始道路繪圖、路徑座標查詢、車輛繪圖函式。

setRoadLightsV4.m
    保留 Wu 的 0~4 號誌意義，另外加入 5=東西黃燈、6=南北黃燈，
    供整合版的黃燈與全紅清空時間使用。

checkWuProjectV2Map.m
    檢查 30 條路徑分組，以及 8 組兩段式路線的待轉格端點銜接。

Project_v2_原始參考/
    使用者提供的 Project_v2 原始程式副本，未修改，供對照。

整合方式與重要差異
------------------
1. Wu 的 map.paths 是唯一的車輛位置與方向來源。車輛不再使用舊版
   Project_v2 的 Node / RoadSegment Mapping 直接計算位置。
2. 原 Project_v2 的 Node.setMapping 固定以 3.65 m 作為車道偏移，
   且舊 createFourWayJunctionScenario 使用另一套座標。Wu V4 的座標
   與路徑是獨立設計，直接把舊 Node 網路套上去會造成車道中心與道路
   幾何不一致。因此本整合版保留 Project_v2 的車輛縱向邏輯，將路線、
   位置、方向重新綁定到 Wu 的 pathId。
3. 汽車左轉使用 Wu 的一般左轉路徑與保護左轉相位。
4. 機車左轉使用 Wu 的 firstPathIdsBySlot / secondPathIds：
   - 第一段：東西向來車依東西直行綠燈；南北向來車依南北直行綠燈。
   - 到達指定待轉格後停止，並保留該 slot，避免同一格同時塞入兩台車。
   - 第二段：等待垂直方向直行綠燈，不使用汽車左轉箭頭。
   - 第二段離開待轉格後，待轉格才釋出。
5. 車輛跨過停止線後會繼續清空路口，不會因為號誌切換就停在路口中央。
6. 加入黃燈與全紅清空時間。這是整合版的號誌安全補強；Wu 原始
   setRoadLightsV4 僅負責畫面，並不會自動控制車輛。

執行方式
--------
1. 解壓縮整個 ZIP，不要拆開 .mat 與 .m 檔案。
2. MATLAB Current Folder 切換到本資料夾。
3. 先執行：
       checkWuProjectV2Map
4. 通過後執行：
       RUN_WU_PROJECT_V2
5. 可在 RUN_WU_PROJECT_V2.m 修改車流量、相位秒數、模擬時間、
   機車比例、播放速度與 Gipps / IDM 模型。

也可在命令列直接執行：
    result = runWuProjectV2Simulation([20 8 20 8],120, ...
        [300 300 300 300],[20 60 20],5,0.35,false,'Gipps');

驗證範圍與限制
--------------
已對原始 Wu MAT 資料做靜態檢查：
- 共 30 條路徑，路徑座標皆為有限值。
- 每條路徑的累積距離遞增，length 與最後一個 s 值一致。
- 1~14 為一般路徑、15~22 為機車第一段、23~30 為機車第二段。
- 8 組第一段終點與第二段起點完全銜接，且待轉格與 slot 編號一致。

重要：目前執行環境沒有 MATLAB / Automated Driving Toolbox，因此無法在此
直接啟動 MATLAB 動畫做動態驗證。這份整合版已完成程式結構與 Wu 路徑
資料的靜態核對，但不能把靜態核對宣稱成「MATLAB 已實際跑通」。
請先執行 checkWuProjectV2Map，再執行主程式；若 MATLAB 出現錯誤，
請保留完整錯誤訊息與行號，才能針對實際版本修正。
