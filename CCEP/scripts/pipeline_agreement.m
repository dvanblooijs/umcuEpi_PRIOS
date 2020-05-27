clear; 

%% Choose patient
config_CCEP

%% set paths
myDataPath = setLocalDataPath(cfg);

%% select run
% choose between available runs
files = dir(fullfile(myDataPath.dataPath,cfg.sub_labels{1}, cfg.ses_label,'ieeg',...
    [cfg.sub_labels{1} '_' cfg.ses_label '_' cfg.task_label '_*'  '_events.tsv']));
names = {files.name};
strings = cellfun(@(x) x(strfind(names{1},'run-'):strfind(names{1},'run-')+9), names, 'UniformOutput', false);
stringsz = [repmat('%s, ',1,size(strings,2)-1),'%s'];

cfg.run_label = {input(sprintf(['Choose one of these runs: \n' stringsz '\n'],strings{:}),'s')}; % Chosen run is in cfg.run_label

if ~contains(cfg.run_label,'run-')
   error('"run-" is missing in run_label') 
end

clear files names strings stringsz

%% load data

dataBase = load_ECoGdata(cfg,myDataPath);

%% CCEP for 2 and 10 stimulations

% avg_stim = 1: we only want to use the first stimulation of all stimuli 
% in one stimulation pair. So instead of averaging all stimuli in one 
% stimulation pair, we only 'average' the first stimulus. If you want to 
% use all stimuli, use avg_stim = [];

% save only first stimulus in both directions
avg_stim = 1;
dataBase2stim = preprocess_ECoG_spes(dataBase,cfg,avg_stim);

% save all stimuli
avg_stim = [];
dataBaseallstim = preprocess_ECoG_spes(dataBase,cfg,avg_stim);

% detect ccep in only first stimulus in both directions and all stimuli
dataBase2stim = detect_n1peak_ECoG_ccep(dataBase2stim,cfg);
dataBaseallstim = detect_n1peak_ECoG_ccep(dataBaseallstim,cfg);

disp('Detection of ERs is completed')

%% save ccep
targetFolder = [fullfile(myDataPath.CCEPpath, dataBase(1).sub_label,dataBase(1).ses_label,dataBase(1).run_label),'/'];

% Create the folder if it doesn't exist already.
if ~exist(targetFolder, 'dir')
    mkdir(targetFolder);
end

start_filename = strfind(dataBase(1).dataName,'/');
stop_filename = strfind(dataBase(1).dataName,'_ieeg');

% save 2 stims
fileName=[dataBase2stim.dataName(start_filename(end)+1:stop_filename-1),'_CCEP_2stims.mat'];
ccep = dataBase2stim.ccep;
ccep.stimchans = dataBase2stim.cc_stimchans;
ccep.stimpnames = dataBase2stim.stimpnames;
ccep.dataName = dataBase2stim.dataName;
ccep.ch = dataBase2stim.ch;
save([targetFolder,fileName], 'ccep');

% save all stims
fileName5=[dataBaseallstim.dataName(start_filename(end)+1:stop_filename-1),'_CCEP_10stims.mat'];
ccep = dataBaseallstim.ccep;
ccep.stimchans = dataBaseallstim.cc_stimchans;
ccep.stimpnames = dataBaseallstim.stimpnames;
ccep.dataName = dataBaseallstim.dataName;
ccep.ch = dataBaseallstim.ch;
save([targetFolder,fileName5], 'ccep');

fprintf('CCEPs 2stims and 10stims is saved in %s \n',targetFolder);

%% determine the agreement between 2 and 10 stims per run
% The determine_agreement function is not only determining the agreement
% when 2 sessions are compared. It could be possible to compare more, but
% then the values for W, Z and XandY should be changed. 
clc
close all

[agreement_run, agreement_stim,compare_mat] = determine_agreement(myDataPath,cfg);

fprintf('Overall agreement = %1.2f, positive agreement = %1.2f, negative agreement = %1.2f \n',...
    agreement_run.OA, agreement_run.PA, agreement_run.NA)

fprintf('Overall agreement = %1.2f, positive agreement = %1.2f, negative agreement = %1.2f \n',...
    agreement_stim.OA, agreement_stim.PA, agreement_stim.NA)

%% Save the values for the agreement per run (2 and 10 stims)
targetFolder = [myDataPath.CCEPpath, dataBase(1).sub_label,'/',dataBase(1).ses_label,'/', dataBase(1).run_label,'/'];

% Create the folder if it doesn't exist already.
if ~exist(targetFolder, 'dir')
    mkdir(targetFolder);
end

Agreements = [dataBase(1).sub_label, '_', dataBase(1).run_label,'_agreement2_versus10.mat'];

save([targetFolder,Agreements], 'agreement_run','agreement_stim');

fprintf('Agreements are saved in %s \n',targetFolder);

