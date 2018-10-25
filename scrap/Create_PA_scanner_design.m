% Created by Jordan Theriault, jtheriault7@gmail.com

%Paired Association Task
% I made this separate because the affect_cb will be set once for each participant and
% should be tracked across subjects. We should keep some running log of
% this so that we know who will receive what order of counterbalancing.

% affect_cb just refers to whether subjects will receive a high-negative or
% neutral run first. 

% Use this once to determine the stimuli for all sessions. Afternoon
% sessions will start at the next run, i.e. usually 5-8.

% 0 = neutral first
% 1 = high-neg first.

% must have psychtoolbox.
function Create_PA_scanner_design(subjID, affect_cb)
rng('shuffle')
addpath(genpath(cd))
%% Parameters
rootdir = '~/Desktop/TaskFiles/PairedAssociates_ScannerVersion';
behavdir = fullfile(rootdir, 'behavioral');
stimdir = fullfile(rootdir, 'stimuli');

param.TR = 2.5;
param.trials_per_run = 30; % must be a number divisible by 2*3, will divide between face and scene, and pairs repeat 3 times. Will eventually be 30.
param.num_runs = 8; %will eventually be 8.
param.rep_per_run = 3; % repetitions of each pic-word pair. must divide evenly into trials per run after being multiplied by 2.
param.group_retrieval = 1; % for every 2 encoding runs, group them into one retrieval. As designed, can be 1, 2, or 4.
% param.jitter_time = 40; %40 seconds of jitter for each run.
% param.jitter_groups = [.6666666666, 1, 1.3333333333, 1.6666666666,  2]; %set these manually.
% param.jitter_repetitions = 6; %the sum of the array above, multiplied by this value, must equal param.jitter_time. 
                % Also, multiplied by number of jitter groups it should
                % equal the number of trials.
                
%% Run checks.
if floor(param.trials_per_run/(param.rep_per_run*2)) ~= param.trials_per_run/(param.rep_per_run*2)
    error('make sure that the repetitions per run can be multiplied by 2, then divided evenly into trials per run.')
end
% if round(param.jitter_time, 3) ~= round(sum(param.jitter_groups)*param.jitter_repetitions, 3)
%     error('make sure that jitter groups * jitter_repetitions is equal to jitter_time.')
% end
% if param.jitter_repetitions * length(param.jitter_groups) ~= param.trials_per_run
%     error('make number of jitter groups * jitter repetitions is equal to trials per run.')
% end

%% Set Affect Order

% find videos.
cd ([stimdir '/videos/negative'])
temp.negvideo = dir('*.mp4');
for xx=1:size(temp.negvideo,1)
    temp.negvideo(xx).path = [pwd filesep temp.negvideo(xx).name];
end
cd ([stimdir '/videos/neutral'])
temp.neuvideo = dir('*.mp4');
for xx=1:size(temp.neuvideo,1)
    temp.neuvideo(xx).path = [pwd filesep temp.neuvideo(xx).name];
end

% set video order
design.encode.video = cell(param.num_runs, 1);
temp.seed1 = randperm(param.num_runs/2);
temp.seed2 = randperm(param.num_runs/2);
if affect_cb == 0
    design.affect = [zeros([param.num_runs/2 1])', ones([param.num_runs/2 1])']';
    design.encode.video = {temp.neuvideo(temp.seed1).name ... % neutral first
        temp.negvideo(temp.seed2).name}; % then negative
    design.encode.video = design.encode.video'; % transpose to put runs in rows.
    %add paths
    design.encode.vid_path = {temp.neuvideo(temp.seed1).path ... % neutral first
        temp.negvideo(temp.seed2).path}; % then negative
    design.encode.vid_path = design.encode.vid_path'; % transpose to put runs in rows.
elseif affect_cb == 1
    design.affect = [ones([param.num_runs/2 1])', zeros([param.num_runs/2 1])']';
    design.encode.video = {temp.negvideo(temp.seed1).name ... % negative first
        temp.neuvideo(temp.seed2).name}; % then neutral
    design.encode.video = design.encode.video'; % transpose to put runs in rows.
    % add paths
    design.encode.vid_path = {temp.negvideo(temp.seed1).path ... % negative first
        temp.neuvideo(temp.seed2).path}; % then neutral
    design.encode.vid_path = design.encode.vid_path'; % transpose to put runs in rows.

