function projectRoot = getWuProjectRoot()
% GETWUPROJECTROOT Return the absolute root folder of this project.
% Keep this helper in the project root. All code should build file paths
% from this function instead of assuming .m and .mat files share a folder.
projectRoot = fileparts(mfilename('fullpath'));
end
