clear all; 
eeglab;

dataPath = pwd; % To the data files.
channelPath = strcat(uigetdir('Choose the directory cotaining EEG cap config file'), '/64cap.ced'); % To EEG cap configuratin file.
channels = {'FP1' 'FP2' 'F7' 'F3' 'FZ' 'F4' 'F8' 'C3' 'CZ' 'C4' 'P3' 'P4' 'O1' 'O2'}; % Channels used.

files = dir('*.edf'); % Loads all .edf data files.
typeCond = {'Baseline' 'JessicaJones' 'KillerWomen'}; % Dictionary with the condition type.
exceptions = {'P25_S1' 'P13_S2' 'P05_S2'}; % List of Patient & Session names (P##_S#) that should be skipped. Must be populated by hand.

% If you have file exceptions, skip the FOR loop and name the file
% manualy. Everything else remains the same. Comment out the fileName = ...
% below when not using it!

% fileName = 'P02_S2_JessicaJones_Block.edf';

for file = files'
    fileName = file.name;
    if any(ismember(exceptions,fileName(1:6))) == 1 % If file name is an exception, skips to next file.
        continue
    end
    
    condition = strtok(fileName(8:end),'_'); % Finds out which condition we are working witgh.
    filePath = strcat(dataPath,'/',fileName); % NOTE: filePath is a CELL. Need to convert to character later using char(). ALSO, use '\' for Windows and '/' for OS/Linux.
    fprintf(strcat('\n',string(filePath),'\n\n'))
    
    % Load and process data set
    EEG = pop_biosig(char(filePath), 'importevent','off','importannot','off');
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
    EEG = eeg_checkset(pop_eegfiltnew(eeg_checkset(eeg_regepochs(eeg_checkset(EEG))), 4, 35, 1650, 0, [], 0));
    EEG = pop_chanedit(EEG, 'lookup',char(channelPath));
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset(pop_reref(pop_select(eeg_checkset(EEG),'channel',channels), []));
    data = EEG.data;
    
    for i = 1:length(data(1,1,:))
        [spectra,freqs,speccomp,contrib,specstd] = spectopo(data(:,:,i), 0, EEG.srate, 'freqrange',[4 35], 'plot', 'off');
        PowerSpec(:,:,i) = 10.^(spectra/10); % Power Spectrum - PowerSpec(power at index channel,frequency,epoch)
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
    
    if condition == string(typeCond(1)) % save Baseline data. Careful here! Baseline must come first and will be assigned to the following condition.
        baseline = Engagement;
        clear Engagement
        clear Asymmetry
    elseif condition == string(typeCond(2)) % Write to Jessica Jones .xls file.
        writePath = strcat(dataPath,'/',fileName(1:6),'_JJ_Engagement.xlsx');
        xlswrite(writePath,baseline,1,'K4');
        xlswrite(writePath,Engagement,1,'Z4');
        clear Engagement
        clear Asymmetry
    elseif condition == string(typeCond(3)) % Write to Killer Women .xls file.
        writePath = strcat(dataPath,'/',fileName(1:6),'_KW_Engagement.xlsx');
        xlswrite(writePath,baseline,1,'K4');
        xlswrite(writePath,Engagement,1,'Z4');
        clear Engagement
        clear Asymmetry
    end
end
 
fprintf('░░░░░░░░░░░░░░▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄░░░░░░░░░░░░░░\n')
fprintf('░░░░░░░▄▄▄▄█▀▀▀░░░░░░░░░░░░▀▀██░░░░░░░░░░░░\n')
fprintf('░░░░▄███▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█▄▄▄░░░░░░░░\n')
fprintf('░░▄▀▀░█░░░░▀█▄▀▄▀██████░▀█▄▀▄▀████▀░░░░░░░░\n')
fprintf('░░█░░░█░░░░░░▀█▄█▄███▀░░░░▀▀▀▀▀▀▀░▀▀▄░░░░░░\n')
fprintf('░░█░░░█░▄▄▄░░░░░░░░░░░░░░░░░░░░░▀▀░░░█░░░░░\n')
fprintf('░░█░░░▀█░░█░░░░▄░░░░▄░░░░░▀███▀░░░░░░░█░░░░\n')
fprintf('░░█░░░░█░░▀▄░░░░░░▄░░░░░░░░░█░░░░░░░░█▀▄░░░\n')
fprintf('░░░▀▄▄▀░░░░░▀▀▄▄▄░░░░░░░▄▄▄▀░▀▄▄▄▄▄▀▀░░█░░░\n')
fprintf('░░░█▄░░░░░░░░░░░░▀▀▀▀▀▀▀░░░░░░░░░░░░░░█░░░░\n')
fprintf('░░░░█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄██░░░░░\n')
fprintf('░░░░▀█▄░░░░░░░░░░░░░░░░░░░░░░░░░▄▀▀░░░▀█░░░\n')
fprintf('█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█\n')
fprintf('█░█▀▄ █▀▀ █▀█ █░░░░█░▄░█ █ ▀█▀ █░█░░█ ▀█▀░█\n')
fprintf('█░█░█ █▀▀ █▀█ █░░░░▀▄▀▄▀ █ ░█░ █▀█░░█ ░█░░█\n')
fprintf('█░▀▀░ ▀▀▀ ▀░▀ ▀▀▀░░░▀░▀░ ▀ ░▀░ ▀░▀░░▀ ░▀░░█\n')
fprintf('▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀\n')
