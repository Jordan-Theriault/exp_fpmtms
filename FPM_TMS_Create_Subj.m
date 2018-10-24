function FPM_TMS_Create_Subj(subjNum)
rng('shuffle')
addpath(genpath(cd))

%% Parameters
rootdir = '~/Desktop/FPM_TMS/experiment';
behavdir = fullfile(rootdir, 'behavioral');
stimdir = fullfile(rootdir, 'stimuli');
factdir = fullfile(rootdir, 'stim_facts');

param.stim_num = 184; % Final value should be 184.
param.fact_num = 2; % two facts to begin each session.


%% Get Stimuli

stim.stim_text = cell(param.stim_num,1);
stim.file = cell(param.stim_num,1);
stim.stim_id = cell(param.stim_num,1);
stim.stim_pair = cell(param.stim_num,1);
stim.mrl_prf = cell(param.stim_num,1);
stim.pos_no_con = cell(param.stim_num,1);
temp.data_start = 1;

%% Get facts
stim.fstim_text = cell(param.fact_num,1);
stim.fstim_id = cell(param.fact_num,1);
stim.ffile = cell(param.fact_num,1);

cd (factdir)
temp.files = [dir('*ProConFact.txt')];
temp.text = cell(numel(temp.files),1);
for xx=1:numel(temp.files)
    temp.data = fopen(temp.files(xx).name, 'r');
    temp.text{xx} = fgetl(temp.data);
    fclose('all');
