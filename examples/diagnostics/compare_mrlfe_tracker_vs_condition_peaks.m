% Compare current mRLFE tracker against a brute-force condition/residual scan.
%
% Purpose:
%   This diagnostic is meant to answer a practical question raised during
%   solver review: is the current tracker following a mode-relevant continuous
%   branch, or is it simply missing roots that a brute-force condition-number
%   scan would find?
%
% What is compared:
%   1) Current project solver: