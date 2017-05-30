close all;
clearvars;
clc
beep off;

addpath(genpath('FYP'));
addpath(genpath('voicebox'));

%% generate mask statistics on set of training files

Tw = 16e-3;         % frame duration in s  
Ts = 4e-3;          % frame shift in s (overlap)
LC = 0;             % LC for IBM (in dB)
noiselevel = -5;    % noise level (in dB)

[u_present, var_present, u_absent, var_absent] = getMaskStats(noiselevel, Tw, Ts, LC);

%% generate new test clean and noise signal

databases = '\\sapfs.ee.ic.ac.uk\Databases\';
timit = [databases 'Speech\TIMIT\TIMIT\TEST\'];
nato = [databases 'Noises\NatoNoise0\'];

% read in a speech file
[y_clean,fs,words,phonemes] = readsph([timit 'DR1\MREB0\SI1375.wav'],'wt');
% [y_clean,fs] = audioread('sp15.wav');

% downsample from 16 -> 8kHz
fs = fs/2;
y_clean = downsample(y_clean,2);

y_clean = activlev(y_clean,fs,'n');     % normalise active level to 0 dB

ns = length(y_clean);       % number of speech samples

noises = {'white'};
noiselevel = -5;      % if noiselevel = 5, target SNR is -5dB

% read in the noises
[vj,fsj] = readwav([nato noises{1}]);
vjr = resample(vj,fs,fsj);
v = vjr(1:ns)/std(vjr(1:ns));  % extract the initial chunck of noise and set to 0 dB; v is noise

y_babble = v_addnoise(y_clean,fs,-noiselevel,'nzZ',v); % add noise at chosen level keeping speech at 0 dB

%% spectrogram
m=4;
n=2;

mode='pJwiat';   % see spgrambw for list of modes
bw = [];
fmax = [];
dbrange = [-12 20];     % power in dB to plot on spectrogram
tinc = [];

p_MDKF = 2;
Tw_slow = 24e-3;     % window and shift for each KF (in seconds)
Ts_slow = 4e-3;
fs_slow = 1/Ts;

figure;

subplot(m,n,1);
spgrambw(y_clean, fs, mode, bw, fmax, dbrange, tinc, phonemes);
get(gca,'XTickLabel');
title('Spectrogram of clean speech');


subplot(m,n,2);
spgrambw(y_babble, fs, mode, bw, fmax, dbrange, tinc, phonemes);
get(gca,'XTickLabel');
title(['Speech corrupted with white Gaussian noise (' num2str(noiselevel) 'dB SNR)']);


subplot(m,n,3);
y_MDKF_IBM = MDKF_obsMask_all(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, u_present, var_present, u_absent, var_absent);
spgrambw(y_MDKF_IBM, fs, mode, bw, fmax, dbrange, tinc, phonemes);
title(['IBM-observation MDKF with p=' num2str(p_MDKF) ', LC=' num2str(LC) 'dB']);


subplot(m,n,4);
y_MDKF = idealMDKF_linear(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow);
spgrambw(y_MDKF, fs, mode, bw, fmax, dbrange, tinc, phonemes);
title(['Linear MDKF with p=' num2str(p_MDKF)]);


subplot(m,n,5);
y_MDKF_uncorr = uncorrelatedMDKF(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow); 
spgrambw(y_MDKF_uncorr, fs, mode, bw, fmax, dbrange, tinc, phonemes);
title(['uncorrelated MDKF with p=' num2str(p_MDKF)]);


subplot(m,n,6);
y_MDKF_uncorrIBM = uncorrelatedMDKF_IBM_all(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, u_present, var_present, u_absent, var_absent);
spgrambw(y_MDKF_uncorrIBM, fs, mode, bw, fmax, dbrange, tinc, phonemes);
title(['uncorrelated MDKF + IBM with p=' num2str(p_MDKF) ', LC=' num2str(LC) 'dB']);


subplot(m,n,7);
y_mmse = ssubmmse(y_babble, fs);
spgrambw(y_mmse, fs, mode, bw, fmax, dbrange, tinc, phonemes);
title('MMSE-enhanced speech');