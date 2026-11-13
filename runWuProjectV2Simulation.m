function result = runWuProjectV2Simulation(phaseSeconds, simulationSeconds, inflow, turnWeights, playbackSpeed, motorcycleShare, showPaths, carFollowingModel)
% RUNWUPROJECTV2SIMULATION
% Integrates Project_v2 vehicle behavior with Wu V4 road geometry.
%
% phaseSeconds = [EW_through EW_protected_left NS_through NS_protected_left]
% Signal sequence includes yellow and all-red clearance:
% 1 -> 5(EW yellow) -> 0 -> 2 -> 5 -> 0 ->
% 3 -> 6(NS yellow) -> 0 -> 4 -> 6 -> 0 -> repeat.
%
% Wu map.paths is the authoritative road geometry. Project_v2's longitudinal
% Gipps/IDM car-following models are ported to this map-based vehicle engine.
% The old Project_v2 Node/RoadSegment mapping is intentionally not reused:
% its fixed 3.65 m lane offset and its old scenario coordinates do not match
% Wu V4's independent coordinate system and lane layout.

if nargin < 1 || isempty(phaseSeconds), phaseSeconds = [20 8 20 8]; end
if nargin < 2 || isempty(simulationSeconds), simulationSeconds = 120; end
if nargin < 3 || isempty(inflow), inflow = [300 300 300 300]; end
if nargin < 4 || isempty(turnWeights), turnWeights = [20 60 20]; end
if nargin < 5 || isempty(playbackSpeed), playbackSpeed = 0; end
if nargin < 6 || isempty(motorcycleShare), motorcycleShare = 0.35; end
if nargin < 7 || isempty(showPaths), showPaths = false; end
if nargin < 8 || isempty(carFollowingModel), carFollowingModel = 'Gipps'; end

validateattributes(phaseSeconds,{'numeric'},{'vector','numel',4,'positive','finite'});
validateattributes(simulationSeconds,{'numeric'},{'scalar','positive','finite'});
validateattributes(inflow,{'numeric'},{'vector','numel',4,'nonnegative','finite'});
validateattributes(turnWeights,{'numeric'},{'vector','numel',3,'nonnegative','finite'});
assert(sum(turnWeights)>0,'turnWeights must have a positive sum.');
assert(motorcycleShare>=0 && motorcycleShare<=1,'motorcycleShare must be in [0,1].');
assert(any(strcmpi(carFollowingModel,{'Gipps','IDM'})), ...
    'carFollowingModel must be Gipps or IDM.');

root = fileparts(mfilename('fullpath'));
D = load(fullfile(root,'intersectionMap_v3_twoStage_v4.mat'),'map');
map = D.map;
dt = 0.05;
yellowSeconds = 3.0;
allRedSeconds = 1.5;
rng(7,'twister');

% Validate the essential Wu map interface before creating vehicles.
assert(numel(map.paths)==30,'Wu V4 map must contain exactly 30 paths.');
assert(isequal(size(map.twoStage.firstPathIdsBySlot),[4 2]));
assert(isequal(size(map.twoStage.secondPathIds),[4 2]));
assert(all([map.paths(15:22).stage]==1));
assert(all([map.paths(23:30).stage]==2));

ui = showRoadV4(map,showPaths);

% Build a Poisson arrival schedule, using Project_v2's arrival-process idea.
arrivals = makeArrivals();
nextArrival = 1;
vehicles = emptyVehicleArray();
nextId = 1;

% Wu phase meanings: 0 all-red, 1 EW straight, 2 EW protected left,
% 3 NS straight, 4 NS protected left. 5/6 are added yellow-clearance states.
signalPhases = [1 5 0 2 5 0 3 6 0 4 6 0];
signalDurations = [phaseSeconds(1),yellowSeconds,allRedSeconds, ...
                   phaseSeconds(2),yellowSeconds,allRedSeconds, ...
                   phaseSeconds(3),yellowSeconds,allRedSeconds, ...
                   phaseSeconds(4),yellowSeconds,allRedSeconds];
signalEdges = [0 cumsum(signalDurations)];
cycleDuration = signalEdges(end);
lastPhase = -1;

completedCars = 0;
completedMotorcycles = 0;
totalWait = 0;
waitingByApproach = zeros(4,1);
twoStageWaitTotal = 0;
twoStageCompleted = 0;
phaseLog = zeros(0,2);

