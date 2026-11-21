% RUN_ROAD_ONLY.m - One-click street map. No vehicles or GA are launched.
% Put all files from the ZIP into the same folder, then click Run.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
mapFile=fullfile(projectRoot,'04_道路資料','intersectionMap_v3_twoStage_v4.mat');
assert(isfile(mapFile),sprintf('找不到道路資料檔：%s',mapFile));
D=load(mapFile,'map');
map=D.map; %#ok<NASGU>  % available for your own code in Workspace
roadUI=showRoadV4(map); %#ok<NASGU>
disp('Road loaded. Workspace: map, roadUI. No simulation is running.');
disp('Example: setRoadLightsV4(roadUI,2,10)  % EW left-turn arrow');
