function assertOceInversionReviewMatch(archivedReview, currentReview)
%ASSERTOCEINVERSIONREVIEWMATCH Prevent figure/MAT scientific provenance drift.
% A numerically reusable native fit does not authorize new researcher claims
% under an archived scientific record. Legacy labels are normalized in memory.
archived=normalizeInverseProvenance(archivedReview);
current=normalizeInverseProvenance(currentReview);
assert(isequaln(orderfields(archived),orderfields(current)), ...
    'lamb:study:ScientificReviewMismatch', ...
    ['The archived scientific review differs from the current review. ' ...
    'Use the archived review or a new outputTag for separately reviewed figures.']);
end