fig = ui.fig;
ax = ui.ax;
t = 0;
while t <= simulationSeconds && isgraphics(fig)
    phase = phaseAt(t);
    remaining = phaseRemaining(t);
    if phase ~= lastPhase
        setRoadLightsV4(ui,phase,remaining);
        phaseLog(end+1,:) = [t phase]; %#ok<AGROW>
        lastPhase = phase;
    end

    % Spawn arrivals. A blocked entry is deferred, never silently discarded.
    while nextArrival <= numel(arrivals) && arrivals(nextArrival).time <= t + 1e-9
        a = arrivals(nextArrival);
        if canSpawn(a.pathId)
            v = makeVehicle(a,nextId,t);
            vehicles(end+1) = v; %#ok<AGROW>
            nextId = nextId + 1;
            nextArrival = nextArrival + 1;
        else
            arrivals(nextArrival).time = t + 1.0;
            % Keep the pending queue ordered so a blocked approach does not
            % unnecessarily delay unrelated arrivals.
            if nextArrival < numel(arrivals)
                [~,tailOrder] = sort([arrivals(nextArrival:end).time]);
                arrivals(nextArrival:end) = arrivals(nextArrival-1+tailOrder);
            end
            break;
        end
    end

    for k = 1:numel(vehicles)
        if ~vehicles(k).active, continue; end
        p = map.paths(vehicles(k).pathId);

        % Stage 2: wait in the reserved Wu waiting-box slot for the
        % perpendicular straight green. The car-left arrow is NOT used.
        if vehicles(k).stage == 2
            requiredPhase = secondLegPhase(vehicles(k).approach);
            if phase == requiredPhase
                vehicles(k).twoStageWait = max(0,t-vehicles(k).waitStart);
                twoStageWaitTotal = twoStageWaitTotal + vehicles(k).twoStageWait;
                vehicles(k).pathId = vehicles(k).nextPathId;
                vehicles(k).distance = 0;
                vehicles(k).stage = 3;
                vehicles(k).speed = 0;
                vehicles(k).hasEntered = false;
                p = map.paths(vehicles(k).pathId);
            else
                vehicles(k).speed = 0;
                vehicles(k).acceleration = 0;
                totalWait = totalWait + dt;
                waitingByApproach(vehicles(k).approach) = ...
                    waitingByApproach(vehicles(k).approach) + dt;
                continue;
            end
        end

        % Before entering the junction, obey the appropriate signal. Once
        % committed past the stop line, clear the junction even at phase edge.
        if vehicles(k).stage == 3
            allowedPhase = secondLegPhase(vehicles(k).approach);
            if ~vehicles(k).hasEntered
                if phase == allowedPhase
                    vehicles(k).hasEntered = true;
                else
                    vehicles(k).speed = 0;
                    vehicles(k).acceleration = 0;
                    totalWait = totalWait + dt;
                    waitingByApproach(vehicles(k).approach) = ...
                        waitingByApproach(vehicles(k).approach) + dt;
                    continue;
                end
            end
        elseif ~vehicles(k).hasEntered
            if vehicles(k).stage == 1
                allowedPhase = firstLegPhase(vehicles(k).approach);
            else
                allowedPhase = movementPhase(vehicles(k).approach,vehicles(k).movement);
            end
            if phase == allowedPhase
                % Commit when the next integration step reaches the stop line.
                if vehicles(k).distance + vehicles(k).speed*dt >= p.stopS - 0.02
                    vehicles(k).hasEntered = true;
                end
            end
        end

        % Project_v2 longitudinal control: its Gipps or IDM car-following model.
        [leaderSpeed,leaderGap,hasLeader] = findLeader(k,vehicles);
        if strcmpi(carFollowingModel,'Gipps')
            if hasLeader
                newSpeed = gippsSpeed(vehicles(k).speed,leaderSpeed,leaderGap, ...
                    vehicles(k).desiredSpeed);
            else
                newSpeed = freeSpeed(vehicles(k).speed,vehicles(k).desiredSpeed);
            end
        else
            if hasLeader
                newSpeed = idmSpeed(vehicles(k).speed,leaderSpeed,leaderGap, ...
                    vehicles(k).desiredSpeed,dt);
            else
                newSpeed = idmFreeSpeed(vehicles(k).speed, ...
                    vehicles(k).desiredSpeed,dt);
            end
        end

        % Red/yellow stop-line constraint applies only before junction entry.
        if ~vehicles(k).hasEntered
            distanceToStop = max(0,p.stopS - vehicles(k).distance - 0.8);
            if phase ~= allowedPhase
                safeStopSpeed = sqrt(2*4.5*distanceToStop);
                newSpeed = min(newSpeed,safeStopSpeed);
                if distanceToStop <= 0.03, newSpeed = 0; end
            end
        end

        % Conservative safe-following bound.
        if hasLeader
            safeFollowingSpeed = sqrt(max(0,leaderSpeed^2 + ...
                2*4.5*max(0,leaderGap-2.5)));
            newSpeed = min(newSpeed,safeFollowingSpeed);
        end

        newSpeed = min(max(newSpeed,0),vehicles(k).maxSpeed);
        vehicles(k).acceleration = (newSpeed-vehicles(k).speed)/dt;
        vehicles(k).acceleration = min(max(vehicles(k).acceleration,-4.5),3.0);
        newSpeed = max(0,vehicles(k).speed + vehicles(k).acceleration*dt);
        vehicles(k).distance = min(p.length,vehicles(k).distance + ...
            0.5*(vehicles(k).speed+newSpeed)*dt);
        vehicles(k).speed = newSpeed;

        % First leg ends at the reserved waiting-box slot; then the scooter
        % stops and waits instead of incorrectly switching directly to exit.
        if vehicles(k).stage == 1 && vehicles(k).distance >= p.length-0.02
            vehicles(k).distance = p.length;
            vehicles(k).stage = 2;
            vehicles(k).speed = 0;
            vehicles(k).acceleration = 0;
            vehicles(k).waitStart = t;
            vehicles(k).hasEntered = false;
        elseif vehicles(k).distance >= p.length-0.02
            vehicles(k).distance = p.length;
            vehicles(k).active = false;
            if strcmp(vehicles(k).kind,'car')
                completedCars = completedCars + 1;
            else
                completedMotorcycles = completedMotorcycles + 1;
                if vehicles(k).stage == 3
                    twoStageCompleted = twoStageCompleted + 1;
                end
            end
        end

        if vehicles(k).active && vehicles(k).speed < 0.1
            totalWait = totalWait + dt;
            waitingByApproach(vehicles(k).approach) = ...
                waitingByApproach(vehicles(k).approach) + dt;
        end
    end

    % Use Wu's drawing functions for both vehicle types and their orientation.
    for k = 1:numel(vehicles)
        if vehicles(k).active
            vehicles(k).drawHandle = drawRoadVehicleV4(ui,map, ...
                vehicles(k).pathId,vehicles(k).distance, ...
                vehicles(k).kind,vehicles(k).drawHandle);
        elseif ~isempty(vehicles(k).drawHandle)
            deleteVehicleGraphic(vehicles(k).drawHandle);
            vehicles(k).drawHandle = [];
        end
    end
    title(ax,sprintf('Project_v2 vehicle logic on Wu V4 road | t = %.1f / %.1f s', ...
        t,simulationSeconds));
    drawnow limitrate;
    if playbackSpeed > 0, pause(dt/playbackSpeed); end
    t = t + dt;
