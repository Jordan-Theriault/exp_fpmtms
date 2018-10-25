% gstreamer must be installed.
% must have psychtoolbox.
function PA_encoding(subjID, acq)
Screen('Preference', 'SkipSyncTests', 1); 
Screen('Preference','VisualDebugLevel', 0);
Screen('Preference','Verbosity', 0);
rng('shuffle')
%% TR Specs
% TR should be 141
%% Parameters
rootdir =  '~/Desktop/TaskFiles/PairedAssociates_ScannerVersion';
% rootdir =  '~/Documents/pair_association';
behavdir = fullfile(rootdir, 'behavioral');
% stimdir = fullfile(rootdir, 'stimuli');
outputdir = fullfile(rootdir, 'output');

cd(behavdir)
load([subjID '.PA_design.mat'],'design', 'param')
if design.affect(acq) == 0
    viddir = fullfile(rootdir,'stimuli','videos','neutral');
else
    viddir = fullfile(rootdir,'stimuli','videos','negative');
end

param.wrap = 70; %new line after this many characters
param.big = 40; %big font size
param.small = 24; %font size for ratings
param.wordsize = 72; %font size for word, shown with image.

% time and date for output file
param.time_date = datestr(now, 'mm-dd-yyyy_HH-MM');

%image dimensions
param.img_x = 640;
param.img_y = 480;

% timing
param.encode_time = param.TR*2; % allow 2 TR (5 sec) for encoding.
% param.scanner_pause = param.TR*5; % pause for 12.5 seconds before beginning video.
% param.post_video_pause = param.TR*2; % stop for 5 seconds after video
% param.max_run_len = 352.5; % This should be fine. I think it was ending 
param.max_run_len = max(design.encode.video_len) + max(design.encode.onset(:,end))+ param.encode_time; 
% First number is length of longest video.
% Second number is max onset + 5 (length of one trial).

param.max_run_len = ceil(param.max_run_len/param.TR)*param.TR;
% Now round param.max_run_len to fit evenly into TRs.

% Other parameters are loaded from the Create_PA_scanner_design file. 

%% Load Stimuli
run.affect = design.affect(acq,1);
run.affect_name = design.affect_name(acq,1);
run.words = design.encode.words(acq,:);
run.images = design.encode.images(acq,:);
run.condition = design.encode.condition(acq,:);
run.condition_name = design.encode.condname(acq,:);
run.video = design.encode.video(acq);
run.video_len = design.encode.video_len(acq);
run.video_path = cell2mat(design.encode.vid_path(acq));
run.onset = design.encode.onset(acq,:);


%% Setup output
output.affect = cell(param.trials_per_run, 1); output.affect(:,1) = design.affect_name(acq); % high-negative / neutral
output.subjID = cell(param.trials_per_run,1); output.subjID(:,1) = {subjID};
output.video = cell(param.trials_per_run,1); output.video(:,1) = run.video(1);
output.acq = nan(param.trials_per_run, 1); output.acq(:,1) = acq;
output.trial = nan(param.trials_per_run, 1);
output.condition = cell(param.trials_per_run, 1); %face / scene
output.image = cell(param.trials_per_run, 1); %image name
output.word = cell(param.trials_per_run, 1); %word
output.onset_abs = nan(param.trials_per_run, 1); %absoute onset, for modeling
output.onset_rel = nan(param.trials_per_run, 1); %relative to memory task start, mostly for debugging.
output.onset_int = design.encode.onset(acq,:)'; %from design, to check against relative for debugging.

output.encode_resp_0M_1NM = nan(param.trials_per_run, 1); %response: match or not match
% output.encode_resp_correct = nan(param.trials_per_run,1); % is response correct?
output.encode_RT = nan(param.trials_per_run, 1); 

vidoutput.name = run.video(1);
vidoutput.dur = run.video_len;
vidoutput.onset = nan(1,1);


%%Text

text.prediction_text = 'Match                                  or                          Not A Match';
text.correct = 'CORRECT';
text.incorrect = 'INCORRECT';
text.noresp = 'Please try to provide a response.';

%% Key Setup
devices = PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName); % TODO - We might just be naming things and not grabbing them.
% kbd_devs = find(ismember(dev_names, 'Keyboard')==1); 
% Jordan - I dropped the line above. It seems to be breaking our ability to
% give input. In the TVTask, it returns an empty array, as it is set to
% ==4.
% Switch KbName into unified mode: 
KbName('UnifyKeyNames');
key.index = KbName('1!');
key.ring = KbName('2@');

%% Window Setup

HideCursor; 
displays = Screen('screens');
screenRect = Screen('rect', displays(end));
% screenRect = [0, 0, 800, 600]; % DEBUG
window = Screen('OpenWindow', displays(end), [0 0 0], screenRect, 32);%identifies the screen we will be drawing to
Screen(window, 'TextSize', param.big);

