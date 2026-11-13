給同學的 MATLAB V4「純道路」測試版
================================

用途
  讓同學使用你的 V4 路口、待轉格、斑馬線、路徑和交通燈外觀，
  接入他自己寫的兩段式左轉程式、車流及交通燈控制。
  本 ZIP 沒有 GA、原本的車輛自動行駛程式，也沒有自動切換號誌。

一、直接看到道路（最簡單）
  1. 解壓縮全部檔案到同一資料夾（不要只開啟 .mat）。
  2. MATLAB 開啟 RUN_ROAD_ONLY.m，按 Run。
  3. 出現 V4 道路畫面，Workspace 會有 map 與 roadUI。
  4. SHOW_MOTORCYCLE_PATHS.m 可顯示機車兩段式兩段路線。

二、接入他自己的 .m 程式
  root=fileparts(mfilename('fullpath'));
  D=load(fullfile(root,'intersectionMap_v3_twoStage_v4.mat'),'map');
  map=D.map;
  roadUI=showRoadV4(map);

  % 他自己的紅綠燈邏輯決定何時調用：
  setRoadLightsV4(roadUI,1,15); % 東西直行綠燈
  setRoadLightsV4(roadUI,2,15); % 東西左轉專用綠箭頭
  setRoadLightsV4(roadUI,3,15); % 南北直行綠燈
  setRoadLightsV4(roadUI,4,15); % 南北左轉專用綠箭頭
  setRoadLightsV4(roadUI,0);    % 全紅，供清空路口

  % 依自訂演算法指定路徑和行駛距離（不會自動前進）：
  a=1; slot=1; % a: 1西 2東 3北 4南，slot: 1 或 2
  path1=map.twoStage.firstPathIdsBySlot(a,slot);
  path2=map.twoStage.secondPathIds(a,slot);
  h=drawRoadVehicleV4(roadUI,map,path1,25,'motorcycle');
  [x,y,theta]=roadPoseV4(map,path1,25);
  % 當演算法讓車繼續前進時，呼叫：
  h=drawRoadVehicleV4(roadUI,map,path1,30,'motorcycle',h);
  % 第1段到待轉格後：等待對應方向直行綠燈才能沿 path2 前進。
  % h=drawRoadVehicleV4(roadUI,map,path2,5,'motorcycle',h);

三、map 結構欄位
  map.paths       路徑結構陣列（共30條，索引1~30）。
                  每條有 a方向、m轉向、stage階段、xy路徑點、s累積距離、length、stopS、exitS 等。
                  stage=0：一般汽車路徑 (1~14)
                  stage=1：機車第1段 (15~22)
                  stage=2：機車第2段 (23~30)
  map.waitingBoxes      四個待轉格矩形 [x y 寬 高]，順序 NW NE SW SE。
  map.waitingBoxSlots   四個格位各自的兩個停車點 [x y]。
  map.twoStage.boxForApproach   [4 1 3 2]：西->SE 東->NW 北->SW 南->NE。
  map.twoStage.firstPathIdsBySlot(a,slot)  第一段路徑 ID。
  map.twoStage.secondPathIds(a,slot)       第二段路徑 ID。
  map.stopLines         各方向停止線位置。
  map.routes            一般左/直/右原始路徑座標。

四、交通燈控制提醒
  相位順序建議：1 東西直行 -> 2 東西保護左轉 -> 0 全紅清空 ->
                3 南北直行 -> 4 南北保護左轉 -> 0 全紅清空 -> 1。
  「setRoadLightsV4」只改燈號畫面，不會攔車，實際路權/碰撞/放行及
  待轉格容量要由同學的演算法自己實作。
  機車兩段式左轉的兩段都依所跨越方向的「直行綠燈」放行，
  而不是依汽車左轉箭頭放行。保護左轉箭頭則保留給有左轉專用道的汽車。

五、檔案清單
  intersectionMap_v3_twoStage_v4.mat：座標資料（原檔改成一致名稱）。
  RUN_ROAD_ONLY.m                  ：一鍵顯示純道路。
  SHOW_MOTORCYCLE_PATHS.m         ：顯示兩段式行走路線（僅靜態線條）。
  showRoadV4.m                    ：畫路口、待轉格、交通號誌。
  setRoadLightsV4.m               ：由外部程式指定燈號（不含計時控制）。
  roadPoseV4.m                    ：查詢任意路徑座標與方向。
  drawRoadVehicleV4.m             ：畫汽/機車，可重複呼叫更新位置。

六、注意
  必須把所有 .m 和 .mat 放在 MATLAB Current Folder 或 addpath 到路徑。
  .mat 匯入 Workspace 並不等於可以自動把車輛模擬接上。
  這個包沒有實際用 MATLAB 跑動畫驗證，請同學先測試繪圖和座標接口。
