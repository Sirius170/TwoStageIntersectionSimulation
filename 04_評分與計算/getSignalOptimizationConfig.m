function config = getSignalOptimizationConfig()
% GETSIGNALOPTIMIZATIONCONFIG Shared signal-plan constraints for PSO and SA.
% Keep this as the single source of truth for the current fixed-cycle setup.
%
% Current cycle:
%   4 green phases + 4 yellow intervals + 4 all-red intervals = 78 s.
% Future variable-cycle support can be added here without rewriting the
% traffic simulation or the PSO/SA acceptance and update mechanisms.

config.cycleMode = 'fixed';
config.cycleSeconds = 78;
config.yellowSecondsPerPhase = 3.0;
config.allRedSecondsPerPhase = 1.5;
config.phaseCount = 4;
config.clearanceSeconds = config.phaseCount * ...
    (config.yellowSecondsPerPhase + config.allRedSecondsPerPhase);
config.totalGreenSeconds = config.cycleSeconds - config.clearanceSeconds;

config.minGreenSeconds = 10;
config.maxGreenSeconds = config.totalGreenSeconds - ...
    (config.phaseCount - 1) * config.minGreenSeconds;

config.initialPhases = [15 15 15 15];

% Simulation settings shared by every objective evaluation.
config.simulationSeconds = 120;
config.inflow = [300 300 300 300];
config.turnWeights = [20 60 20];
config.playbackSpeed = 0;
config.motorcycleShare = 0.35;
config.showPaths = false;
config.carFollowingModel = 'Gipps';
config.enableVisualization = false;

assert(abs(sum(config.initialPhases)-config.totalGreenSeconds)<1e-9, ...
    'Initial phase plan does not satisfy the fixed-cycle constraint.');
end
