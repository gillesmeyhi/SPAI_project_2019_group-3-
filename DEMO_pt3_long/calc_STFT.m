function [X,f] = calc_STFT(x,fs,window,nfft,noverlap, sides)
%CALC_STFT short-time fourier transform using OLA. The STFT uses a
%sqrt(hann(nfft)) window.
%
% INPUT:
%   x           : input time signal(s) (samples x channels)
%   fs          : sampling rate
%   window      : window function
%   nfft        : FFT size
%   noverlap    : frame overlap; default: 2 (50%)
%   sides       : 'onesided' or 'twosided'
%
% OUTPUT:
%   X           : STFT matrix (bins x frames x channels)
%   f           : frequency vector for bins


% use only half FFT spectrum
N_half = nfft / 2 + 1;

% get frequency vector
f = 0:(fs / 2) / (N_half - 1):fs / 2;
if strcmp(sides, 'twosided')
    f = [f, -f(end-1:-1:2)];
end

% init
L = floor((length(x) - nfft + (nfft / noverlap)) / (nfft / noverlap));
M = size(x,2);
if strcmp(sides, 'onesided')
    X = zeros(N_half, L, M);
elseif strcmp(sides, 'twosided')
    X = zeros(nfft, L, M);
end
% % OLA processing
for m = 0:M-1
    for l = 0:L-1 % Frame index
        x_frame = x(floor(l*(nfft / noverlap) + 1): ...
            floor(l*(nfft / noverlap) + nfft),m+1);
        X_frame = fft(window.*x_frame);
        if strcmp(sides, 'onesided')
            X(:,l+1,m+1) = X_frame(1 : size(X_frame,1) / 2 + 1, :);
        elseif strcmp(sides, 'twosided')
            X(:,l+1,m+1) = X_frame;
        end
    end
end

end