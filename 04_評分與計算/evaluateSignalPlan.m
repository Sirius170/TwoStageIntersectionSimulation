function [cost, details] = evaluateSignalPlan(phaseSeconds)
% EVALUATESIGNALPLAN Evaluate a feasible 4-phase plan on the Wu V4 core.
%
% Input order:
% [EW_through, EW_protected_left, NS_through, NS_protected_left]
%
% The fixed 78-second cycle is enforced here, not inside PSO/SA.
% Current cost includes the accumulated stopped time reported by Wu V4.
% Pedestrian waiting is deliberately reserved for a future extension and
% is NOT included until pedestrian simulation/statistics exist.

config = getSignalOptimizationConfig();

validateattributes(phaseSeconds, {'numeric'}, ...
    {'vector','numel',4,'real','finite'});

phaseSeconds = reshape(phaseSeconds,1,[]);
tol = 1e-8;

if any(phaseSeconds < config.minGreenSeconds-tol) || ...
        any(phaseSeconds > config.maxGreenSeconds+tol)
    error('evaluateSignalPlan:GreenBounds', ...
        'Each green phase must be between %.1f and %.1f seconds.', ...
        config.minGreenSeconds,config.maxGreenSeconds);
end

if abs(sum(phaseSeconds)-config.totalGreenSeconds)>tol
    error('evaluateSignalPlan:FixedCycle', ...
        ['Infeasible plan: green times must sum to %.1f seconds ' ...
         'for the fixed %.1f-second cycle.'], ...
        config.totalGreenSeconds,config.cycleSeconds);
end

% The simulation core seeds MATLAB's global RNG to make traffic arrivals
% repeatable. Save/restore the optimizer RNG so simulation calls do not
% reset PSO/SA random search sequences.
optimizerRngState = rng;
rngCleanup = onCleanup(@() rng(optimizerRngState)); %#ok<NASGU>

result = runWuProjectV2Simulation( ...
    phaseSeconds, ...
    config.simulationSeconds, ...
    config.inflow, ...
    config.turnWeights, ...
    config.playbackSpeed, ...
    config.motorcycleShare, ...
    config.showPaths, ...
    config.carFollowingModel, ...
    config.enableVisualization);

if abs(result.cycleDurationSeconds-config.cycleSeconds)>tol
    error('evaluateSignalPlan:CoreCycleMismatch', ...
        ['Wu V4 core produced a %.3f-second cycle; expected %.3f seconds. ' ...
         'Check yellow/all-red timing in the simulation core.'], ...
        result.cycleDurationSeconds,config.cycleSeconds);
end

cost = result.totalWaitSeconds;
if ~isscalar(cost) || ~isfinite(cost) || cost < 0
    error('evaluateSignalPlan:InvalidCost', ...
        'Wu V4 core returned an invalid total waiting-time cost.');
end

if nargout > 1
    details = struct();
    details.phaseSeconds = phaseSeconds;
    details.cycleDurationSeconds = result.cycleDurationSeconds;
    details.carMotorcycleWaitSeconds = result.totalWaitSeconds;
    details.pedestrianWaitSeconds = NaN; % Reserved; not simulated yet.
    details.pedestrianIncluded = false;
    details.twoStageWaitSeconds = result.twoStageWaitSeconds;
    details.twoStageCompleted = result.twoStageCompleted;
    details.completedCars = result.completedCars;
    details.completedMotorcycles = result.completedMotorcycles;
    details.rawSimulationResult = result;
end
end
