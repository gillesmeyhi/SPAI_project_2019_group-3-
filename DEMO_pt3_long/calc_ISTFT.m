function x = calc_ISTFT(X,window,nfft,noverlap, sides)
%CALC_ISTFT inverse short-time fourier transform using OLA. The ISTFT uses 
%a sqrt(hann(nfft)) window.
%
% INPUT:
%   X           : input matrix (bins x frames x channels)
%   window      : window function
%   nfft        : FFT size
%   noverlap    : frame overlap; default: 2 (50%)
%   sides       : 'onesided' or 'twosided'
%
% OUTPUT:
%   x           : output time signal(s)


L = size(X,2);
if strcmp(sides, 'onesided')
    x_tmp = ifft([X; conj(X(end-1:-1:2,:,:))], [], 1, 'symmetric');
elseif strcmp(sides, 'twosided')
    x_tmp = ifft(X, 'symmetric');
end

% Apply synthesis window
win_tmp = repmat(window, [1, size(x_tmp, 2), size(x_tmp, 3)]);
x_tmp = x_tmp.*win_tmp;
x_tmp = x_tmp(1:nfft,:,:);

% IFFT per frame
x = zeros((nfft / noverlap)*(L-1) + nfft, size(x_tmp, 3));

% OLA processing
for m = 0:L-1
    x(floor(m * (nfft / noverlap) + 1):floor(m * (nfft / noverlap) + nfft),:) = ...
        squeeze(x_tmp(:,m+1,:)) + ...
        x(floor(m * (nfft / noverlap) + ...
        1):floor(m * (nfft / noverlap) + nfft),:);
end

end