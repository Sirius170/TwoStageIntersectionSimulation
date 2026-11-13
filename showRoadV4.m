% SHOWROADV4 - Road drawing only (no car spawning, no GA, no controller).
% Usage:
%   D = load('intersectionMap_v3_twoStage_v4.mat');
%   ui = showRoadV4(D.map);             % show road, all signals red
%   ui = showRoadV4(D.map,true);        % also show first/second-leg paths
%   setRoadLightsV4(ui,2,10);          % sample: EW protected LEFT arrow
%   setRoadLightsV4(ui,3,10);          % sample: NS straight green
%
% The visual signal state is controlled entirely by the caller. It is NOT
% safety logic: the student's simulation must handle clearance/collisions.

function ui=showRoadV4(map,showPaths)

if nargin<2, showPaths=false; end

fig=figure(...
    'Color','w',...
    'Name','V4 Road only - external algorithm interface',...
    'Position',[70 50 1280 850]);

ax=axes('Parent',fig);
hold(ax,'on');
axis(ax,'equal');

xlim(ax,map.xlim);
ylim(ax,map.ylim);

set(ax,'Color',[.72 .72 .68],'Layer','top');

c=map.colors;
A=c.asphalt;
W=c.white;
Y=c.yellow;

%% 周邊建築與行人區
rect([-100 27 67 61],[.69 .66 .62]);
rect([33 27 67 61],[.67 .66 .61]);
rect([-100 -88 67 57],[.62 .64 .59]);
rect([33 -88 67 57],[.68 .64 .60]);

rect([-96 42 53 45],[.52 .46 .42]);
rect([50 45 47 40],[.51 .54 .53]);
rect([-97 -85 59 38],[.56 .57 .55]);
rect([49 -86 48 46],[.55 .48 .44]);

for k=1:7
    tree(-92+8*k,33+3*mod(k,2),3.1);
    tree(40+8*k,35+2*mod(k,2),3);
    tree(-91+8*k,-36-3*mod(k,2),3.3);
end

%% 主道路
rect([-100 -27 200 54],A);
rect([-18 -88 36 176],A);

%% 中央槽化線
rect([-100 -2.4 66 4.8],[.31 .32 .32]);
rect([34 -2.4 66 4.8],[.31 .32 .32]);

for x=-98:5:-37
    line([x x+3],[-2 2],...
        'Color',W,'LineWidth',.9);
end

for x=36:5:97
    line([x x+3],[-2 2],...
        'Color',W,'LineWidth',.9);
end

for y=[-3.3 3.3]

    line([-100 -34],[y y],...
        'Color',Y,'LineWidth',1.8);

    line([34 100],[y y],...
        'Color',Y,'LineWidth',1.8);
end

%% 南北中央黃線
line([0 0],[35 88],...
    'Color',Y,'LineWidth',1.8);

line([0 0],[-88 -35],...
    'Color',Y,'LineWidth',1.8);

%% 東西車道線
for y=[...
    -22.75 -18.25 -13.75 -9.25...
     7.75 12.25 16.75 21.25]

    line([-100 -34],[y y],...
        'LineStyle','--',...
        'Color',W,'LineWidth',1);

    line([34 100],[y y],...
        'LineStyle','--',...
        'Color',W,'LineWidth',1);
end

%% 南北車道線
for x=[-15 -11 -7 -3 3 7 11 15]

    line([x x],[-88 -34],...
        'LineStyle','--',...
        'Color',W,'LineWidth',1);

    line([x x],[34 88],...
        'LineStyle','--',...
        'Color',W,'LineWidth',1);
end

%% 道路邊界
for y=[-27 27]

    line([-100 -34],[y y],...
        'Color',W,'LineWidth',1.3);

    line([34 100],[y y],...
        'Color',W,'LineWidth',1.3);
end

for x=[-18 18]

    line([x x],[-88 -34],...
        'Color',W,'LineWidth',1.3);

    line([x x],[34 88],...
        'Color',W,'LineWidth',1.3);