end

result = struct();
result.completedCars = completedCars;
result.completedMotorcycles = completedMotorcycles;
result.totalWaitSeconds = totalWait;
result.waitingByApproach = waitingByApproach;
result.twoStageWaitSeconds = twoStageWaitTotal;
result.twoStageCompleted = twoStageCompleted;
result.phaseLog = phaseLog;
result.arrivalsScheduled = numel(arrivals);
result.arrivalsSpawned = nextId-1;
result.remainingActive = sum([vehicles.active]);
result.vehicles = vehicles;

fprintf('\n=== Wu + Project_v2 integration summary ===\n');
fprintf('Spawned: %d | Completed cars: %d | Completed motorcycles: %d\n', ...
    result.arrivalsSpawned,completedCars,completedMotorcycles);
fprintf('Two-stage left turns completed: %d | Total box wait: %.2f s\n', ...
    twoStageCompleted,twoStageWaitTotal);
fprintf('Accumulated stopped time: %.2f s\n',totalWait);
fprintf('Still active at stop time: %d\n',result.remainingActive);

    function arrivalsOut = makeArrivals()
        arrivalsOut = struct('time',{},'approach',{},'kind',{}, ...
            'movement',{},'pathId',{},'nextPathId',{},'slot',{});
        weights = turnWeights(:)'/sum(turnWeights);
        for approach = 1:4
            if inflow(approach)==0, continue; end
            arrivalTime = 0;
            while true
                % Project_v2 Poisson arrival process, with 1 s minimum headway.
                headway = max(1,-log(max(rand,eps))*3600/inflow(approach));
                arrivalTime = arrivalTime + headway;
                if arrivalTime >= simulationSeconds, break; end

                movement = find(rand <= cumsum(weights),1,'first');
                isMotorcycle = rand < motorcycleShare;
                slot = 0;
                nextPathId = 0;
                if isMotorcycle && movement==1
                    slot = randi(2);
                    pathId = map.twoStage.firstPathIdsBySlot(approach,slot);
                    nextPathId = map.twoStage.secondPathIds(approach,slot);
                else
                    candidates = find(arrayfun(@(q) q.a==approach && ...
                        q.m==movement && q.stage==0,map.paths));
                    assert(~isempty(candidates),'No Wu path for approach/movement.');
                    pathId = candidates(randi(numel(candidates)));
                end
                if isMotorcycle, kind='motorcycle'; else, kind='car'; end
                arrivalsOut(end+1) = struct('time',arrivalTime, ...
                    'approach',approach,'kind',kind,'movement',movement, ...
                    'pathId',pathId,'nextPathId',nextPathId,'slot',slot); %#ok<AGROW>
            end
        end
        if ~isempty(arrivalsOut)
            [~,order] = sort([arrivalsOut.time]);
            arrivalsOut = arrivalsOut(order);
        end
    end

    function v = makeVehicle(a,id,spawnTime)
        if strcmp(a.kind,'car')
            vehicleLength = 4.5; desired = 11.0; maxV = 15.0;
        else
            vehicleLength = 2.2; desired = 9.0; maxV = 13.0;
        end
        v = struct('id',id,'kind',a.kind,'approach',a.approach, ...
            'movement',a.movement,'pathId',a.pathId, ...
            'nextPathId',a.nextPathId,'slot',a.slot, ...
            'stage',map.paths(a.pathId).stage,'distance',0, ...
            'speed',min(5,desired),'acceleration',0, ...
            'desiredSpeed',desired,'maxSpeed',maxV, ...
            'vehicleLength',vehicleLength,'entryTime',spawnTime, ...
            'waitStart',NaN,'twoStageWait',0,'active',true, ...
            'hasEntered',false,'drawHandle',[]);
    end

    function ok = canSpawn(pathId)
        p0 = map.paths(pathId);
        xy0 = p0.xy(1,:);
        [~,~,heading0] = roadPoseV4(map,pathId,0);
        dir0 = [cos(heading0) sin(heading0)];
        ok = true;

        % Reserve the selected waiting-box slot while its scooter is on
        % stage 1 or waiting in stage 2. A slot is released at stage 3.
        if p0.stage == 1
            for jj = 1:numel(vehicles)
                if vehicles(jj).active && vehicles(jj).approach==p0.a && ...
                        vehicles(jj).slot==p0.slot && ...
                        (vehicles(jj).stage==1 || vehicles(jj).stage==2)
                    ok = false;
                    return;
                end
            end
        end

        for jj = 1:numel(vehicles)
            if ~vehicles(jj).active, continue; end
            [xj,yj,headingJ] = roadPoseV4(map,vehicles(jj).pathId,vehicles(jj).distance);
            delta = [xj yj]-xy0;
            longitudinal = dot(delta,dir0);
            lateral = abs(dir0(1)*delta(2)-dir0(2)*delta(1));
            if longitudinal > -2 && longitudinal < 13 && lateral < 2.0 && ...
                    dot(dir0,[cos(headingJ) sin(headingJ)]) > 0.75
                ok = false;
                return;
            end
        end
    end

    function [leaderSpeed,gap,found] = findLeader(selfIndex,allVehicles)
        self = allVehicles(selfIndex);
        currentPath = map.paths(self.pathId);
        [sx,sy,sh] = roadPoseV4(map,self.pathId,self.distance);
        selfDir = [cos(sh) sin(sh)];
        bestGap = inf;
        leaderSpeed = 0;
        for jj = 1:numel(allVehicles)
            if jj==selfIndex || ~allVehicles(jj).active, continue; end
            other = allVehicles(jj);
            [ox,oy,oh] = roadPoseV4(map,other.pathId,other.distance);
            otherDir = [cos(oh) sin(oh)];
            if dot(selfDir,otherDir) < 0.82, continue; end
            [projectedS,lateral] = projectToPath([ox oy],currentPath);
            if lateral > 1.9, continue; end
            deltaS = projectedS-self.distance;
            if deltaS <= 0.1, continue; end
            candidateGap = deltaS-other.vehicleLength;
            if candidateGap < bestGap
                bestGap = candidateGap;
                leaderSpeed = other.speed;
            end
        end
        found = isfinite(bestGap);
        if found
            gap = max(0.1,bestGap-self.vehicleLength*0.15);
        else
            gap = inf;
        end
    end

    function [sProj,lateral] = projectToPath(point,pth)
        xy = pth.xy;
        bestD2 = inf;
        sProj = 0;
        for mm = 1:size(xy,1)-1
            segment = xy(mm+1,:)-xy(mm,:);
            seg2 = dot(segment,segment);
            if seg2 < eps, continue; end
            u = max(0,min(1,dot(point-xy(mm,:),segment)/seg2));
            q = xy(mm,:)+u*segment;
            d2 = sum((point-q).^2);
            if d2 < bestD2
                bestD2 = d2;
                sProj = pth.s(mm)+u*(pth.s(mm+1)-pth.s(mm));
            end
        end
        lateral = sqrt(bestD2);
    end

    function vNew = freeSpeed(vNow,vDesired)
        % Project_v2 Gipps free-acceleration branch.
        reactionTime = 0.8;
        maxAcc = 3.0;
        vNew = vNow + 2.5*maxAcc*reactionTime* ...
            (1-vNow/vDesired)*sqrt(max(0,0.025+vNow/vDesired));
        vNew = min(vNew,vDesired);
    end

    function vNew = gippsSpeed(vNow,vLead,spacing,vDesired)
        % Numerically guarded form of Project_v2's Gipps model.
        reactionTime = 0.8;
        maxAcc = 3.0;
        minAcc = -3.0;
        s0 = 2.0;
        vA = vNow + 2.5*maxAcc*reactionTime* ...
            (1-vNow/vDesired)*sqrt(max(0,0.025+vNow/vDesired));
        disc = (minAcc*reactionTime)^2 - minAcc*( ...
            2*(spacing-s0)-vNow*reactionTime-vLead^2/minAcc);
        vB = minAcc*reactionTime + sqrt(max(0,disc));
        vNew = max(0,min([vA vB vDesired]));
    end

    function vNew = idmSpeed(vNow,vLead,spacing,vDesired,step)
        % Project_v2 IDM parameters and desired-spacing equation.
        accelMax = 0.73;
        decelComfort = 1.67;
        safeHeadway = 1.6;
        jamSpacing = 2.0;
        speedDiff = vLead-vNow;
        desiredSpacing = jamSpacing + vNow*safeHeadway - ...
            vNow*speedDiff/(2*sqrt(accelMax*decelComfort));
        spacing = max(0.5,spacing);
        acceleration = accelMax*(1-(vNow/vDesired)^4- ...
            (desiredSpacing/spacing)^2);
        acceleration = min(max(acceleration,-5),3);
        vNew = max(0,vNow+acceleration*step);
    end

    function vNew = idmFreeSpeed(vNow,vDesired,step)
        acceleration = 0.73*(1-(vNow/vDesired)^4);
        acceleration = min(max(acceleration,-5),3);
        vNew = max(0,vNow+acceleration*step);
    end

    function phase = phaseAt(timeNow)
        localTime = mod(timeNow,cycleDuration);
        index = find(localTime < signalEdges(2:end),1,'first');
        if isempty(index), index = numel(signalPhases); end
        phase = signalPhases(index);
    end

    function remaining = phaseRemaining(timeNow)
        localTime = mod(timeNow,cycleDuration);
        index = find(localTime < signalEdges(2:end),1,'first');
        if isempty(index), index = numel(signalPhases); end
        remaining = signalEdges(index+1)-localTime;
    end
