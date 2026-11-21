function h=drawRoadVehicleV4(ui,map,pathId,distance,kind,h)
% DRAWROADVEHICLEV4 Draw/update ONE vehicle at a caller-selected distance.
% kind='motorcycle' or 'car'. Handle h can be reused for animation updates.
% Example:
%   h=drawRoadVehicleV4(ui,map,15,20,'motorcycle');
%   h=drawRoadVehicleV4(ui,map,15,25,'motorcycle',h);
if nargin<5 || isempty(kind), kind='motorcycle'; end
if nargin<6, h=[]; end
assert(ischar(kind) || isstring(kind),'kind must be car or motorcycle.');
kind=lower(char(kind));
assert(strcmp(kind,'car')||strcmp(kind,'motorcycle'), ...
    'kind must be car or motorcycle.');
[x,y,a]=roadPoseV4(map,pathId,distance);
R=[cos(a) -sin(a); sin(a) cos(a)];
if strcmp(kind,'car')
    L=4.3; W=1.9;
    coords=[-L/2 -W/2; L/2 -W/2; L/2 W/2; -L/2 W/2];
    color=[.16 .51 .94];
else
    L=2.8; W=1.6;
    coords=[-L/2 -W/2;-L/2 W/2;L*.12 W*.56;L/2 0;L*.12 -W*.56];
    color=[.06 .96 .94];
end
xy=coords*R'+[x y];
if isempty(h) || ~isstruct(h) || ~isfield(h,'body') || ~isgraphics(h.body)
    h=struct();
    h.body=patch(ui.ax,xy(:,1),xy(:,2),color, ...
        'EdgeColor','w','LineWidth',1.1,'HitTest','off');
    h.lamp=[];
else
    set(h.body,'XData',xy(:,1),'YData',xy(:,2));
end
if strcmp(kind,'motorcycle')
    forward=[cos(a),sin(a)];
    p=[x y]+.3*L*forward;
    if ~isfield(h,'lamp')||isempty(h.lamp)||~isgraphics(h.lamp)
        h.lamp=plot(ui.ax,[x p(1)],[y p(2)],'-', ...
            'Color','w','LineWidth',2,'HitTest','off');
    else
        set(h.lamp,'XData',[x p(1)],'YData',[y p(2)]);
    end
elseif isfield(h,'lamp') && ~isempty(h.lamp) && isgraphics(h.lamp)
    delete(h.lamp);h.lamp=[];
end
end