end

%% 路口中心
rect([-46 -46 92 92],A);

corner([-47 40;-47 47;-40 47;-39 43;-42 40],c.sidewalk);
corner([47 40;47 47;40 47;39 43;42 40],c.sidewalk);
corner([-47 -40;-47 -47;-40 -47;-39 -43;-42 -40],c.sidewalk);
corner([47 -40;47 -47;40 -47;39 -43;42 -40],c.sidewalk);

%% 四個斑馬線：移至待轉格外側（40.5 到 46 m），保留間距
for x=-16:3.6:16
    rect([x-1.1 40.5 2.2 5.5],W);
    rect([x-1.1 -46 2.2 5.5],W);
end
for y=-25:3.6:25
    rect([-46 y-1.05 5.5 2.1],W);
    rect([40.5 y-1.05 5.5 2.1],W);
end

%% 停止線也移至斑馬線外側；與程式中的停車座標一致
line([-18 18],[49 49],'Color',W,'LineWidth',2.5);
line([-18 18],[-49 -49],'Color',W,'LineWidth',2.5);
line([-49 -49],[-27 27],'Color',W,'LineWidth',2.5);
line([49 49],[-27 27],'Color',W,'LineWidth',2.5);

%% 機車待轉格
for k=1:size(map.waitingBoxes,1)

    rectangle(...
        'Position',map.waitingBoxes(k,:),...
        'EdgeColor',W,...
        'LineWidth',1.6,...
        'FaceColor','none');
end

%% =========================================================
%% =========================================================

for x=[-78 -51]
    drawArrow(x,-7,[1 0],'left',W);
    drawArrow(x,-11.5,[1 0],'straight',W);
    drawArrow(x,-16,[1 0],'straight',W);
    drawArrow(x,-20.5,[1 0],'right',W);
end

for x=[78 51]
    drawArrow(x,5.5,[-1 0],'left',W);
    drawArrow(x,10,[-1 0],'straight',W);
    drawArrow(x,14.5,[-1 0],'straight',W);
    drawArrow(x,19,[-1 0],'right',W);
end

for y=[72 49]
    drawArrow(-5,y,[0 -1],'left',W);
    drawArrow(-9,y,[0 -1],'straight',W);
    drawArrow(-13,y,[0 -1],'right',W);
end

for y=[-72 -49]
    drawArrow(5,y,[0 1],'left',W);
    drawArrow(9,y,[0 1],'straight',W);
    drawArrow(13,y,[0 1],'right',W);
end

%% 座標顯示
xticks(ax,-100:10:100);
yticks(ax,-80:10:80);

grid(ax,'on');
ax.GridAlpha=.12;
ax.GridColor=[.25 .25 .25];

xlabel(ax,'X (m)');
ylabel(ax,'Y (m)');

title(ax,'V4 Road Only | independent two-stage turn test');

% Identify the two reserved scooter parking slots. They are *not* vehicles.
for b=1:numel(map.waitingBoxSlots)
    pts=map.waitingBoxSlots{b};
    plot(ax,pts(:,1),pts(:,2),'o','Color',[.14 .98 .98], ...
        'MarkerSize',5,'LineWidth',1.2,'HitTest','off');
    pos=map.waitingBoxes(b,:);
    text(ax,pos(1)+pos(3)/2,pos(2)+pos(4)+1.8, ...
        map.waitingBoxNames{b},'Color',[.1 .1 .1], ...
        'FontSize',8,'FontWeight','bold', ...
        'HorizontalAlignment','center','HitTest','off');
end

% Optional debugging overlay: cyan = first leg, amber = second leg.
if showPaths
    for k=1:numel(map.paths)
        p=map.paths(k);
        if p.stage==1
            plot(ax,p.xy(:,1),p.xy(:,2),':', ...
                'Color',[.1 .9 .95],'LineWidth',1.25,'HitTest','off');
        elseif p.stage==2
            plot(ax,p.xy(:,1),p.xy(:,2),'-', ...
                'Color',[1 .74 .18],'LineWidth',1.25,'HitTest','off');
        end
    end
