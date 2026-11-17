function [nativeResult, reused, physics] = fitOceInversionNative(study, assembly, experimental, physics, review, sourceFiles, family)
%FITOCEINVERSIONNATIVE Reuse exact requests or delegate to native family fitting.
% Families: "RayleighLamb", "mRLFE" (canonical SI physics translated here to the
% native names), "AcoustoelasticIOPHGO" (physics.native) and "Plate".
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
    if family~="Plate"
        % Exact native request, including the unchanged observations and fixed mask.
        % The builders validate without optimizing (mRLFE may precompute its own cache).
        if family=="RayleighLamb"
            nativeProblem=lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental,physics);
            modelFamily="rayleigh_lamb";
        elseif family=="mRLFE"
            nativeProblem=lamb.fitting.mrlfe.mrlfeBuildFitProblem( ...
                experimental,translateOceMrlfeConfig(physics));
            modelFamily="mrlfe";
        else
            nativeProblem=lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem( ...
                experimental,physics.native);
            modelFamily="acoustoelastic_iop_hgo";
        end
        effective=rmfield(nativeProblem,{'evaluateModel','residualFunction','objectiveFunction'});
        same=same&&string(existing.modelFamily)==modelFamily&& ...
            isequaln(existing.problem,effective);
        if study.excitationMode=="QH"&&study.estimator=="kf_ridge"
            % Optional assembly fields must match exactly, including presence.
            same=same&&sameOptionalField(existingAssembly,assembly,'physicalFrequency_Hz')&& ...
                sameOptionalField(existingAssembly,assembly,'requestedTargetFrequency_Hz')&& ...
                sameLineageBins(existingAssembly,assembly);
        end
    else
        same=same&&isequaln(existing.physical,physics)&&isequaln(existing.options,fitOptions);
        for name=string(fieldnames(experimental))'
            same=same&&isfield(existing.experimental,name)&& ...
                isequaln(existing.experimental.(name),experimental.(name));
        end
        if study.excitationMode=="QH"
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
    elseif family=="mRLFE"
        nativeResult=lamb.fitting.mrlfe.mrlfeFitDispersionData( ...
            experimental,translateOceMrlfeConfig(physics));
    elseif family=="AcoustoelasticIOPHGO"
        nativeResult=lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData( ...
            experimental,physics.native);
    elseif study.excitationMode=="QH"
        outcome=fitOceQhPrestressedPlate(assembly,physics,review,fitOptions);
        nativeResult=outcome.nativeResult;
    else
        nativeResult=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
            experimental,physics,fitOptions);
    end
end
assert(isequal(nativeResult.validMask,experimental.validMask), ...
    'lamb:study:NativeMask','Native result must retain the reviewed mask.');
if family~="Plate"
    assert(isequaln(nativeResult.frequency_Hz,experimental.frequency_Hz)&& ...
        isequaln(nativeResult.Cp_exp_mps,experimental.Cp_mps), ...
        'lamb:study:NativeRows','%s must retain the original observation rows.',family);
end
end

function tf=sameOptionalField(a,b,name)
hasA=isfield(a,name);hasB=isfield(b,name);
tf=hasA==hasB&&(~hasA||isequaln(a.(name),b.(name)));
end

function tf=sameLineageBins(a,b)
hasA=isfield(a,'lineage')&&isfield(a.lineage,'binIndex');
hasB=isfield(b,'lineage')&&isfield(b.lineage,'binIndex');
tf=hasA==hasB&&(~hasA||isequal([a.lineage.binIndex],[b.lineage.binIndex]));
end
