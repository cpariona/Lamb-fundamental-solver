function id = oceInversionConditionId(keys, condition)
%OCEINVERSIONCONDITIONID Stable path-safe identity from exact recorded conditions.
% KEYS: ordered recorded metadata variable names. CONDITION: scalar struct of
% literal text or finite scalar numeric values. This is a path label only;
% the original typed CONDITION remains the authoritative fitting selector.
keys = string(keys(:));
assert(~isempty(keys) && numel(unique(keys)) == numel(keys), ...
    'lamb:study:ConditionIdentity','Provide unique recorded condition keys.');
assert(isstruct(condition) && isscalar(condition), ...
    'lamb:study:ConditionIdentity','A scalar recorded condition is required.');
parts = strings(numel(keys),1);
for j = 1:numel(keys)
    key = keys(j);
    assert(isfield(condition,char(key)), ...
        'lamb:study:ConditionIdentity','A recorded condition key is missing.');
    value = condition.(char(key));
    if isa(value,'double') && isscalar(value) && isfinite(value)
        literal = string(sprintf('%.17g',value));
        kind = "number";
    else
        assert((ischar(value) || isstring(value)) && ...
            isscalar(string(value)) && ~ismissing(string(value)), ...
            'lamb:study:ConditionIdentity', ...
            'Condition identity requires a finite double or literal text.');
        literal = string(value);
        kind = "text";
    end
    label=key+"_"+literal;
    if key=="strain_percent"
        % Compact display only; hash the unchanged full-precision literal.
        displayValue=literal;
        numericValue=str2double(literal);
        if isreal(numericValue) && isfinite(numericValue)
            displayValue=string(sprintf('%.3g',numericValue));
        end
        label="Strain_"+displayValue+"pct";
    end
    readable = string(matlab.lang.makeValidName( ...
        label,'ReplacementStyle','underscore'));
    digest = java.security.MessageDigest.getInstance('SHA-256');
    digest.update(uint8(unicode2native(char(kind+"|"+key+"="+literal),'UTF-8')));
    hash = lower(string(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[])));
    parts(j) = extractBefore(readable,min(strlength(readable)+1,25)) ...
        +"_"+extractBefore(hash,9);
end
id = strjoin(parts,"_");
end