end

% Four *static* signal heads. setRoadLightsV4 updates their color when the
% student's own controller decides a phase. No automatic timer/GA here.
ui=struct();
ui.fig=fig;
ui.ax=ax;
ui.lamps=gobjects(4,3); % red, yellow, green
ui.leftArrow=gobjects(1,4);
ui.countdown=gobjects(1,4);
ui.phaseText=text(ax,-97,81,'Road ready: all RED', ...
    'BackgroundColor','w','Color','k','FontWeight','bold', ...
    'FontSize',9,'Margin',4,'HitTest','off');
positions=[-87 50;59 50;-30 64;24 -71];
directions={'W','E','N','S'};
arrows={'\uparrow','\downarrow','\rightarrow','\leftarrow'};
for a=1:4
    pos=positions(a,:);
    ui.countdown(a)=text(ax,pos(1)+4.4,pos(2)+11.7, ...
        sprintf('%s  --',directions{a}), ...
        'Color','w','BackgroundColor',[.12 .12 .12], ...
        'FontWeight','bold','FontSize',9, ...
        'HorizontalAlignment','center','HitTest','off');
    rectangle(ax,'Position',[pos(1)-.8 pos(2)-.8 11.3 10.8], ...
        'FaceColor',[.09 .10 .11],'EdgeColor',[.82 .82 .82], ...
        'LineWidth',1.5,'HitTest','off');
    for b=1:3
        ui.lamps(a,b)=rectangle(ax,'Position', ...
            [pos(1)+(b-1)*3.5,pos(2),3.1,3.1], ...
            'Curvature',[1 1],'FaceColor',[.18 .18 .18], ...
            'EdgeColor',[.4 .4 .4],'HitTest','off');
    end
    rectangle(ax,'Position',[pos(1)+2.7,pos(2)+4.2,4.2,5], ...
        'FaceColor',[.12 .17 .12],'EdgeColor',[.4 .48 .4], ...
        'LineWidth',.9,'HitTest','off');
    ui.leftArrow(a)=text(ax,pos(1)+4.8,pos(2)+6.6,arrows{a}, ...
        'Interpreter','tex','Color',[.20 .29 .21], ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FontSize',17,'FontWeight','bold','HitTest','off');
end
setRoadLightsV4(ui,0);

end

%% 矩形
function rect(pos,c)
rectangle(...
    'Position',pos,...
    'FaceColor',c,...
    'EdgeColor','none');
end

%% 路口角落
function corner(p,c)
patch(p(:,1),p(:,2),c,'EdgeColor','none');
end

%% 樹木
function tree(x,y,r)

rectangle(...
    'Position',[x-r y-r 2*r 2*r],...
    'Curvature',[1 1],...
    'FaceColor',[.23 .38 .24],...
    'EdgeColor',[.17 .30 .17],...
    'LineWidth',.6);

end

%% 真正的左轉、直行、右轉箭頭
function drawArrow(x,y,d,type,c)

p=[x y];
left=[-d(2) d(1)];

if strcmp(type,'straight')

    q=[...
        p-2.9*d;
        p+2.3*d];

elseif strcmp(type,'left')

    q=[...
        p-2.9*d;
        p+0.2*d;
        p+1.25*d+0.75*left;
        p+1.35*d+1.7*left];

else

    q=[...
        p-2.9*d;
        p+0.2*d;
        p+1.25*d-0.75*left;
        p+1.35*d-1.7*left];
end

plot(q(:,1),q(:,2),...
    'Color',c,...
    'LineWidth',1.5);

v=q(end,:)-q(end-1,:);
v=v/max(norm(v),eps);

n=[-v(2) v(1)];
head=q(end,:);

tri=[...
    head;
    head-1.6*v+0.9*n;
    head-1.6*v-0.9*n];

patch(...
    tri(:,1),tri(:,2),c,...
    'EdgeColor','none');

end