else error('second parameter was something other than 0, or 1. Use 0 for neutral-first run order. Use 1 for high-neg first run order.')
end

design.encode.video_len = nan(param.num_runs,1);
for xx = 1:size(design.encode.video_len)
    temp.vid_info = VideoReader(cell2mat(design.encode.video(xx)));
    design.encode.video_len(xx) = temp.vid_info.Duration;
end

design.affect_name = cell(param.num_runs, 1);
design.affect_name(find(design.affect==1)) = {'High-Neg'}; 
design.affect_name(find(design.affect==0)) = {'Neutral'}; 

clear temp xx
%% Collect Stimuli.
cd ([stimdir '/words']);
% words = strrep(table2array(readtable('words.csv')), ' ', ''); %strrep added to get rid of white space.
load('words.mat')

% Return full list of faces files.
cd ([stimdir '/faces']);
faces = [dir('*.jpeg');dir('*.jpg')];
for xx=1:size(faces,1)
    faces(xx).name = [stimdir '/faces/' faces(xx).name ];
end

% get scene files
cd ([stimdir '/scenes']);
scenes = [dir('*.jpeg');dir('*.jpg')];
for xx=1:size(scenes,1)
    scenes(xx).name = [stimdir '/scenes/' scenes(xx).name ];
end

%% Get optsec info
% Get conditions, cond names, and onsets (to account for jitter)
% Designed with 8 encoding runs, and 4 retrieval runs in mind.
% Encoding
cd ([rootdir '/design/optsec/encode'])
optsec_files = dir('*.csv');

design.encode.condition = nan(param.num_runs, param.trials_per_run);
design.encode.condname = cell(param.num_runs, param.trials_per_run);
design.encode.onset = nan(param.num_runs, param.trials_per_run);

for xx=1:size(optsec_files,1)
    optsec = readtable(optsec_files(xx).name);
    temp.rows = optsec.cond_0_ITI_1face_2scene~=0; %grab all rows which are not NULL, jitter events.
    temp.cond = table2array(optsec(temp.rows, {'cond_0_ITI_1face_2scene'}));
    temp.condname = table2array(optsec(temp.rows, {'label'}));
    temp.onset = table2array(optsec(temp.rows, {'x___onset'}));
    
    design.encode.condition(xx,:) = [temp.cond-1]'; %transpose to fit in row, subtract 1. Face =0, scene = 1
    design.encode.condname(xx,:) = temp.condname';
    design.encode.onset(xx,:) = temp.onset';
end

% Retrieval
cd ([rootdir '/design/optsec/retrieve'])
optsec_files = dir('*.csv');

design.retrieve.condition  = nan(param.num_runs/param.group_retrieval, (param.trials_per_run/param.rep_per_run)*param.group_retrieval);
design.retrieve.condname  = cell(param.num_runs/param.group_retrieval, (param.trials_per_run/param.rep_per_run)*param.group_retrieval);
design.retrieve.onset  = nan(param.num_runs/param.group_retrieval, (param.trials_per_run/param.rep_per_run)*param.group_retrieval);

for xx=1:size(optsec_files,1)
    optsec = readtable(optsec_files(xx).name);
    temp.rows = optsec.cond_0_ITI_1face_2scene~=0; %grab all rows which are not NULL, jitter events.
    temp.cond = table2array(optsec(temp.rows, {'cond_0_ITI_1face_2scene'}));
    temp.condname = table2array(optsec(temp.rows, {'label'}));
    temp.onset = table2array(optsec(temp.rows, {'x___onset'}));
    
    design.retrieve.condition(xx,:) = [temp.cond-1]'; %transpose to fit in row, subtract 1. Face =0, scene = 1
    design.retrieve.condname(xx,:) = temp.condname';
    design.retrieve.onset(xx,:) = temp.onset';
end

cd (behavdir)
%% Shuffle conditions and stimuli

%shuffle all rows of optsec, so that order of runs not consistent across
%subjects.
temp.seed = randperm(size(design.encode.condition,1)); % these orders were set by optsec, so make sure all runs are shuffled in the same way.
design.encode.condition = design.encode.condition(temp.seed,:);
design.encode.condname  = design.encode.condname(temp.seed,:);
design.encode.onset  = design.encode.onset(temp.seed,:);

