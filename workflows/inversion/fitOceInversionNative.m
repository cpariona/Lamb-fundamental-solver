function [nativeResult, reused, physics] = fitOceInversionNative(study, assembly, experimental, physics, review, sourceFiles, family)
%FITOCEINVERSIONNATIVE Reuse exact requests or delegate to native family fitting.
% No estimation of bandwidth, weights, model support or material parameters.
family=string(family);
existing=study.existingNativeResult;
existingAssembly=study.existingAssembly;
if isempty(existing)&&isfile(study.resultFile)
    saved=load(study.resultFile,'nativeResult','assembly');
    existing=saved.nativeResult;existingAssembly=saved.assembly;
end
reused=false;
fitOptions=struct();
if family=="Plate"
    fitOptions=study.fitOptions;
    if isempty(fieldnames(fitOptions)) && ~isempty(existing) && ...
            isfield(existing,'options')
        fitOptions=existing.options;
    end
end
if ~isempty(existing)&&~isempty(existingAssembly)
    if isfield(existingAssembly,'sourceResultFiles')
        recordedFiles=string(existingAssembly.sourceResultFiles(:));
    else
        recordedFiles=string({existingAssembly.lineage.resultFile})';
    end
    same=isequal(recordedFiles,string(sourceFiles(:)));
    if family=="RayleighLamb"
        nativeProblem=lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental,physics);
        effective=rmfield(nativeProblem,{'evaluateModel','residualFunction','objectiveFunction'});
        same=same&&string(existing.modelFamily)=="rayleigh_lamb"&& ...
            isequaln(existing.problem,effective);
        if study.mode=="QH"&&study.estimator=="kf_ridge"
            same=same&&isequaln(existingAssembly.physicalFrequency_Hz,assembly.physicalFrequency_Hz)&& ...
                isequaln(existingAssembly.requestedTargetFrequency_Hz,assembly.requestedTargetFrequency_Hz)&& ...
                isequal([existingAssembly.lineage.binIndex],[assembly.lineage.binIndex]);
        end
    else
        same=same&&isequaln(existing.physical,physics)&&isequaln(existing.options,fitOptions);
        for name=string(fieldnames(experimental))'
            same=same&&isfield(existing.experimental,name)&& ...
                isequaln(existing.experimental.(name),experimental.(name));
        end
        if study.mode=="QH"
            same=same&&isequaln(existingAssembly.physicalFrequency_Hz,assembly.physicalFrequency_Hz)&& ...
                isequaln(existingAssembly.requestedTargetFrequency_Hz,assembly.requestedTargetFrequency_Hz);
        else
            same=same&&~isfield(existing.experimental,'independentFrequencyGroupId');
        end
    end
    if same,nativeResult=existing;reused=true;end
end
assert(reused||~study.reuseOnly,'lamb:study:RequestMismatch', ...
    'No identical native result: review mask and configuration before enabling a new fit.');
if ~reused
    if family=="RayleighLamb"
        nativeResult=lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimental,physics);
    elseif study.mode=="QH"
        outcome=fitOceQhPrestressedPlate(assembly,physics,review,fitOptions);
        nativeResult=outcome.nativeResult;
    else
        nativeResult=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
            experimental,physics,fitOptions);
    end
end
assert(isequal(nativeResult.validMask,experimental.validMask), ...
    'lamb:study:NativeMask','Native result must retain the reviewed mask.');
if family=="RayleighLamb"
    assert(isequaln(nativeResult.frequency_Hz,experimental.frequency_Hz)&& ...
        isequaln(nativeResult.Cp_exp_mps,experimental.Cp_mps), ...
        'lamb:study:NativeRows','RL must retain the original observation rows.');
end
end
