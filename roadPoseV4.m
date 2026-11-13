function [x,y,heading] = roadPoseV4(map,pathId,distance)
% ROADPOSEV4 Find the XY position and heading along an existing path.
% pathId 1..numel(map.paths), distance in meters along path.s.
assert(isscalar(pathId) && pathId==round(pathId) && ...
    pathId>=1 && pathId<=numel(map.paths),'Invalid pathId.');
p=map.paths(pathId);
assert(isscalar(distance) && isfinite(distance), ...
    'distance must be a finite scalar.');
distance=max(0,min(p.length,distance));
x=interp1(p.s,p.xy(:,1),distance,'linear');
y=interp1(p.s,p.xy(:,2),distance,'linear');
a=max(0,distance-.35);
b=min(p.length,distance+.35);
x0=interp1(p.s,p.xy(:,1),a,'linear');
y0=interp1(p.s,p.xy(:,2),a,'linear');
x1=interp1(p.s,p.xy(:,1),b,'linear');
y1=interp1(p.s,p.xy(:,2),b,'linear');
heading=atan2(y1-y0,x1-x0);
end