% [screenXpixels, screenYpixels] = Screen('WindowSize', window);
% baseRect = [0 0 screenYpixels*0.02 screenYpixels*0.02];
[xCenter, yCenter] = RectCenter(screenRect); %sets center for screenRect(x,y)
param.img_pos = [xCenter-param.img_x/2 yCenter-param.img_y/2 xCenter+param.img_x/2 yCenter+param.img_y/2];
% scooch the image up a bit.
param.img_pos(2) = param.img_pos(2) - param.img_y/3;
param.img_pos(4) = param.img_pos(4) - param.img_y/3;

param.text_pos.x = xCenter;
param.text_pos.y = yCenter+param.img_y/2.5;
param.text_pos.y2 = yCenter+param.img_y/2+param.wordsize + param.big*1.5;


cd ../

%%Instructions
DrawFormattedText(window, ['You will start by watching a video. \n\n\nYou won''t be asked to remember the details.'...
    '\n\n\nIt''s important that you pay attention to the video while it plays.'], 'center', 'center', 255, param.wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, ['After the video is over, you will see pairs of images and words.'...
    '\n\n\nThe images will be faces or scenes. \n\n\nFor each pair, you will be asked to judge whether'...
    ' the image and the word belong together. \n\n\nFor example...'], 'center', 'center', 255, param.wrap);
Screen('Flip', window);
KbStrokeWait;
Screen('PutImage', window, imread(char('dusty.jpg')), param.img_pos);
Screen('TextSize', window, 60);
DrawFormattedText(window, 'DUSTY', 'center', param.text_pos.y, 255);
Screen('TextSize', window, 45);
DrawFormattedText(window, '        Match                                        Not A Match','center', param.text_pos.y2-100, 255);
Screen('TextSize', window, 30);
DrawFormattedText(window, ['(Press the button with your                                             '...
    '(Press the button with your'],'center', param.text_pos.y2-40, 255);
DrawFormattedText(window, ['   POINTER FINGER if it is a MATCH)                     '...
    'MIDDLE FINGER if it is NOT A MATCH)'],'center', param.text_pos.y2-10, 255);
Screen('Flip', window);
KbStrokeWait;
Screen('PutImage', window, imread(char('silly.jpg')), param.img_pos);
Screen('TextSize', window, 60);
DrawFormattedText(window, 'SILLY', 'center', param.text_pos.y, 255);
Screen('TextSize', window, 45);
DrawFormattedText(window, '        Match                                        Not A Match','center', param.text_pos.y2-100, 255);
Screen('TextSize', window, 30);
DrawFormattedText(window, ['(Press the button with your                                             '...
    '(Press the button with your'],'center', param.text_pos.y2-40, 255);
DrawFormattedText(window, ['   POINTER FINGER if it is a MATCH)                     '...
    'MIDDLE FINGER if it is NOT A MATCH)'],'center', param.text_pos.y2-10, 255);
