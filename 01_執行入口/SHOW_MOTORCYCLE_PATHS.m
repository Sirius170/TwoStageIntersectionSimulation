% SHOW_MOTORCYCLE_PATHS - Debug route overlays only; no vehicle motion.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
mapFile=fullfile(projectRoot,'04_道路資料','intersectionMap_v3_twoStage_v4.mat');
assert(isfile(mapFile),sprintf('找不到道路資料檔：%s',mapFile));
D=load(mapFile,'map');
map=D.map; %#ok<NASGU>
roadUI=showRoadV4(map,true); %#ok<NASGU>
disp('Cyan dotted: stage 1 to waiting box. Amber solid: stage 2.');
