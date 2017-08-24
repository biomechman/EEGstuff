clear all; 
eeglab;

dataPath = '/home/biomechman/Documents/data/P22_S2_JessicaJones_Block.edf'; % To the data files.
channelPath = '/home/biomechman/Documents/MATLAB/eeglab14_1_1b/64cap.ced'; % To EEG cap configuratin file.
channels = {'FP1' 'FP2' 'F7' 'F3' 'FZ' 'F4' 'F8' 'C3' 'CZ' 'C4' 'P3' 'P4' 'O1' 'O2'}; % Channels used.

% Load and process data set
EEG = pop_biosig(dataPath, 'importevent','off','importannot','off');
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
EEG = eeg_checkset(pop_eegfiltnew(eeg_checkset(eeg_regepochs(eeg_checkset(EEG))), 4, 35, 1650, 0, [], 0));
EEG = pop_chanedit(EEG, 'lookup',channelPath);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = eeg_checkset(pop_reref(pop_select(eeg_checkset(EEG),'channel',channels), []));
data = EEG.data;

for i = 1:length(data(1,1,:))
    [spectra,freqs,speccomp,contrib,specstd] = spectopo(data(:,:,i), 0, 1000, 'freqrange',[4 35], 'plot', 'off');
    PowerSpec(:,:,i) = spectra; % Power Spectrum - PowerSpec(power at index channel,frequency,epoch)
end

for i = 1:length(PowerSpec(1,1,:))
    for j = 1:length(PowerSpec(:,1,1))
        Alpha(j,i) = mean(PowerSpec(j,9:13,i),2); % Band(channel,epochAvg) - e.g.: Alpha(j,i)
        Beta(j,i) = mean(PowerSpec(j,16:31,i),2);
        Theta(j,i) = mean(PowerSpec(j,7:9,i),2);
        Delta(j,i) = mean(PowerSpec(j,2:5,i),2);
    end
end

EngChan = [4, 6, 3, 7]; % Channels used for Engagement, in their proper order. {'FP1' 'FP2' 'F7' 'F3' 'FZ' 'F4' 'F8' 'C3' 'CZ' 'C4' 'P3' 'P4' 'O1' 'O2'}
AsymChan = [8, 9, 10, 4, 6, 3, 7, 1, 2, 5, 13, 14, 11, 12]; % Channels used for Asymmetry, in their proper order.

fprintf('Creating data matrices.\n')

Engagement(:,1:4) = Alpha(EngChan,:)';
Engagement(:,5:8) = Beta(EngChan,:)';
Engagement(:,9:12) = Theta(EngChan,:)';

Asymmetry(:,1:14) = Alpha(AsymChan,:)';
Asymmetry(:,15:28) = Beta(AsymChan,:)';
Asymmetry(:,29:42) = Theta(AsymChan,:)';
Asymmetry(:,43:56) = Delta(AsymChan,:)';


xlswrite('/home/biomechman/Documents/data/test.xls',Engagement,1,'Z4') 