% [V,D] = orderedeigs(M)
%
% Like eigs, but ensures that the eigenvalues are in order
%
% Given a matrix M with real eigenvalues, computes the eigenvalue
% decomposition and returns decomposition M*V = V*D so that the eigenvalues
% are in decreasing order on the diagonal of D

function [V,D] = orderedeigs(M, varargin)

[V,D] = eigs(M, varargin{:});
[~,idx] = sort(diag(D),1,'descend');
V = V(:, idx);
D = diag(D);
D = diag(D(idx));

end