end
stim.ffile(1:param.fact_num) = fullfile(factdir, {temp.files.name}');
stim.fstim_text(1:param.fact_num) = temp.text;
temp.names = char({temp.files.name}');
stim.fstim_id(1:param.fact_num) = cellstr(temp.names(:,5:7));

%% get remaining stimuli.
cd (stimdir);
% no consensus morals.
temp.files = [dir('*NoConMoral.txt')];
temp.text = cell(numel(temp.files),1);
for xx=1:numel(temp.files)
    temp.data = fopen(temp.files(xx).name, 'r');
    temp.text{xx} = fgetl(temp.data);
    fclose('all');
end
temp.data_end = temp.data_start + numel(temp.text)-1;
stim.file(temp.data_start:temp.data_end) = fullfile(stimdir, {temp.files.name}');
stim.stim_text(temp.data_start:temp.data_end) = temp.text;
temp.names = char({temp.files.name}');
stim.stim_id(temp.data_start:temp.data_end) = cellstr(temp.names(:,5:7));
stim.stim_pair(temp.data_start:temp.data_end) = cellstr(temp.names(:,13:15));
stim.mrl_prf(temp.data_start:temp.data_end) = {'mrl'};
stim.pos_no_con(temp.data_start:temp.data_end) = {'nocon'};
temp.data_start = temp.data_end+1;

% no consensus preferences.
temp.files = [dir('*NoConPreference.txt')];
temp.text = cell(numel(temp.files),1);
for xx=1:numel(temp.files)
    temp.data = fopen(temp.files(xx).name, 'r');
    temp.text{xx} = fgetl(temp.data);
    fclose('all');
end
temp.data_end = temp.data_start + numel(temp.text)-1;
stim.file(temp.data_start:temp.data_end) = fullfile(stimdir, {temp.files.name}');
stim.stim_text(temp.data_start:temp.data_end) = temp.text;
temp.names = char({temp.files.name}');
stim.stim_id(temp.data_start:temp.data_end) = cellstr(temp.names(:,5:7));
stim.stim_pair(temp.data_start:temp.data_end) = cellstr(temp.names(:,13:15));
stim.mrl_prf(temp.data_start:temp.data_end) = {'prf'};
stim.pos_no_con(temp.data_start:temp.data_end) = {'nocon'};
temp.data_start = temp.data_end+1;

% positive consensus morals.
temp.files = [dir('*ProConMoral.txt')];
temp.text = cell(numel(temp.files),1);
for xx=1:numel(temp.files)
    temp.data = fopen(temp.files(xx).name, 'r');
    temp.text{xx} = fgetl(temp.data);
    fclose('all');
end
temp.data_end = temp.data_start + numel(temp.text)-1;
stim.file(temp.data_start:temp.data_end) = fullfile(stimdir, {temp.files.name}');
stim.stim_text(temp.data_start:temp.data_end) = temp.text;
temp.names = char({temp.files.name}');
stim.stim_id(temp.data_start:temp.data_end) = cellstr(temp.names(:,5:7));
stim.stim_pair(temp.data_start:temp.data_end) = cellstr(temp.names(:,13:15));
stim.mrl_prf(temp.data_start:temp.data_end) = {'mrl'};
stim.pos_no_con(temp.data_start:temp.data_end) = {'poscon'};
temp.data_start = temp.data_end+1;

% positive consensus preferences.
temp.files = [dir('*ProConPreference.txt')];
temp.text = cell(numel(temp.files),1);
for xx=1:numel(temp.files)
    temp.data = fopen(temp.files(xx).name, 'r');
    temp.text{xx} = fgetl(temp.data);
    fclose('all');
end
temp.data_end = temp.data_start + numel(temp.text)-1;
stim.file(temp.data_start:temp.data_end) = fullfile(stimdir, {temp.files.name}');
stim.stim_text(temp.data_start:temp.data_end) = temp.text;
temp.names = char({temp.files.name}');
stim.stim_id(temp.data_start:temp.data_end) = cellstr(temp.names(:,5:7));
stim.stim_pair(temp.data_start:temp.data_end) = cellstr(temp.names(:,13:15));
stim.mrl_prf(temp.data_start:temp.data_end) = {'prf'};
stim.pos_no_con(temp.data_start:temp.data_end) = {'poscon'};

clear temp

%% Randomize Stimuli.
design.stim_text = cell(param.stim_num/2+param.fact_num,2);
design.file = cell(param.stim_num/2+param.fact_num,2);
design.stim_id = cell(param.stim_num/2+param.fact_num,2);
design.stim_pair = cell(param.stim_num/2+param.fact_num,2);
design.mrl_prf = cell(param.stim_num/2+param.fact_num,2);
design.pos_no_con = cell(param.stim_num/2+param.fact_num,2);


% get locations of all categories.
temp.mrl_nocon_loc = intersect(find(ismember(stim.mrl_prf, 'mrl')), ...
    find(ismember(stim.pos_no_con, 'nocon')));
temp.prf_nocon_loc = intersect(find(ismember(stim.mrl_prf, 'prf')), ...
    find(ismember(stim.pos_no_con, 'nocon')));
temp.mrl_poscon_loc = intersect(find(ismember(stim.mrl_prf, 'mrl')), ...
    find(ismember(stim.pos_no_con, 'poscon')));
temp.prf_poscon_loc = intersect(find(ismember(stim.mrl_prf, 'prf')), ...
    find(ismember(stim.pos_no_con, 'poscon')));

temp.data_start = 3;

if mod(subjNum, 2) % if subjNum is odd, randomize order.
    % Facts
    design.stim_text(1:param.fact_num, 1:2) = repmat(stim.fstim_text(:), 1, 2);
    design.file(1:param.fact_num, 1:2) = repmat(stim.ffile(:), 1, 2);
    design.stim_id(1:param.fact_num, 1:2) = repmat(stim.fstim_id(:), 1, 2);
    design.stim_pair(1:param.fact_num, 1:2) = {'000'};
    design.mrl_prf(1:param.fact_num, 1:2) = {'fact'};
    design.pos_no_con(1:param.fact_num, 1:2) = {'fact'};
    
    % No consensus morals
    temp.target_data = temp.mrl_nocon_loc;
    temp.stim_text = stim.stim_text(temp.target_data);
    temp.file = stim.file(temp.target_data);
    temp.stim_id = stim.stim_id(temp.target_data);
    temp.stim_pair = stim.stim_pair(temp.target_data);
    temp.mrl_prf = stim.mrl_prf(temp.target_data);
    temp.pos_no_con = stim.pos_no_con(temp.target_data);
    temp.seed = randperm(size(temp.target_data,1));
    temp.data_end = temp.data_start + numel(temp.seed)/2 - 1;
    % data arranged into two columns, each column is a TMS session.
    design.stim_text(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_text(temp.seed), [numel(temp.seed)/2, 2]);
    design.file(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.file(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_id(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_id(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_pair(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_pair(temp.seed), [numel(temp.seed)/2, 2]);
    design.mrl_prf(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.mrl_prf(temp.seed), [numel(temp.seed)/2, 2]);
    design.pos_no_con(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.pos_no_con(temp.seed), [numel(temp.seed)/2, 2]);
    temp.data_start = temp.data_end + 1;
    
    % No consensus preferences
    temp.target_data = temp.prf_nocon_loc;
    temp.stim_text = stim.stim_text(temp.target_data);
    temp.file = stim.file(temp.target_data);
    temp.stim_id = stim.stim_id(temp.target_data);
    temp.stim_pair = stim.stim_pair(temp.target_data);
    temp.mrl_prf = stim.mrl_prf(temp.target_data);
    temp.pos_no_con = stim.pos_no_con(temp.target_data);
    temp.seed = randperm(size(temp.target_data,1));
    temp.data_end = temp.data_start + numel(temp.seed)/2 - 1;
    
    design.stim_text(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_text(temp.seed), [numel(temp.seed)/2, 2]);
    design.file(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.file(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_id(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_id(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_pair(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_pair(temp.seed), [numel(temp.seed)/2, 2]);
    design.mrl_prf(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.mrl_prf(temp.seed), [numel(temp.seed)/2, 2]);
    design.pos_no_con(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.pos_no_con(temp.seed), [numel(temp.seed)/2, 2]);
    temp.data_start = temp.data_end + 1;
    
    % Positive consensus morals
    temp.target_data = temp.mrl_poscon_loc;
    temp.stim_text = stim.stim_text(temp.target_data);
    temp.file = stim.file(temp.target_data);
    temp.stim_id = stim.stim_id(temp.target_data);
    temp.stim_pair = stim.stim_pair(temp.target_data);
    temp.mrl_prf = stim.mrl_prf(temp.target_data);
    temp.pos_no_con = stim.pos_no_con(temp.target_data);
    temp.seed = randperm(size(temp.target_data,1));
    temp.data_end = temp.data_start + numel(temp.seed)/2 - 1;
    
    design.stim_text(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_text(temp.seed), [numel(temp.seed)/2, 2]);
    design.file(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.file(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_id(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_id(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_pair(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_pair(temp.seed), [numel(temp.seed)/2, 2]);
    design.mrl_prf(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.mrl_prf(temp.seed), [numel(temp.seed)/2, 2]);
    design.pos_no_con(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.pos_no_con(temp.seed), [numel(temp.seed)/2, 2]);
    temp.data_start = temp.data_end + 1;
    
    % Positive consensus preferences
    temp.target_data = temp.prf_poscon_loc;
    temp.stim_text = stim.stim_text(temp.target_data);
    temp.file = stim.file(temp.target_data);
    temp.stim_id = stim.stim_id(temp.target_data);
    temp.stim_pair = stim.stim_pair(temp.target_data);
    temp.mrl_prf = stim.mrl_prf(temp.target_data);
    temp.pos_no_con = stim.pos_no_con(temp.target_data);
    temp.seed = randperm(size(temp.target_data,1));
    temp.data_end = temp.data_start + numel(temp.seed)/2 - 1;
    
    design.stim_text(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_text(temp.seed), [numel(temp.seed)/2, 2]);
    design.file(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.file(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_id(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_id(temp.seed), [numel(temp.seed)/2, 2]);
    design.stim_pair(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.stim_pair(temp.seed), [numel(temp.seed)/2, 2]);
    design.mrl_prf(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.mrl_prf(temp.seed), [numel(temp.seed)/2, 2]);
    design.pos_no_con(temp.data_start:temp.data_end,1:2) = ...
        reshape(temp.pos_no_con(temp.seed), [numel(temp.seed)/2, 2]);
    temp.data_start = temp.data_end + 1;
    
    % Now shuffle everything within each TMS session.
    temp.targ = [param.fact_num+1:length(design.stim_text)]';
    temp.seed = randperm(param.stim_num/2)+2;
    design.stim_text(temp.targ,1) = design.stim_text(temp.seed,1);
    design.stim_id(temp.targ,1) = design.stim_id(temp.seed,1);
    design.stim_pair(temp.targ,1) = design.stim_pair(temp.seed,1);
    design.mrl_prf(temp.targ,1) = design.mrl_prf(temp.seed,1);
    design.pos_no_con(temp.targ,1) = design.pos_no_con(temp.seed,1);
    % session 2
    temp.seed = randperm(param.stim_num/2)+2;
    design.stim_text(temp.targ,2) = design.stim_text(temp.seed,2);
    design.stim_id(temp.targ,2) = design.stim_id(temp.seed,2);
    design.stim_pair(temp.targ,1) = design.stim_pair(temp.seed,1);
    design.mrl_prf(temp.targ,2) = design.mrl_prf(temp.seed,2);
    design.pos_no_con(temp.targ,2) = design.pos_no_con(temp.seed,2);
    
else % if subjNum is even, grab previous subject's data.
    cd (behavdir);
    temp.prev_subj = dir(['design_sub-' num2str(subjNum-1) '*']);
    assert(numel(temp.prev_subj) == 1, 'multiple (or zero) files returned for subjNum - 1.');
    load(temp.prev_subj.name)
    
    % Flip the design from the previous person. 
    % NOTE - no longer doing this.
%     design.stim_text = fliplr(design.stim_text);
%     design.file = fliplr(design.file);
%     design.stim_id = fliplr(design.stim_id);
%     design.stim_pair = fliplr(design.stim_pair);
%     design.mrl_prf = fliplr(design.mrl_prf);
%     design.pos_no_con = fliplr(design.pos_no_con);
    
end

clear temp

%% Question Order
design.q_order = cell(3,1);
design.q_text = cell(3,1);
design.q_order(:) = {'abt_fact', 'abt_morl', 'abt_pref'};
design.q_text(:) = {'About Facts', 'About Morality', 'About Preferences'};
seed = randperm(size(design.q_order,1));
design.q_order = design.q_order(seed);
design.q_text = design.q_text(seed);

%% Save Behavioral File
cd (behavdir)
subjID = subjNum;
param.time_date = datestr(now, 'mm-dd-yyyy_HH-MM');
assert(isempty(dir(['design_sub-' num2str(subjNum) '*'])), 'Subject already exists. Check /behavioral')
save(['design_sub-' num2str(subjNum) '_task-FPMTMS_' 'date-' param.time_date '.mat'], 'subjID', 'stim', 'design', 'param')
cd (rootdir)

end