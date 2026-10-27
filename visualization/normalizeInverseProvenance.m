function provenance = normalizeInverseProvenance(provenance)
%NORMALIZEINVERSEPROVENANCE Read historic review labels without altering files.
% Legacy values are researcher statements, never computed model support.
assert(isstruct(provenance) && isscalar(provenance), ...
    'lamb:visualization:Provenance','Provide scalar provenance metadata.');
pairs = ["modelSupportReference","modelAssumptionsJustification"; ...
    "densityReference","densitySource"; ...
    "parameterJustification","fitParameterJustification"];
for k=1:size(pairs,1)
    previous=char(pairs(k,1)); current=char(pairs(k,2));
    if isfield(provenance,previous)
        assert(~isfield(provenance,current), ...
            'lamb:visualization:AmbiguousProvenance', ...
            'Do not supply legacy and current names for one review field.');
        provenance.(current)=provenance.(previous);
        provenance=rmfield(provenance,previous);
    end
end
if isfield(provenance,'mode')
    branch=string(provenance.mode);
    if isscalar(branch) && any(branch==["A0","S0"])
        assert(~isfield(provenance,'modelBranch'), ...
            'lamb:visualization:AmbiguousProvenance', ...
            'Do not supply two modal review identities.');
        provenance.modelBranch=branch;
        provenance=rmfield(provenance,'mode');
    end
end
end
