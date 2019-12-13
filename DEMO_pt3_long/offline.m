close all; clear; clc

addpath(genpath(fullfile('C:\Users\Shana Reynders\Documents\SEMESTER 1 2019 - 2020\INDUSTRIELE WETENSCHAPPEN\R&D Signal Processing\Offline')));  

[y,Fs] = audioread("DEMO_pt3_long.wav");
left = y(:,1);
right = y(:,2);
[c,lags] = xcorr(left,right);

maxF = max(c);                                                              % Find max value over all elements.
indexOfFirstMax = find(c == maxF, 1, 'first');                              % Get first element that is the max.
maxY = c(indexOfFirstMax);
maxlag = lags(indexOfFirstMax);
if (maxlag > 0)
    left = left(maxlag:end);
else
    right = right(abs(maxlag):end);
end

[c,lags] = xcorr(left,right);

if(length(left)>length(right))
    left = left(1:end-(size(left,1)-size(right,1)));
else
    right = right(1:end-(size(right,1)-size(left,1)));
end

result = [left right];
%sound(result,Fs);

y_mic_1 = result(:,1);
y_mic_2 = result(:,2);


time_signal=[y_mic_1 y_mic_2];

Number_of_microphones = size(time_signal,2);  

Number_of_fft = 1024;                                                       
overlap_fft = Number_of_fft/2;                                              
hann_window = sqrt(hann(Number_of_fft,'periodic'));

%k = floor(Number_of_fft/2)+1; 
k = 512;
frequencies = 0:Fs/Number_of_fft:Fs/2;                              

[STFT_signal_1 freq_vector] = calc_STFT(time_signal(:,1), Fs,...
    hann_window, Number_of_fft, Number_of_fft/overlap_fft, 'onesided');
[STFT_signal_2 freq_vector] = calc_STFT(time_signal(:,2), Fs,...
    hann_window, Number_of_fft, Number_of_fft/overlap_fft, 'onesided');
STFT = [STFT_signal_1 STFT_signal_2];

[K_bins, L_time_frames] = size(STFT_signal_1(:,:,1)); 

[noisePowMat, SPP_1] = spp_calc(time_signal(:,1),Number_of_fft,...
       overlap_fft);
[noisePowMat, SPP_2] = spp_calc(time_signal(:,2),Number_of_fft,...
       overlap_fft);
   
SPP = [SPP_1;SPP_2];

Rnn = cell(K_bins, L_time_frames);  
Rnn(:) = {zeros(Number_of_microphones,Number_of_microphones)};              

Ryy = cell(K_bins, L_time_frames);  
Ryy(:) = {zeros(Number_of_microphones,Number_of_microphones)};              

Rxx = cell(K_bins, L_time_frames);  
Rxx(:) = {zeros(Number_of_microphones,Number_of_microphones)};                                                                          

sigma_sound = zeros(K_bins, L_time_frames);
sigma_noise = zeros(K_bins, L_time_frames);
single_gain_stft = zeros(K_bins, L_time_frames);                           
single_speech_stft = zeros(K_bins, L_time_frames);

lambda = 0.8;                                                            
SPP_thr = 0.999999;
Xi_min = 1e-6; 
%Xi_min = 1;
%alpha_n = 0.995;
alpha_n = 0.995;
alpha_s = 0.8;
%alpha_s = 0.8;

multiple_speech_stft = zeros(K_bins, L_time_frames);                    
W_mvdr = (1/Number_of_microphones)*ones(Number_of_microphones,K_bins);      
W_mc = (1/Number_of_microphones)*ones(Number_of_microphones,K_bins);
W_mc_1 = (1/Number_of_microphones)*ones(Number_of_microphones,K_bins);