Screen('Flip', window);
KbStrokeWait;
cd(behavdir)
Screen(window, 'TextSize', param.big);
DrawFormattedText(window, 'Don''t worry about being right or wrong, just give it your best guess.', 'center', 'center', 255, param.wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, ['After you''ve viewed all the image-word pairs, you will rest briefly. '...
    '\n\n\nThen, you will be asked to remember them.'], 'center', 'center', 255, param.wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Please ask the experimenter if you have any questions.', 'center', 'center', 255, param.wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Ready to begin?', 'center', 'center', 255, param.wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Waiting for scanner.', 'center', 'center', 255, param.wrap);
Screen('Flip',window);

%% Trigger
while 1 %wait for the 1st trigger pulse
    FlushEvents;
    trig = GetChar;
    if trig == '='
        t1 = GetSecs; %experiment start time.
        break
    end
end
tic
Screen('Flip', window);
runStart = GetSecs;
% 
%% Affective Priming

cd(viddir)
% pause(param.scanner_pause)
AssertOpenGL; % Child protection
InitializePsychSound(1);
vid.sound = PsychPortAudio('Open', [], [], [], [], 1, [], .01, [], 2);

% stopmovie = 0;
vidoutput.onset = GetSecs - runStart;
Screen('Flip', window);
% Open movie file and retrieve basic info about movie:
[vid.movie movieduration fps imgw imgh] = Screen('OpenMovie', window, run.video_path);
        % Seek to start of movies (timeindex 0):
vid.rate = 1;
vid.vid_start = GetSecs;
Screen('SetMovieTimeIndex', vid.movie, GetSecs-vid.vid_start); % What is this doing? Just starting at the beginning?
Screen('PlayMovie', vid.movie, vid.rate, 1, 1.0); % play movie, at 1x speed, with endless loop (1), and 100% audio volume
while (GetSecs-vid.vid_start)<run.video_len-.2
%     if (GetSecs-vid.vid_start)>run.video_len-.2 % NOTE - this is the line that was giving us random crashes. 
%         Adjust the subtracted amount as necessary.
%         stopmovie = 1;
%         sprintf('break')
%         break
%     end
    % Fetch video frames and display them. End at length of video.
    if (abs(vid.rate)>0)
        % Return next frame in movie, in sync with current playback time and sound.
        % tex either the texture handle or zero if no new frame is ready yet.
        vid.tex = Screen('GetMovieImage', window, vid.movie, 0);

        % Valid texture returned?
        if vid.tex > 0
            % Draw the new texture immediately to screen:
            Screen('DrawTexture', window, vid.tex, []);
            % Release texture:
            Screen('Close', vid.tex);
        end

        % Update display if there is anything to update:
        if (vid.tex > 0)
            % We use clearmode=1, aka don't clear on flip. This is
            % needed to avoid flicker...
            Screen('Flip', window, 0, 1);
        else
            % Sleep a bit before next poll...
            WaitSecs('YieldSecs', 0.001); 
        end
    end
end
Screen('Flip', window);
Screen('Flip', window);
Screen('PlayMovie', vid.movie, 0);
Screen('CloseMovie', vid.movie);
PsychPortAudio('Stop', vid.sound);
PsychPortAudio('Close', vid.sound)
clear vid
sprintf('post-video')

%% Encoding Phase

%pause(param.post_video_pause)
    % This ensures that we begin on a TR. Accurate to 1/100 of a second.
    % So, based on the length of the video, the pause above could be just
    % over or under the specified length.
% while mod(round(GetSecs - runStart, 1), param.TR) ~= 0
%     pause(.01)
%     if mod(round(GetSecs - runStart, 1), param.TR) == 0
%         break
%     end
% end
mem_start = GetSecs;
% offset = 0;
for xx=1:param.trials_per_run
    % This pauses until we reach the specified onset for this trial.

    while run.onset(xx) > GetSecs - mem_start
       sprintf('pausing')
        pause(.1); % increased this to .01 from .001 to reduce load on CPU.
    end
    
    trial.start = GetSecs;
    output.onset_abs(xx) = GetSecs - runStart;
    output.onset_rel(xx) = GetSecs - mem_start;
    output.trial(xx) = xx;
    output.condition(xx) = run.condition_name(xx);

    %trial info
    trial.image = imread(char(run.images(xx))); %read image
        output.image{xx} = char(run.images(xx));
    trial.word = run.words{xx}; % read word from list.
        output.word{xx} = trial.word;
    trial.condition = run.condition(xx); % get condition 0 = scene, 1 = face 
    trial.condition_name = run.condition_name(xx); %get condition name
%         output.condition(xx) = trial.condition_name;

    % present word-image pair
    Screen('PutImage', window, trial.image, param.img_pos);
    Screen('TextSize', window, param.wordsize);
    DrawFormattedText(window, trial.word, 'center', param.text_pos.y, 255);
    Screen('TextSize', window, param.big);
    DrawFormattedText(window, text.prediction_text,'center', param.text_pos.y2, 255);
    Screen('Flip',window, 0, 1); 

    % Collect responses using KbCheck to confirm they have read story
    while (GetSecs - trial.start) < param.encode_time
        [keyIsDown, timeSecs, keyCode] = KbCheck;
        if (keyCode(key.index) == 1 || keyCode(key.ring) == 1) && isnan(output.encode_RT(xx))
            output.encode_RT(xx) = GetSecs - trial.start;
            if keyCode(key.index) == 1
                output.encode_resp_0M_1NM(xx) = 0; %match
                centeredRect1 = CenterRectOnPointd([0 0 200 80], xCenter*.31, yCenter*1.9);
                Screen('FrameRect', window, 255,centeredRect1, 5); 
                Screen('Flip',window, 0, 1);
            elseif keyCode(key.ring) == 1
                output.encode_resp_0M_1NM(xx) = 1; %no match
                centeredRect2 = CenterRectOnPointd([0 0 270 80], xCenter*1.63, yCenter*1.9);
                Screen('FrameRect', window, 255,centeredRect2, 5); 
                Screen('Flip',window, 0, 1);
            end
            % mark answer correct or not.
%             if output.encode_resp_0M_1NM(xx) == run.condition(xx)
%                 output.encode_resp_correct(xx) = 1;
%             else
%                 output.encode_resp_correct(xx) = 0;
%             end
        end
    end    

    Screen('Flip',window);
    Screen('Flip',window);
    cd(behavdir)
    save([subjID '.PA.run_' num2str(acq) '_encoding_' param.time_date '.mat'],'acq','subjID', 'output', 'vidoutput')
%     offset = round(run.jitter(xx), 3);
%     pause(run.jitter(xx)-.95*run.jitter(xx)); % pause for appropriate jitter time. % Shorterned, so that the 
end

output_table = struct2table(output);
cd(outputdir)
writetable(output_table, [subjID '.PA.run_' num2str(acq) '_encoding_' param.time_date '.csv']);

while ((GetSecs-t1)<param.max_run_len)
    early_finish = 'Thank you. \n\n The scan will end shortly.';
    Screen(window, 'TextSize', param.big);
    DrawFormattedText(window, early_finish, 'center', 'center', 255, param.wrap);
    Screen('Flip',window); 
end

cd(behavdir)
runDur = GetSecs - runStart;
save([subjID '.PA.run_' num2str(acq) '_encoding_' param.time_date '.mat'],'acq','subjID', 'output', 'vidoutput', 'runDur')

sca
toc
% exit
end