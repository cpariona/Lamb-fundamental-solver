function [experimental, physics, review] = reviewOceInversionPhysics(study, assembly, observationReview, family)
%REVIEWOCEINVERSIONPHYSICS Validate reviewed family-specific current geometry.
% No model equations, frequency masks or recorded OCE observations are changed.
experimental=assembly.experimental;
family=string(family);
review=study.review;
if family=="RayleighLamb"
    physics=study.fitConfig;
    if study.thicknessPolicy=="oce_directional_per_acquisition"
        recorded=directionalThickness(assembly,observationReview);
        relevant=isfinite(experimental.frequency_Hz)&experimental.frequency_Hz>0;
        assert(all(isfinite(recorded(relevant))&recorded(relevant)>0), ...
            'lamb:study:MissingThickness','Missing signed-direction current thickness at positive Hz.');
        experimental.observationThickness_m=recorded;
        physics.fixedParams.thickness=recorded(find(relevant,1));
        review.thicknessSource="OCE directional_mean_thickness_mm; selected signed direction";
        review.thicknessJustification="Recorded current thickness per acquisition, no averaging";
        selected=recorded(experimental.validMask);
        fprintf('RL OCE thickness range: %.6f to %.6f mm; %d exact groups.\n', ...
            min(selected)*1e3,max(selected)*1e3,numel(unique(selected)));
    else
        assert(study.thicknessPolicy=="explicit_constant", ...
            'lamb:study:ThicknessPolicy','RL requires a reviewed thickness policy.');
    end
    assert(any(string(physics.branchName)==["A0","S0"])&&review.mode==physics.branchName, ...
        'lamb:study:ModelReview','Review A0/S0 before inversion.');
    for name=["thicknessSource","thicknessJustification","densityReference", ...
            "parameterJustification","modelSupportReference"]
        checkText(review,name);
    end
    % Preflight native physics, without running a forward solve.
    lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental,physics);
elseif family=="Plate"
    assert(study.estimator=="kf_ridge", ...
        'lamb:study:PlateEstimator','Plate requires original k-f observations.');
    physics=study.physical;
    if isfield(study,'thicknessPolicy')&& ...
            study.thicknessPolicy=="oce_reference_acquisition"
        reference=study.thicknessReferenceSourceIndex;
        validateattributes(reference,{'double'}, ...
            {'scalar','integer','positive','<=',height(study.sourceMetadata)});
        recorded=directionalThickness(assembly,observationReview);
        rows=observationReview.sourceIndex==reference;
        candidates=unique(recorded(rows));
        assert(isscalar(candidates)&&isfinite(candidates)&&candidates>0, ...
            'lamb:study:MissingThickness','The reviewed Plate reference acquisition has no thickness.');
        physics.thickness_m=candidates;
        review.thicknessSource="OCE directional_mean_thickness_mm; signed-direction source index "+reference;
        review.thicknessJustification="One explicitly selected source acquisition is a scalar reference; no averaging";
    else
        assert(~isfield(study,'thicknessPolicy')|| ...
            study.thicknessPolicy=="explicit_constant_current_thickness", ...
            'lamb:study:ThicknessPolicy','Plate requires explicit constant or reference acquisition.');
    end
    % Plate's q=pi*f*h/Cp requires a single thickness; varying-h Plate is
    % not implemented by copying RL's exact-thickness grouping policy.
    review.thicknessPolicy="explicit_constant_current_thickness";
    assert(review.mode=="A0",'lamb:study:ModelReview','Review Plate A0 mode.');
    for name=["density_kgpm3","thickness_m"]
        validateattributes(physics.(name),{'double'},{'scalar','finite','real','positive'});
    end
    for name=["thicknessSource","thicknessJustification","densityReference","modelSupportReference"]
        checkText(review,name);
    end
    recorded=directionalThickness(assembly,observationReview);
    chosen=recorded(experimental.validMask);
    finite=chosen(isfinite(chosen));
    if ~isempty(finite)
        fprintf('Plate reference thickness %.6f mm; OCE measured selected range %.6f to %.6f mm.\n', ...
            physics.thickness_m*1e3,min(finite)*1e3,max(finite)*1e3);
    end
else
    error('lamb:study:ModelFamily','Unsupported inversion family.');
end
end

function thickness=directionalThickness(assembly,observationReview)
n=height(observationReview);
if isfield(assembly,'measuredThickness_m')
    thickness=double(assembly.measuredThickness_m(:));
else
    thickness=nan(n,1);
    for j=1:numel(assembly.prepared)
        thickness(observationReview.sourceIndex==j)= ...
            double(assembly.prepared{j}.measuredThickness_m);
    end
end
assert(numel(thickness)==n,'lamb:study:ThicknessAlignment', ...
    'Signed-direction thickness must align with original observation rows.');
end

function checkText(value,name)
s=string(value.(name));
assert(isscalar(s)&&~ismissing(s)&&strlength(strtrim(s))>0, ...
    'lamb:study:PhysicalReview','%s needs an explicit review.',name);
end