tic
for l=2:L_time_frames                                                     
    
    for k = 1:K_bins                                                      
                
        % (1) CALCULATE Rnn WITH THE USE OF SPP THRESHOLDING  
        n = [STFT_signal_1(k,l); STFT_signal_2(k,l)];
        
        n_matrix = (1-lambda)*n*ctranspose(n);
        if(SPP_1(k,l) < SPP_thr)
            lambda = 0.99;
            Rnn(k,l) = cellfun(@(x) x*lambda,Rnn(k,l-1),'un',0);
            Rnn(k,l) = cellfun(@(x) x+n_matrix,Rnn(k,l-1),'un',0);
        else
            lambda = 0.0010;
            Rnn(k,l) = cellfun(@(x) x*lambda,Rnn(k,l-1),'un',0);
            Rnn(k,l) = cellfun(@(x) x+n_matrix,Rnn(k,l-1),'un',0);
        end
        
        Rnn_matrix = cell2mat(Rnn(k,l));
        
        % (2) CALCULATE A PRIORI RTF VECTOR (h_pr)                         
        e = eig(Rnn_matrix);
        
        h = e/([1,0]*e);
        
        h_pr(1,k) = h(1, 1);
        h_pr(2,k) = h(2, 1);
        
        % (3) BEAMFORMING - COMPUTE MVDR FILTER         
        mat_1 = (Rnn_matrix)*h_pr(:,k);
        mat_2 = ctranspose(h_pr(:,k))*(Rnn_matrix)*h_pr(:,k);
        mat_f = mat_1/mat_2;
        
        W_mvdr(1,k) = mat_f(1,1);
        W_mvdr(2,k) = mat_f(2,1);     
        
        % (4) BEAMFORMING - COMPUTE MWF FILTER  
         if(SPP_1(k,l) > SPP_thr)
            sigma_noise(k,l) = alpha_n*sigma_noise(k,l-1)+(1-alpha_n)*...
                STFT_signal_1(k,l)^2; 
            sigma_sound(k,l) = max(alpha_s*(...                          
                single_speech_stft(k,l-1))^2 +(1-alpha_s)*((...
                STFT_signal_1(k,l))^2-sigma_noise(k,l)^2), Xi_min*(...
                sigma_noise(k,l))^2);
        else
            sigma_noise(k,l) = alpha_n*sigma_noise(k,l-1)+(1-alpha_n)*...
                STFT_signal_1(k,l)^2;
            sigma_sound(k,l) = 0;
         end
         
        W_mc(1,k) = W_mvdr(1,k)*(sigma_sound(k,l)/(sigma_sound(k,l)+...
            1/mat_2));
        W_mc(2,k) = W_mvdr(2,k)*(sigma_sound(k,l)/(sigma_sound(k,l)+...
            1/mat_2));
        
        if(SPP_1(k,l) > SPP_thr)
            multiple_speech_stft(k,l) = ctranspose(W_mc(:,k))*n;
        elseif (SPP_1(k,l) < 0.6)
            multiple_speech_stft(k,l) = 0; 
        else
            multiple_speech_stft(k,l) = ctranspose(W_mvdr(:,k))*n;
        end
        
        % (5) SIGNLE CHANNEL ENHENCEMENT   
        single_gain_stft = (sigma_sound(k,l))/((sigma_sound(k,l))+...   
            (sigma_noise(k,l)));
        
        single_speech_stft(k,l) = single_gain_stft * ...
            multiple_speech_stft(k,l);                                      
                       
    end                                                                    
end                                                                     
toc

times_stft = ((1:L_time_frames));

time = 0:1/Fs:(length(STFT(:,1))-1)/Fs;
Single_speech_time_domain = calc_ISTFT(single_speech_stft, hann_window,...
    Number_of_fft,Number_of_fft/overlap_fft, 'onesided');

%LOW PASS

Single_speech_time_domain = lowpass(Single_speech_time_domain,16000,Fs);

    sound(Single_speech_time_domain, Fs, 16);
%sound(time_signal(:, 2), Fs, 16);

figure; 
imagesc(times_stft,frequencies,mag2db(abs(single_speech_stft(:,:))),...
    [-65, 10]); colorbar; 
axis xy; 
set(gcf,'color','w'); 
set(gca,'Fontsize',14);
xlabel('Time (s)'), ylabel('Frequency (Hz)'),...
    title('Single Channel Enhancement');

figure; 
imagesc(times_stft,frequencies,mag2db(abs(STFT_signal_1(:,:,1))), [-65, 10]); 
colorbar; 
axis xy; 
set(gcf,'color','w');
set(gca,'Fontsize',14); 
xlabel('Time (s)'), ylabel('Frequency (Hz)'), ...
    title('microphne signal, 1st mic : noisy');

figure; 
imagesc(times_stft,frequencies,mag2db(abs(STFT_signal_2(:,:,1))), [-65, 10]); 
colorbar; 
axis xy; 
set(gcf,'color','w');
set(gca,'Fontsize',14); 
xlabel('Time (s)'), ylabel('Frequency (Hz)'), ...
    title('microphne signal, 2st mic : noisy');

figure();
plot(Single_speech_time_domain(:,1));
xlabel('time');
ylabel('amplitude');
title('Amplitude - time of the sound');

%% CALCULATE THE SNR
plot(y_mic_1(:,1));noise=2806;
maxamplitude=max(y_mic_1(:,1));
signal=find(y_mic_1(:,1)==maxamplitude);

%calculate powers
Pn=mean(y_mic_1(noise:noise+1000,1).^2);
Ps=mean(y_mic_1(signal:signal+1000,1).^2);
SNR1=10*log10((Ps-Pn)/Pn);

plot(y_mic_2(:,1));noise=3300;
maxamplitude=max(y_mic_2(:,1));
signal=find(y_mic_2(:,1)==maxamplitude);

%calculate powers
Pn=mean(y_mic_2(noise:noise+1000,1).^2);
Ps=mean(y_mic_2(signal:signal+1000,1).^2);
SNR2=10*log10((Ps-Pn)/Pn);

plot(Single_speech_time_domain(:,1));noise=4900;
maxamplitude=max(Single_speech_time_domain(:,1));
signal=find(Single_speech_time_domain(:,1)==maxamplitude);

%calculate powers
Pn=mean(Single_speech_time_domain(noise:noise+1000,1).^2);
Ps=mean(Single_speech_time_domain(signal:signal+1000,1).^2);
SNR3=10*log10((Ps-Pn)/Pn);

%% SAVING
audiowrite('D:\School 2019-2020\SPAI\NoiseReduction\Single_speech_time_domain.wav',Single_speech_time_domain(:,1),Fs);
audiowrite('D:\School 2019-2020\SPAI\NoiseReduction\Original.wav',time_signal(:,1),Fs);
