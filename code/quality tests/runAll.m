function [SNRMDKFmask, SNRLPCmask, SNRNoisemask, SNRMDKF, SNRmmse, SNRbabble, ...
    pesqMDKFmask, pesqLPCmask, pesqNoisemask, pesqMDKF, pesqMMSE, pesqNoisy, ...
    stoiMDKFmask, stoiLPCmask, stoiNoisemask, stoiMDKF, stoiMMSE, stoiNoisy] = runAll(y_clean, y_babble, fs)

load 'maskstats';

Tw = 16e-3;         % frame duration in s  
Ts = 4e-3;          % frame shift in s (overlap)
LC = 0;             % LC for IBM (in dB)
p_MDKF = 2;
% Tw_slow = 24e-3;     % window and shift for each KF (in seconds)
% Ts_slow = 4e-3;
Tw_slow = 16e-3;     % window and shift for each KF (in seconds)
Ts_slow = 4e-3;
fs_slow = 1/Ts;

maskth = 0.15;

maskth_noise = 1.0;

% MMSE-enhanced
y_mmse = ssubmmse(y_babble, fs);

%%
% % MMSE-enhanced LPCs
% % linear MDKF
% y_MDKF = idealMDKF_linear(y_mmse, y_mmse, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow);
% 
% % uncorrelated MDKF with IBM applied in KF equations
% y_MDKF_uncorrIBM = uncorrelatedMDKF_IBM_all(y_mmse, y_mmse, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, u_present, var_present, u_absent, var_absent);
% 
% % mask-enhanced LPCs
% y_maskLPC = MDKFmaskLPC(y_mmse, y_mmse, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, maskth);
% 
% % mask-enhanced noise estimation
% y_MDKF_IBMnoise = idealMDKF_noiseIBM(y_mmse, y_mmse, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, maskth_noise);

%%
% clean LPCs
% linear MDKF
y_MDKF = idealMDKF_linear(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow);

% uncorrelated MDKF with IBM applied in KF equations
y_MDKF_uncorrIBM = uncorrelatedMDKF_IBM_all(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, u_present, var_present, u_absent, var_absent);

% mask-enhanced LPCs
y_maskLPC = MDKFmaskLPC(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, maskth);

% mask-enhanced noise estimation
y_MDKF_IBMnoise = idealMDKF_noiseIBM(y_babble, y_clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, maskth_noise);

%% PESQ
audiowrite('FYP\testfiles\y_clean.wav',y_clean,fs);
audiowrite('FYP\testfiles\y_babble.wav',y_babble,fs);
audiowrite('FYP\testfiles\y_MDKF.wav',y_MDKF,fs);
audiowrite('FYP\testfiles\y_MDKF_uncorrIBM.wav',y_MDKF_uncorrIBM,fs);
audiowrite('FYP\testfiles\y_maskLPC.wav',y_maskLPC,fs);
audiowrite('FYP\testfiles\y_MDKF_IBMnoise.wav',y_MDKF_IBMnoise,fs);
audiowrite('FYP\testfiles\y_mmse.wav',y_mmse,fs);

pesqNoisy = pesqITU(fs,'FYP\testfiles\y_clean.wav','FYP\testfiles\y_babble.wav');
pesqMDKF = pesqITU(fs,'FYP\testfiles\y_clean.wav','FYP\testfiles\y_MDKF.wav');
pesqMDKFmask = pesqITU(fs,'FYP\testfiles\y_clean.wav','FYP\testfiles\y_MDKF_uncorrIBM.wav');
pesqLPCmask = pesqITU(fs,'FYP\testfiles\y_clean.wav','FYP\testfiles\y_maskLPC.wav');
pesqNoisemask = pesqITU(fs,'FYP\testfiles\y_clean.wav','FYP\testfiles\y_MDKF_IBMnoise.wav');
pesqMMSE = pesqITU(fs,'FYP\testfiles\y_clean.wav','FYP\testfiles\y_mmse.wav');

%% segSNR
cutoff = min([length(y_clean), length(y_MDKF), length(y_MDKF_uncorrIBM)]);

y_clean = y_clean(1:cutoff);
y_babble = y_babble(1:cutoff);
y_MDKF = y_MDKF(1:cutoff);
y_MDKF_uncorrIBM = y_MDKF_uncorrIBM(1:cutoff);
y_maskLPC = y_maskLPC(1:cutoff);
y_MDKF_IBMnoise = y_MDKF_IBMnoise(1:cutoff);
y_mmse = y_mmse(1:cutoff);

SNRbabble = snrseg(y_babble, y_clean, fs);
SNRMDKF = snrseg(y_MDKF, y_clean, fs);
SNRMDKFmask = snrseg(y_MDKF_uncorrIBM, y_clean, fs);
SNRLPCmask = snrseg(y_maskLPC, y_clean, fs);
SNRNoisemask = snrseg(y_MDKF_IBMnoise, y_clean, fs);
SNRmmse = snrseg(y_mmse, y_clean, fs);

%% STOI
stoiNoisy = stoi(y_clean,y_babble,fs);
stoiMDKF = stoi(y_clean,y_MDKF,fs);
stoiLPCmask = stoi(y_clean,y_maskLPC,fs);
stoiMDKFmask = stoi(y_clean,y_MDKF_uncorrIBM,fs);
stoiNoisemask = stoi(y_clean,y_MDKF_IBMnoise,fs);
stoiMMSE = stoi(y_clean,y_mmse,fs);

end