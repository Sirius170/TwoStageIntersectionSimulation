function report = checkWuProjectV2Map()
% Static interface check for Wu's road map and two-stage motorcycle routes.
root = fileparts(mfilename('fullpath'));
D = load(fullfile(root,'intersectionMap_v3_twoStage_v4.mat'),'map');
map = D.map;

assert(numel(map.paths)==30,'Expected 30 paths.');
assert(all([map.paths(1:14).stage]==0),'Paths 1-14 must be normal car paths.');
assert(all([map.paths(15:22).stage]==1),'Paths 15-22 must be first-leg paths.');
assert(all([map.paths(23:30).stage]==2),'Paths 23-30 must be second-leg paths.');

endpointErrors = zeros(4,2);
for approach = 1:4
    for slot = 1:2
        firstId = map.twoStage.firstPathIdsBySlot(approach,slot);
        secondId = map.twoStage.secondPathIds(approach,slot);
        first = map.paths(firstId);
        second = map.paths(secondId);
        endpointErrors(approach,slot) = norm(first.xy(end,:)-second.xy(1,:));
        assert(first.stage==1 && second.stage==2);
        assert(first.waitBox==second.waitBox,'Waiting-box ID mismatch.');
        assert(first.slot==second.slot,'Waiting-box slot mismatch.');
        assert(endpointErrors(approach,slot)<1e-6, ...
            'First-leg endpoint and second-leg start do not match.');
    end
end

report = struct('pathCount',numel(map.paths), ...
    'endpointErrors',endpointErrors,'passed',true);
fprintf('Wu map check passed: 30 paths, 8 matching two-stage handoffs.\n');
disp(endpointErrors);
end
