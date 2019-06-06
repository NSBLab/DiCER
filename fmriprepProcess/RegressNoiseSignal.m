function Xresid = RegressNoiseSignal(X,N)
% Regress out the noise signal, N from a data x time time-series matrix, X
%-------------------------------------------------------------------------------

% Get inverse
Nstar = pinv(N');

% Regress noise signal estimate onto X and take residuals:
Xresid = (X' - N'*Nstar*X')';

end
