function names = mrlfeModelCandidateNames(modelName)
%MRLFEMODELCANDIDATENAMES Return primary mRLFE model name plus legacy aliases.
%
% The maintained viscoelastic real-k model name is mRLFEViscoRealK. The
% author-labeled Han name is retained only as a legacy alias for old cached
% results or archived scripts.

modelName = string(modelName);
switch modelName
    case "mRLFEViscoRealK"
        names = ["mRLFEViscoRealK", "mRLFEHanViscoRealK"];
    case "mRLFERealK"
        names = ["mRLFERealK", "mRLFEViscoRealK", "mRLFEHanViscoRealK", "mRLFEElasticRealK"];
    case "mRLFEElasticRealK"
        names = ["mRLFEElasticRealK", "mRLFERealK"];
    otherwise
        names = modelName;
end
end
