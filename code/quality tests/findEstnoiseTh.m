close all;
clearvars;
clc
beep off;

addpath(genpath('FYP'));
addpath(genpath('voicebox'));
addpath(genpath('pesqSTOI'));

warning('off','all')
warning

%%
databases = '\\sapfs.ee.ic.ac.uk\Databases\';
timit = [databases 'Speech\TIMIT\TIMIT\TRAIN\'];
db = [timit 'DR1\'];
nato = [databases 'Noises\NatoNoise0\'];

folders = dir(db);

for k = length(folders):-1:1
    % remove non-folders
    if ~folders(k).isdir
        folders(k) = [ ];
        continue
    end

    % remove folders starting with .
    fname = folders(k).name;
    if fname(1) == '.'
        folders(k) = [ ];
    end
end

fileNames = {};
for i=1:length(folders)
    folder = folders(i).name;
    directory = [db folder];
    files = dir(fullfile(directory,'*.wav'));
    files = {files.name}';                      %'# file names

    data = cell(numel(files),1);                %# store file contents
    for j=1:numel(files)
        fname = fullfile(directory,files{j});     %# full path to file
        fileNames = [fileNames, fname];
    end
end

fileNames = datasample(fileNames,floor(length(fileNames)/12),'Replace',false);

%%
[clean,fs] = readsph(fileNames{1},'wt');

numFiles = length(fileNames)
noises = {'white'};

% read in the noises
[vj,fsj] = readwav([nato noises{1}]);
vjr = resample(vj,fs,fsj);

targetSNR = [-20 -15 -10 -5 0 5 10 15 20];
targetSNR = targetSNR';

numSNR = length(targetSNR);

pesqRatio_0pt7 = zeros(numSNR, numFiles);
pesqRatio_0pt8 = zeros(numSNR, numFiles);
pesqRatio_0pt9 = zeros(numSNR, numFiles);
pesqRatio_1pt0 = zeros(numSNR, numFiles);
pesqRatio_1pt1 = zeros(numSNR, numFiles);
pesqRatio_1pt2 = zeros(numSNR, numFiles);

stoiRatio_0pt7 = zeros(numSNR, numFiles);
stoiRatio_0pt8 = zeros(numSNR, numFiles);
stoiRatio_0pt9 = zeros(numSNR, numFiles);
stoiRatio_1pt0 = zeros(numSNR, numFiles);
stoiRatio_1pt1 = zeros(numSNR, numFiles);
stoiRatio_1pt2 = zeros(numSNR, numFiles);

segSNRratio_0pt7 = zeros(numSNR, numFiles);
segSNRratio_0pt8 = zeros(numSNR, numFiles);
segSNRratio_0pt9 = zeros(numSNR, numFiles);
segSNRratio_1pt0 = zeros(numSNR, numFiles);
segSNRratio_1pt1 = zeros(numSNR, numFiles);
segSNRratio_1pt2 = zeros(numSNR, numFiles);

Tw = 16e-3;         % frame duration in s  
Ts = 4e-3;          % frame shift in s (overlap)
LC = 0;             % LC for IBM (in dB)
p_MDKF = 2;
Tw_slow = 24e-3;     % window and shift for each KF (in seconds)
Ts_slow = 4e-3;
fs_slow = 1/Ts;

%%
for k = 1:numFiles
    % read in a speech file
    [clean,fs] = readsph(fileNames{k},'wt');

    clean = activlev(clean,fs,'n');     % normalise active level to 0 dB

    ns = length(clean);       % number of speech samples
    v = vjr(1:ns)/std(vjr(1:ns));  % extract the initial chunck of noise and set to 0 dB; v is noise

    for i = 1:length(targetSNR)
        noisy = v_addnoise(clean, fs, targetSNR(i), 'nzZ', v);  % add noise at chosen level keeping speech at 0 dB

        % linear MDKF
        y_MDKF = idealMDKF_linear(noisy, clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow);

        %% 0.7 threshold
        y_MDKF_estnoisemask = idealMDKF_noiseIBM(noisy, clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, 0.7);
        
        audiowrite('FYP\testfiles\clean.wav',clean,fs);
        audiowrite('FYP\testfiles\y_MDKF.wav',y_MDKF,fs);
        audiowrite('FYP\testfiles\y_MDKF_estnoisemask.wav',y_MDKF_estnoisemask,fs);
        pesqMDKF = pesqITU(fs,'FYP\testfiles\clean.wav','FYP\testfiles\y_MDKF.wav');
        pesqNoisemask = pesqITU(fs,'FYP\testfiles\clean.wav','FYP\testfiles\y_MDKF_estnoisemask.wav');
        pesqRatio_0pt7(i,k) = pesqNoisemask/pesqMDKF;

        cutoff = min([length(clean), length(y_MDKF), length(y_MDKF_estnoisemask)]);
        clean = clean(1:cutoff);
        y_MDKF = y_MDKF(1:cutoff);
        y_MDKF_estnoisemask = y_MDKF_estnoisemask(1:cutoff);
        segSNRMDKF = snrseg(y_MDKF, clean, fs);
        segSNRMDKFmask = snrseg(y_MDKF_estnoisemask, clean, fs);
        segSNRratio_0pt7(i,k) = segSNRMDKFmask/segSNRMDKF;

        stoiMDKF = stoi(clean,y_MDKF,fs);
        stoiNoisemask = stoi(clean,y_MDKF_estnoisemask,fs);
        stoiRatio_0pt7(i,k) = stoiNoisemask/stoiMDKF;
        
        %% 0.8 threshold
        y_MDKF_estnoisemask = idealMDKF_noiseIBM(noisy, clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, 0.8);
        
        audiowrite('FYP\testfiles\y_MDKF_estnoisemask.wav',y_MDKF_estnoisemask,fs);
        pesqNoisemask = pesqITU(fs,'FYP\testfiles\clean.wav','FYP\testfiles\y_MDKF_estnoisemask.wav');
        pesqRatio_0pt8(i,k) = pesqNoisemask/pesqMDKF;

        y_MDKF_estnoisemask = y_MDKF_estnoisemask(1:cutoff);
        segSNRMDKFmask = snrseg(y_MDKF_estnoisemask, clean, fs);
        segSNRratio_0pt8(i,k) = segSNRMDKFmask/segSNRMDKF;

        stoiNoisemask = stoi(clean,y_MDKF_estnoisemask,fs);
        stoiRatio_0pt8(i,k) = stoiNoisemask/stoiMDKF;
        
        %% 0.9 threshold
        y_MDKF_estnoisemask = idealMDKF_noiseIBM(noisy, clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, 0.9);
        
        audiowrite('FYP\testfiles\y_MDKF_estnoisemask.wav',y_MDKF_estnoisemask,fs);
        pesqNoisemask = pesqITU(fs,'FYP\testfiles\clean.wav','FYP\testfiles\y_MDKF_estnoisemask.wav');
        pesqRatio_0pt9(i,k) = pesqNoisemask/pesqMDKF;

        y_MDKF_estnoisemask = y_MDKF_estnoisemask(1:cutoff);
        segSNRMDKFmask = snrseg(y_MDKF_estnoisemask, clean, fs);
        segSNRratio_0pt9(i,k) = segSNRMDKFmask/segSNRMDKF;

        stoiNoisemask = stoi(clean,y_MDKF_estnoisemask,fs);
        stoiRatio_0pt9(i,k) = stoiNoisemask/stoiMDKF;
        
        %% 1.0 threshold
        y_MDKF_estnoisemask = idealMDKF_noiseIBM(noisy, clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, 1.0);
        
        audiowrite('FYP\testfiles\y_MDKF_estnoisemask.wav',y_MDKF_estnoisemask,fs);
        pesqNoisemask = pesqITU(fs,'FYP\testfiles\clean.wav','FYP\testfiles\y_MDKF_estnoisemask.wav');
        pesqRatio_1pt0(i,k) = pesqNoisemask/pesqMDKF;

        y_MDKF_estnoisemask = y_MDKF_estnoisemask(1:cutoff);
        segSNRMDKFmask = snrseg(y_MDKF_estnoisemask, clean, fs);
        segSNRratio_1pt0(i,k) = segSNRMDKFmask/segSNRMDKF;

        stoiNoisemask = stoi(clean,y_MDKF_estnoisemask,fs);
        stoiRatio_1pt0(i,k) = stoiNoisemask/stoiMDKF;  
        
        %% 1.1 threshold
        y_MDKF_estnoisemask = idealMDKF_noiseIBM(noisy, clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, 1.1);
        
        audiowrite('FYP\testfiles\y_MDKF_estnoisemask.wav',y_MDKF_estnoisemask,fs);
        pesqNoisemask = pesqITU(fs,'FYP\testfiles\clean.wav','FYP\testfiles\y_MDKF_estnoisemask.wav');
        pesqRatio_1pt1(i,k) = pesqNoisemask/pesqMDKF;

        y_MDKF_estnoisemask = y_MDKF_estnoisemask(1:cutoff);
        segSNRMDKFmask = snrseg(y_MDKF_estnoisemask, clean, fs);
        segSNRratio_1pt1(i,k) = segSNRMDKFmask/segSNRMDKF;

        stoiNoisemask = stoi(clean,y_MDKF_estnoisemask,fs);
        stoiRatio_1pt1(i,k) = stoiNoisemask/stoiMDKF;
        
        %% 1.2 threshold
        y_MDKF_estnoisemask = idealMDKF_noiseIBM(noisy, clean, fs, Tw, Ts, p_MDKF, Tw_slow, Ts_slow, fs_slow, LC, 1.2);
        
        audiowrite('FYP\testfiles\y_MDKF_estnoisemask.wav',y_MDKF_estnoisemask,fs);
        pesqNoisemask = pesqITU(fs,'FYP\testfiles\clean.wav','FYP\testfiles\y_MDKF_estnoisemask.wav');
        pesqRatio_1pt2(i,k) = pesqNoisemask/pesqMDKF;

        y_MDKF_estnoisemask = y_MDKF_estnoisemask(1:cutoff);
        segSNRMDKFmask = snrseg(y_MDKF_estnoisemask, clean, fs);
        segSNRratio_1pt2(i,k) = segSNRMDKFmask/segSNRMDKF;

        stoiNoisemask = stoi(clean,y_MDKF_estnoisemask,fs);
        stoiRatio_1pt2(i,k) = stoiNoisemask/stoiMDKF;
        
        %%
%         [pesqRatio_0pt7(i,k), stoiRatio_0pt7(i,k), segSNRratio_0pt7(i,k)] = runEstnoiseAll(clean, noisy, fs, 0.7);
%         [pesqRatio_0pt8(i,k), stoiRatio_0pt8(i,k), segSNRratio_0pt8(i,k)] = runEstnoiseAll(clean, noisy, fs, 0.8);
%         [pesqRatio_0pt9(i,k), stoiRatio_0pt9(i,k), segSNRratio_0pt9(i,k)] = runEstnoiseAll(clean, noisy, fs, 0.9);
%         [pesqRatio_1pt0(i,k), stoiRatio_1pt0(i,k), segSNRratio_1pt0(i,k)] = runEstnoiseAll(clean, noisy, fs, 1.0);
%         [pesqRatio_1pt1(i,k), stoiRatio_1pt1(i,k), segSNRratio_1pt1(i,k)] = runEstnoiseAll(clean, noisy, fs, 1.1);
%         [pesqRatio_1pt2(i,k), stoiRatio_1pt2(i,k), segSNRratio_1pt2(i,k)] = runEstnoiseAll(clean, noisy, fs, 1.2);
    end
    k
end

%%

save('snrStats_estnoise','segSNRratio_0pt7','segSNRratio_0pt8','segSNRratio_0pt9','segSNRratio_1pt0','segSNRratio_1pt1','segSNRratio_1pt2');
save('pesqStats_estnoise','pesqRatio_0pt7','pesqRatio_0pt8','pesqRatio_0pt9','pesqRatio_1pt0','pesqRatio_1pt1','pesqRatio_1pt2');
save('stoiStats_estnoise','stoiRatio_0pt7','stoiRatio_0pt8','stoiRatio_0pt9','stoiRatio_1pt0','stoiRatio_1pt1','stoiRatio_1pt2');
