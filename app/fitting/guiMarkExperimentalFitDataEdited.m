function metadata = guiMarkExperimentalFitDataEdited(metadata)
%GUIMARKEXPERIMENTALFITDATAEDITED Preserve provenance and mark manual edits.

if nargin < 1 || isempty(metadata) || ~isstruct(metadata)
    metadata = struct();
end
if ~isfield(metadata, 'sourceType') || isempty(metadata.sourceType)
    metadata.sourceType = "editable_table";
end
metadata.wasManuallyEdited = true;
end