temp.seed = randperm(size(design.retrieve.condition,1)); % these orders were set by optsec, so make sure all runs are shuffled in the same way.
design.retrieve.condition = design.retrieve.condition(temp.seed,:);
design.retrieve.condname = design.retrieve.condname(temp.seed,:);
design.retrieve.onset = design.retrieve.onset(temp.seed,:);

%shuffle stimuli.
stimuli.allwords = Shuffle(words);
stimuli.allfaces = Shuffle({faces.name}');
stimuli.allscenes = Shuffle({scenes.name}');

clear words faces scenes xx temp optsec optsec_files
%% Set Randomized Stimuli design.
% Assign words and images.
design.encode.words = cell(param.num_runs, param.trials_per_run);
design.encode.images = cell(param.num_runs, param.trials_per_run);
design.retrieve.words = cell(param.num_runs/param.group_retrieval, (param.trials_per_run/param.rep_per_run)*param.group_retrieval);
design.retrieve.images = cell(param.num_runs/param.group_retrieval, (param.trials_per_run/param.rep_per_run)*param.group_retrieval);
temp.ipoint1 = 1; % use this to iterate through blocks of images.
temp.wpoint1 = 1; % use this to iterate through blocks of words.
temp.epoint1 = 1; % use this to iterate through encoding runs.

for xx = 1:size(design.retrieve.condition,1) % iterating through retrieval runs.
    temp.ipoint2 = xx*(length(stimuli.allscenes)*2/3)/size(design.retrieve.condition,1); % adjusted for procdis
    temp.wpoint2 = xx*(length(stimuli.allwords)*2/3)/size(design.retrieve.condition,1); % adjusted for procdis
    temp.epoint2 = xx*param.group_retrieval;
    %grab the necessary stimuli.
    temp.faces = stimuli.allfaces(temp.ipoint1:temp.ipoint2);
    temp.scenes = stimuli.allscenes(temp.ipoint1:temp.ipoint2);
    temp.words = stimuli.allwords(temp.wpoint1:temp.wpoint2);
    % rearrange words. Row 1 is for faces, Row 2 is for scenes.
    temp.r.words = reshape(temp.words, 5, 2)'; % TODO - hardcoded, 08-16-2018
    
    %find their place by condition
    temp.r.face_loc = find(design.retrieve.condition(xx,:)== 0);
    temp.r.scene_loc = find(design.retrieve.condition(xx,:)== 1);
    % Enter images, and paired words. Do this in a consistent order so the
    % same can be applied to encoding.
    design.retrieve.images(xx, temp.r.face_loc) = temp.faces;
    design.retrieve.words(xx, temp.r.face_loc) = temp.r.words(1,:); % assign face words
    design.retrieve.images(xx, temp.r.scene_loc) = temp.scenes;
    design.retrieve.words(xx, temp.r.scene_loc) = temp.r.words(2,:); % assign scene words
    
    % ENCODING
    % First, rearrange the faces for retrieval to be used in encoding.
    temp.e.faces = reshape(temp.faces, length(temp.faces)/length(temp.epoint1:temp.epoint2), length(temp.epoint1:temp.epoint2))';
    temp.e.scenes = reshape(temp.scenes, length(temp.scenes)/length(temp.epoint1:temp.epoint2),  length(temp.epoint1:temp.epoint2))';
    %further reshape words, to get separate face and scene groups.
    temp.e.words_faces = reshape(temp.r.words(1, :), ...
        length(temp.faces)/length(temp.epoint1:temp.epoint2), length(temp.epoint1:temp.epoint2))';
    temp.e.words_scenes = reshape(temp.r.words(2, :), ...
        length(temp.scenes)/length(temp.epoint1:temp.epoint2), length(temp.epoint1:temp.epoint2))';

    for yy = 1:length(temp.epoint1:temp.epoint2) %iterating through encoding runs, matched with retrieval?by default, 2 per retrieval run.
        temp.e.run = temp.epoint1+(yy-1);
        % This grabs the original presentaitons. The rest will be
        % repetitions.
        temp.e.face_loc = find(design.encode.condition(temp.e.run,:)==0); % 0 - face
        temp.e.face_loc = reshape(temp.e.face_loc, length(temp.e.face_loc)/param.rep_per_run, param.rep_per_run)';
        
        temp.e.scene_loc = find(design.encode.condition(temp.e.run,:)==1); % 1 = scene
        temp.e.scene_loc = reshape(temp.e.scene_loc, length(temp.e.scene_loc)/param.rep_per_run, param.rep_per_run)';
        
        % Fill in the original set, for this run.
        design.encode.images(temp.e.run, temp.e.face_loc(1,:)) = temp.e.faces(yy, :);
        design.encode.words(temp.e.run, temp.e.face_loc(1,:)) =  temp.e.words_faces(yy,:);

        design.encode.images(temp.e.run, temp.e.scene_loc(1,:)) = temp.e.scenes(yy, :);
        design.encode.words(temp.e.run, temp.e.scene_loc(1,:)) =  temp.e.words_scenes(yy,:);
        
        % Now grab the last face and scene of the original set. We want to
        % avoid repeating images in the next set.
        temp.e.last_face = temp.e.faces(yy, end);
        temp.e.last_scene = temp.e.scenes(yy, end);
        for zz = 2:(param.rep_per_run) % iterate through repetiions, WITHIN the encoding run.
            %FACES
            % Make sure face doesn't repeat in the next repetition
            temp.seed = randperm(length(temp.e.faces(yy, :)));
            while strcmp(temp.e.last_face, temp.e.faces(yy,temp.seed(1))) == 1
                temp.seed = randperm(length(temp.e.faces(yy, :)));
            end
            % add faces to design.
            design.encode.images(temp.e.run, temp.e.face_loc(zz,:)) = temp.e.faces(yy, temp.seed);
            design.encode.words(temp.e.run, temp.e.face_loc(zz,:)) = temp.e.words_faces(yy, temp.seed);
            temp.e.last_face = temp.e.faces(yy, temp.seed(end)); % grab the last image from the new random order.
            
            %SCENES
            % Make sure scene doesn't repeat.
            temp.seed = randperm(length(temp.e.scenes(yy, :)));
            while strcmp(temp.e.last_scene, temp.e.scenes(yy,temp.seed(1))) == 1
                temp.seed = randperm(length(temp.e.scenes(yy, :)));
            end
            % add scene to design.
            design.encode.images(temp.e.run, temp.e.scene_loc(zz,:)) = temp.e.scenes(yy, temp.seed);
            design.encode.words(temp.e.run, temp.e.scene_loc(zz,:)) = temp.e.words_scenes(yy, temp.seed);
            temp.e.last_scene = temp.e.scenes(yy, temp.seed(end)); % grab the last image from the new random order.
        end % move to the next repetition
        
    end
    temp.ipoint1 = temp.ipoint2+1;
    temp.wpoint1 = temp.wpoint2+1;
    temp.epoint1 = temp.epoint2+1;
end

%% Create ProcDis
% create empty arrays
temp.procdis.images = cell(8, 10);
temp.procdis.words = cell(8, 10);
temp.procdis.condition = nan(8, 10);
temp.procdis.condname = cell(8, 10);
% grab first 5 scenes and images for each run. % NOTE - this is hardcoded.
for xx = 1:8 % cycle through encoding runs.
    temp.faceloc = find(design.encode.condition(xx,:)==0);
    temp.sceneloc = find(design.encode.condition(xx,:)==1);
    %images
    temp.procdis.images(xx, 1:5) = design.encode.images(xx, temp.faceloc(1:5));
    temp.procdis.images(xx, 6:10) = design.encode.images(xx, temp.sceneloc(1:5));
    %words
    temp.procdis.words(xx, 1:5) = design.encode.words(xx, temp.faceloc(1:5));
    temp.procdis.words(xx, 6:10) = design.encode.words(xx, temp.sceneloc(1:5));
    %conditions
    temp.procdis.condition(xx, 1:5) = design.encode.condition(xx, temp.faceloc(1:5));
    temp.procdis.condition(xx, 6:10) = design.encode.condition(xx, temp.sceneloc(1:5));
    %condname
    temp.procdis.condname(xx, 1:5) = design.encode.condname(xx, temp.faceloc(1:5));
    temp.procdis.condname(xx, 6:10) = design.encode.condname(xx, temp.sceneloc(1:5));
end

% set up final design.
design.procdis.images = cell(2, 60);
design.procdis.words = cell(2, 60);
design.procdis.condition = nan(2, 60);
design.procdis.condname = cell(2, 60);

% reshape images into the final design. 1:40 were shown in the scanner.
design.procdis.images(:,1:40) = reshape(temp.procdis.images', 40, 2)'; 
design.procdis.words(:,1:40) = reshape(temp.procdis.words', 40, 2)';
design.procdis.condition(:,1:40) = reshape(temp.procdis.condition', 40, 2)'; 
design.procdis.condname(:,1:40) = reshape(temp.procdis.condname', 40, 2)';

% shuffle everything, just to be sure to break up any simple relationships. 
temp.seed = randperm(40);
temp.procdis.images = design.procdis.images(:,1:40);
design.procdis.images(:,1:40) = design.procdis.images(:,temp.seed);
temp.procdis.words = design.procdis.words(:,1:40);
design.procdis.words(:,1:40) = design.procdis.words(:,temp.seed);
temp.procdis.condition = design.procdis.condition(:,1:40);
design.procdis.condition(:,1:40) = design.procdis.condition(:,temp.seed);
temp.procdis.condname = design.procdis.condname(:,1:40);
design.procdis.condname(:,1:40) = design.procdis.condname(:,temp.seed);

% leave first 20 alone, sort next 20, for both morning and afternoon session.
temp.seed1 = randperm(20);
temp.seed2 = randperm(20);
% images are not sorted, meaning that word-image relationship is disrupted.
% temp.procdis.images = design.procdis.images(:,21:40);
% design.procdis.images(1,21:40) = temp.procdis.images(1,temp.seed1);
% design.procdis.images(2,21:40) = temp.procdis.images(2,temp.seed2);
temp.procdis.words = design.procdis.words(:,21:40);
design.procdis.words(1,21:40) = temp.procdis.words(1,temp.seed1);
design.procdis.words(2,21:40) = temp.procdis.words(2,temp.seed2);
temp.procdis.condition = design.procdis.condition(:,21:40);
design.procdis.condition(1,21:40) = temp.procdis.condition(1,temp.seed1);
design.procdis.condition(2,21:40) = temp.procdis.condition(2,temp.seed2);
temp.procdis.condname = design.procdis.condname(:,21:40);
design.procdis.condname(1,21:40) = temp.procdis.condname(1,temp.seed1);
design.procdis.condname(2,21:40) = temp.procdis.condname(2,temp.seed2);

% add remaining dummy trials.
design.procdis.images(:,41:50) = reshape(stimuli.allfaces(41:end), 2, 10); % faces
design.procdis.images(:,51:60) = reshape(stimuli.allscenes(41:end), 2, 10); %scenes
design.procdis.words(:,41:60) = reshape(stimuli.allwords(81:end), 2, 20); %words
design.procdis.condition(:,41:60) = [repmat(0, 2, 10), repmat(1, 2,10)];
design.procdis.condname(:,41:60) = [repmat({'face'}, 2, 10), repmat({'scene'}, 2,10)];
% identify these new conditions.
design.procdis.procdiscondname = cell(2, 60);
design.procdis.procdiscond = nan(2, 60);
design.procdis.procdiscondname = [repmat({'old'}, 2, 20), repmat({'mixed'}, 2, 20), repmat({'new'}, 2, 20)];
design.procdis.procdiscond = [repmat(0, 2, 20), repmat(1, 2, 20), repmat(2, 2, 20)];

% then shuffle them all up.
temp.shuffle = randperm(60);
design.procdis.images = design.procdis.images(:,temp.shuffle);
design.procdis.words = design.procdis.words(:, temp.shuffle);
design.procdis.condition = design.procdis.condition(:, temp.shuffle);
design.procdis.condname = design.procdis.condname(:, temp.shuffle);
design.procdis.procdiscondname = design.procdis.procdiscondname(:,temp.shuffle);
design.procdis.procdiscond = design.procdis.procdiscond(:,temp.shuffle);

clear xx yy zz temp

%% Save Behavioral File
cd (behavdir)
save([subjID '.PA_design.mat'],'subjID','affect_cb', 'design', 'param')
cd (rootdir)
end