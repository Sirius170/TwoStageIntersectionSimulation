% CHECK_PROJECT - Add project folders to MATLAB path and validate map data.
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
report = checkWuProjectV2Map(); %#ok<NASGU>
disp('Project folder paths initialized and map check passed.');
