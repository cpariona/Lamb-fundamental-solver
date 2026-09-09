function test_ae_production_architecture_contract()
%TEST_AE_PRODUCTION_ARCHITECTURE_CONTRACT Guard canonical AE ownership.

repoRoot = testRepositoryRoot();
modelRoot = fullfile(repoRoot, 'src', '+lamb', '+models', '+acoustoelastic_iop_hgo');

assert(~isfile(fullfile(modelRoot, '+solvers', ...
    'solveAcoustoelasticIOPHGOAtlasBranch.m')), ...
    'The obsolete AE forwarding API must remain removed.');

publicOwner = fullfile(modelRoot, 'aeSolveBranch.m');
assert(samePath(which('lamb.models.acoustoelastic_iop_hgo.aeSolveBranch'), publicOwner), ...
    'The public AE entrypoint must resolve to its canonical model owner.');

atlasSolverText = matlabCode(fullfile(modelRoot, '+solvers', 'aeSolveAtlasBranch.m'));
selectionPosition = callPosition(atlasSolverText, ...
    'lamb\.models\.acoustoelastic_iop_hgo\.policies\.aeSelectAtlasA0Branch');
refinementPosition = callPosition(atlasSolverText, ...
    'lamb\.models\.acoustoelastic_iop_hgo\.tracking\.aeRefineSelectedAtlasBranch');
assert(refinementPosition > selectionPosition, ...
    'AE refinement must remain after discrete atlasA0 selection.');

refinementText = matlabCode(fullfile(modelRoot, '+tracking', ...
    'aeRefineSelectedAtlasBranch.m'));
assert(~isempty(regexp(refinementText, '\<fminbnd\s*\(', 'once')) && ...
    ~isempty(regexp(refinementText, ...
    'lamb\.models\.acoustoelastic_iop_hgo\.core\.aeObjectiveResidual\s*\(', 'once')), ...
    'AE refinement must minimize the true SVD objective with fminbnd.');
assert(isempty(regexp(lower(refinementText + newline + atlasSolverText), ...
    '\<parabolic\w*\s*\(', 'once')), ...
    'AE production must not reintroduce parabolic refinement.');

fprintf('AE production architecture contract passed.\n');
end

function position = callPosition(text, qualifiedNamePattern)
positions = regexp(text, qualifiedNamePattern + "\s*\(");
assert(isscalar(positions), 'Expected exactly one production call matching %s.', qualifiedNamePattern);
position = positions;
end

function text = matlabCode(path)
text = string(fileread(path));
text = regexprep(text, '%\{[\s\S]*?%\}', ' ');
text = regexprep(text, '%[^\r\n]*', ' ');
end

function tf = samePath(actual, expected)
tf = strcmpi(replace(string(actual), "\", "/"), replace(string(expected), "\", "/"));
end
