% SHOW_MOTORCYCLE_PATHS - Debug route overlays only; no vehicle motion.
root=fileparts(mfilename('fullpath'));
D=load(fullfile(root,'intersectionMap_v3_twoStage_v4.mat'),'map');
map=D.map; %#ok<NASGU>
roadUI=showRoadV4(map,true); %#ok<NASGU>
disp('Cyan dotted: stage 1 to waiting box. Amber solid: stage 2.');
