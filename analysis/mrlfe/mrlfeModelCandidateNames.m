function names = mrlfeModelCandidateNames(modelName)
%MRLFEMODELCANDIDATENAMES Return canonical mRLFE model candidate names.
%
% This helper intentionally exposes only maintained physical model names.

modelName = string(modelName);
switch modelName
    case "mRLFEViscoRealK"
        names = "mRLFEViscoRealK";
    case "mRLFERealK"
        names = ["mRLFERealK", "mRLFEViscoRealK", "mRLFEElasticRealK"];
    case "mRLFEElasticRealK"
        names = ["mRLFEElasticRealK", "mRLFERealK"];
    otherwise
        names = modelName;
end
end
