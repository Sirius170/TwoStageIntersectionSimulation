%% 版本更新：2026-10-23
% 10/22 baseline: compare convergence curves for five algorithms
% Settings: population size = 20, iterations/generations = 20.
% START_HERE2 inflow remains [800, 800, 500, 500].
% Run this script from the OpenTrafficLab project root folder.

clear; clc;

% 1. Read saved convergence history (relative paths from project root)
ga_curve    = readtable(fullfile('GA',    'GA_20_Pop20_Convergence_Curve.xlsx'));
cpode_curve = readtable(fullfile('CPODE', 'CPODE_20_Pop20_Convergence_Curve.xlsx'));
gwo_curve   = readtable(fullfile('GWO',   'GWO_20_Pop20_Convergence_Curve.xlsx'));
pso_curve   = readtable(fullfile('PSO',   'PSO_20_Pop20_Convergence_Curve.xlsx'));
sa_curve    = readtable(fullfile('SA',    'SA_20_T1500_Convergence_Curve.xlsx'));

% 2. Validate required column names
curves = {ga_curve, cpode_curve, gwo_curve, pso_curve, sa_curve};
names  = {'GA', 'CPO-DE', 'GWO', 'PSO', 'SA'};

for k = 1:numel(curves)
    if ~all(ismember({'Iteration', 'BestCost'}, ...
            curves{k}.Properties.VariableNames))
        error('%s convergence file must contain columns named Iteration and BestCost.', ...
            names{k});
    end
end

% 3. Plot all five convergence curves in one figure
fig = figure( ...
    'Name', '10/22 Five-Algorithm Convergence Comparison', ...
    'Color', 'w', ...
    'Position', [100, 100, 1000, 600]);

hold on;

plot(ga_curve.Iteration, ga_curve.BestCost, '-o', ...
    'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', 'GA');

plot(cpode_curve.Iteration, cpode_curve.BestCost, '-s', ...
    'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', 'CPO-DE');

plot(gwo_curve.Iteration, gwo_curve.BestCost, '-^', ...
    'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', 'GWO');

plot(pso_curve.Iteration, pso_curve.BestCost, '-d', ...
    'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', 'PSO');

plot(sa_curve.Iteration, sa_curve.BestCost, '-v', ...
    'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', 'SA');

xlabel('Iteration / recorded step');
ylabel('Best total waiting time (seconds)');
title('10/22 Convergence Curves: GA, CPO-DE, GWO, PSO, SA');

legend('Location', 'best');
grid on;
box on;
hold off;

% 4. Export figures to the project root
exportgraphics(fig, ...
    '10-22_Five_Algorithm_Convergence.png', ...
    'Resolution', 300);

savefig(fig, '10-22_Five_Algorithm_Convergence.fig');

disp('Saved: 10-22_Five_Algorithm_Convergence.png and .fig');