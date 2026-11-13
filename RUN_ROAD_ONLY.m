% RUN_ROAD_ONLY.m - One-click street map. No vehicles or GA are launched.
% Put all files from the ZIP into the same folder, then click Run.
root=fileparts(mfilename('fullpath'));
D=load(fullfile(root,'intersectionMap_v3_twoStage_v4.mat'),'map');
map=D.map; %#ok<NASGU>  % available for your own code in Workspace
roadUI=showRoadV4(map); %#ok<NASGU>
disp('Road loaded. Workspace: map, roadUI. No simulation is running.');
disp('Example: setRoadLightsV4(roadUI,2,10)  % EW left-turn arrow');
