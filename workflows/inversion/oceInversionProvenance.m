function record = oceInversionProvenance(inputFiles, projectRoot, captureCode)
%OCEINVERSIONPROVENANCE Fingerprint current inputs for human OCE inversion workflows.
% Current bytes and code state do not verify historical ProcessingRun inputs.
% captureCode defaults to true for the complete persisted record. False returns
% only inputFiles, without locating or querying either code repository.
if nargin<3,captureCode=true;end
validateattributes(captureCode,{'logical'},{'scalar'});
paths=string(inputFiles);paths=unique(paths(:),'stable');
bytes=zeros(numel(paths),1);sha256=strings(numel(paths),1);
for k=1:numel(paths)
    fid=fopen(paths(k),'rb');
    assert(fid>=0,'lamb:study:UnreadableInput','Cannot hash input: %s',paths(k));
    closeFile=onCleanup(@() fclose(fid));
    digest=java.security.MessageDigest.getInstance('SHA-256');
    while ~feof(fid)
        chunk=fread(fid,1024*1024,'*uint8');bytes(k)=bytes(k)+numel(chunk);digest.update(chunk);
    end
    sha256(k)=lower(string(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[])));
    clear closeFile
end
inputManifest=table(paths,bytes,sha256,'VariableNames',{'path','bytes','sha256'});
if ~captureCode
    record=struct('inputFiles',inputManifest);
    return
end
oceRoot=fileparts(fileparts(fileparts(fileparts(which('oce.results.recoverSummaryObservations')))));
record=struct('matlabVersion',string(version),'matlabRelease',string(version('-release')), ...
    'code',struct('Lamb',repositoryState(projectRoot),'OCE',repositoryState(oceRoot)), ...
    'inputFiles',inputManifest, ...
    'provenanceScope',"current_input_bytes_unchanged_during_this_study", ...
    'historicalProcessingContentVerified',false);
end

function state=repositoryState(root)
state=struct('root',string(root),'commit',"unknown",'status',"",'available',false);
if strlength(string(root))==0,return;end
prefix=sprintf('git --no-optional-locks -c safe.directory="%s" -c core.quotepath=false -C "%s" ',root,root);
[headStatus,head]=system([prefix 'rev-parse HEAD']);
[statusCode,status]=system([prefix 'status --porcelain=v1 --untracked-files=all']);
state.status=string(status);state.available=headStatus==0&&statusCode==0;
if state.available,state.commit=strtrim(string(head));end
end
