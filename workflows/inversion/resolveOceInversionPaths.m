function study = resolveOceInversionPaths(study, family)
%RESOLVEOCEINVERSIONPATHS Resolve experiment-contained, configurable relative outputs.
% Only experimentRoot is a machine-local anchor. All persisted destinations
% are constructed from root-relative paths; no absolute output override.
family=string(family);
assert(isscalar(family)&&any(family==["RayleighLamb","Plate"]), ...
    'lamb:study:ModelFamily','Select RayleighLamb or Plate.');
root=string(study.experimentRoot);
assert(isscalar(root)&&~ismissing(root)&&strlength(strtrim(root))>0&&isfolder(root), ...
    'lamb:study:ExperimentRoot','Supply an existing experiment root.');
sub=safePart(study.subexperimentId);
if isfield(study,'summaryRelativeFile') && ...
        strlength(string(study.summaryRelativeFile))>0
    summaryRel=safeRelative(study.summaryRelativeFile);
elseif ~isfield(study,'resolvedSummaryRelativeFile') && ...
        isfield(study,'summaryFile') && strlength(string(study.summaryFile))>0
    summaryRel=safeRelative(study.summaryFile);
else
    summaryRel=fullfile("Results",sub,"summary.mat");
end
study.resolvedSummaryRelativeFile=summaryRel;
study.summaryFile=fullfile(root,summaryRel);
if ~isfield(study,'outputTag'),study.outputTag="";end
tag=string(study.outputTag);
if strlength(tag)>0
    tag=safePart(tag);
else
    period="";
    if study.mode=="Pulse",period="_"+safePart(study.period_us)+"us";end
    tag=safePart(study.mode+period+"_"+study.conditionId+ ...
        "_axis"+string(study.scanAxisIndex)+"_"+study.direction);
end
if ~isfield(study,'outputRelativeFolder')||strlength(string(study.outputRelativeFolder))==0
    destination=fullfile("Results",sub,"Inversions",family,tag);
else
    destination=safeRelative(study.outputRelativeFolder);
end
study.resolvedOutputRelativeFolder=destination;
study.resultFile=fullfile(root,destination,"inversion.mat");
study.figureFolder=fullfile(root,destination);
study.figureName="inversion";
% Never allow accidental study overwrites. This is checked again at saving.
end

function value=safePart(value)
value=string(value);
assert(isscalar(value)&&~ismissing(value)&& ...
    ~isempty(regexp(char(value),'^[A-Za-z0-9][A-Za-z0-9_.-]*$','once'))&& ...
    value~="."&&value~="..", ...
    'lamb:study:UnsafeOutputPath','An output identity contains unsafe characters.');
end

function value=safeRelative(value)
value=string(value);
assert(isscalar(value)&&~ismissing(value)&&strlength(value)>0, ...
    'lamb:study:UnsafeOutputPath','A nonempty relative path is required.');
% Validate both separator conventions, including on a non-Windows runner.
normalized=replace(value,"\\","/");
parts=split(normalized,"/");
assert(~startsWith(normalized,"/")&&~contains(normalized,":")&& ...
    all(parts~=""&parts~="."&parts~=".."), ...
    'lamb:study:UnsafeOutputPath','Output and summary paths must be root-relative.');
for part=parts(:)'
    safePart(part);
end
value=fullfile(parts{:});
end