end

function vehicles = emptyVehicleArray()
vehicles = struct('id',{},'kind',{},'approach',{},'movement',{}, ...
    'pathId',{},'nextPathId',{},'slot',{},'stage',{},'distance',{}, ...
    'speed',{},'acceleration',{},'desiredSpeed',{},'maxSpeed',{}, ...
    'vehicleLength',{},'entryTime',{},'waitStart',{},'twoStageWait',{}, ...
    'active',{},'hasEntered',{},'drawHandle',{});
end

function phase = movementPhase(approach,movement)
% Wu approach order: 1=W, 2=E, 3=N, 4=S.
if approach<=2
    if movement==1, phase=2; else, phase=1; end
else
    if movement==1, phase=4; else, phase=3; end
end
end

function phase = firstLegPhase(approach)
% First scooter leg crosses the approach road on its straight/right green.
if approach<=2, phase=1; else, phase=3; end
end

function phase = secondLegPhase(approach)
% Second scooter leg uses the perpendicular straight green, never car-left.
if approach<=2, phase=3; else, phase=1; end
end

function deleteVehicleGraphic(h)
if ~isstruct(h), return; end
if isfield(h,'body') && ~isempty(h.body) && isgraphics(h.body), delete(h.body); end
if isfield(h,'lamp') && ~isempty(h.lamp) && isgraphics(h.lamp), delete(h.lamp); end
end
