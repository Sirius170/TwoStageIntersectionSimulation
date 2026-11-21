給組員的道路模組使用說明
========================

用途
----
此專案包含 Wu V4 路口道路幾何、待轉格、號誌外觀及道路路徑資料。
可單獨使用道路模組，也可執行整合版汽車＋機車模擬。

快速操作
--------
1. 解壓縮整個 Wu_Project_v2_整理版 資料夾。
2. MATLAB 開啟 01_執行入口。
3. 執行 CHECK_PROJECT.m，確認路徑與道路資料檢查通過。
4. 執行 RUN_ROAD_ONLY.m，即可只顯示道路。
5. 執行 SHOW_MOTORCYCLE_PATHS.m，可顯示機車兩段式路線。
6. 執行 RUN_WU_PROJECT_V2.m，可執行整合模擬。

重要：請勿將 .mat 與 .m 檔案拆散後單獨搬移。若要調整資料夾名稱，
請同步檢查 getWuProjectRoot.m 與所有 fullfile(...) 的路徑。

給自行撰寫演算法的組員
----------------------
入口腳本會將專案根目錄及其子資料夾加入 MATLAB path。
道路資料可用以下方式載入：

    projectRoot = getWuProjectRoot();
    mapFile = fullfile(projectRoot,'04_道路資料', ...
        'intersectionMap_v3_twoStage_v4.mat');
    D = load(mapFile,'map');
    map = D.map;
    roadUI = showRoadV4(map);

號誌外觀由呼叫端指定：
    setRoadLightsV4(roadUI,1,15); % 東西直行綠燈
    setRoadLightsV4(roadUI,2,15); % 東西保護左轉箭頭
    setRoadLightsV4(roadUI,3,15); % 南北直行綠燈
    setRoadLightsV4(roadUI,4,15); % 南北保護左轉箭頭
    setRoadLightsV4(roadUI,0);    % 全紅

車輛位置由 pathId 與路徑距離決定：
    approach = 1; slot = 1;
    path1 = map.twoStage.firstPathIdsBySlot(approach,slot);
    path2 = map.twoStage.secondPathIds(approach,slot);
    h = drawRoadVehicleV4(roadUI,map,path1,25,'motorcycle');
    [x,y,theta] = roadPoseV4(map,path1,25);
    h = drawRoadVehicleV4(roadUI,map,path1,30,'motorcycle',h);

資料夾分工
----------
01_執行入口：使用者直接執行的腳本。
02_模擬核心：車流、車輛移動、號誌週期與等待時間計算。
03_道路與視覺化：道路繪圖、車輛繪圖、路徑座標與燈號顯示。
04_道路資料：MAT 道路結構與 CSV 路線索引。
05_檢查工具：檢查道路路徑及兩段式銜接。
06_文件：使用方式、整合設計與交接說明。
07_參考圖片：畫面參考圖。
getWuProjectRoot.m：位於專案最外層，負責提供穩定的專案根目錄。

路徑欄位提示
------------
map.paths：30 條路徑。stage=0 為一般車輛路徑，stage=1 為機車第一段，
stage=2 為機車第二段。
map.waitingBoxes：四個待轉格矩形。
map.waitingBoxSlots：各待轉格內兩個停車點。
map.twoStage.firstPathIdsBySlot：各來車方向、各 slot 的第一段路徑 ID。
map.twoStage.secondPathIds：各來車方向、各 slot 的第二段路徑 ID。
map.stopLines：停止線位置。
map.routes：一般路線資料。

注意事項
--------
- setRoadLightsV4 只改變燈號外觀，不會自動攔車或處理碰撞。
- 自行接入演算法時，仍需自行負責號誌路權、車輛衝突與待轉格容量。
- 這份 ZIP 沒有包含原始 Project_v2_原始參考資料夾；如需比對，需另行提供。
- 尚未由本次整理流程在 MATLAB 實際執行動畫，請先執行 CHECK_PROJECT.m。
