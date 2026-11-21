function setRoadLightsV4(ui,phase,remaining)
% SETROADLIGHTSV4 Paint signal heads only; it does not control vehicle motion.
% 0=ALL RED, 1=EW straight, 2=EW protected LEFT,
% 3=NS straight, 4=NS protected LEFT,
% 5=EW YELLOW clearance, 6=NS YELLOW clearance.
if nargin<3 || isempty(remaining), remaining=NaN; end
validateattributes(phase,{'numeric'},{'scalar','integer','>=',0,'<=',6});
if ~isgraphics(ui.fig), return; end

red=[.96 .12 .08];
yellow=[1 .72 .02];
green=[.07 .95 .22];
off=[.18 .18 .18];
labels={'ALL RED','EW straight / right','EW protected LEFT', ...
    'NS straight / right','NS protected LEFT','EW yellow clearance', ...
    'NS yellow clearance'};

for a=1:4
    ew=(a<=2);
    redOn=false; yellowOn=false; throughOn=false; arrowOn=false;

    if phase==0
        redOn=true;
    elseif phase==5
        if ew, yellowOn=true; else, redOn=true; end
    elseif phase==6
        if ~ew, yellowOn=true; else, redOn=true; end
    elseif ew
        redOn=~(phase==1);
        throughOn=(phase==1);
        arrowOn=(phase==2);
    else
        redOn=~(phase==3);
        throughOn=(phase==3);
        arrowOn=(phase==4);
    end

    colors=repmat(off,3,1);
    if redOn, colors(1,:)=red; end
    if yellowOn, colors(2,:)=yellow; end
    if throughOn, colors(3,:)=green; end
    for b=1:3
        if isgraphics(ui.lamps(a,b))
            set(ui.lamps(a,b),'FaceColor',colors(b,:));
        end
    end
    if arrowOn, ac=[.07 .97 .22]; else, ac=[.20 .29 .21]; end
    if isgraphics(ui.leftArrow(a)), set(ui.leftArrow(a),'Color',ac); end

    dirNames={'W','E','N','S'};
    if isnan(remaining)
        txt=sprintf('%s --',dirNames{a});
    else
        txt=sprintf('%s %02d',dirNames{a},max(0,ceil(remaining)));
    end
    if isgraphics(ui.countdown(a)), set(ui.countdown(a),'String',txt); end
end

if isgraphics(ui.phaseText)
    set(ui.phaseText,'String',sprintf('Road | %s | phase %d',labels{phase+1},phase));
end
drawnow limitrate;
end
