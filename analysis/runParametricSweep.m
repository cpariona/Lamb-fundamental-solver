function S=runParametricSweep(p,o,sp)
% Compact one-parameter sweep.
q=char(sp.parameter); v=sp.values(:)'; n=numel(v);
if ~isfield(sp,'label'), sp.label=q; end
if ~isfield(sp,'units'), sp.units=''; end
if ~isfield(sp,'scale'), sp.scale=1; end
S=struct('spec',sp,'values',v,'results',{cell(1,n)},'params',{cell(1,n)},'options',{cell(1,n)});
for i=1:n
    pp=p; oo=o;
    if isfield(pp,q)
        pp.(q)=v(i);
    else
        if ~isfield(oo,'mrlfe