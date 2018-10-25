% must have psychtoolbox.
function FPM_TMS(subjID, acq)
Screen('Preference', 'SkipSyncTests', 1); 
Screen('Preference','VisualDebugLevel', 0);
Screen('Preference','Verbosity', 0);
rng('shuffle')
%% Directories
rootdir = '~/projects/FPM_TMS/experiment';
behavdir = fullfile(rootdir, 'behavioral');
% stimdir = fullfile(rootdir, 'stimuli');
outputdir = fullfile(rootdir, 'output');
%% Load design
cd(behavdir)
temp.subj_design = dir(['design_sub-' num2str(subjID) '*']);
assert(numel(temp.subj_design) == 1, 'multiple (or zero) files returned for subjID. Check /behavioral folder.');
load(temp.subj_design.name)

%% Parameters
param.wrap = 70; %new line after this many characters
param.big = 40; %big font size
param.small = 24; %font size for ratings
param.wordsize = 72; %font size for word, shown with image.

% time and date for output file
param.time_date = datestr(now, 'mm-dd-yyyy_HH-MM');

param.max_trial_len = 10; % allow max 10 sec per trial
% Other parameters are loaded from the Create_PA_scanner_design file. 
param.trials_per_run = size(design.stim_text,1);
%% Setup output

output.subjID = cell(param.trials_per_run,1); output.subjID(:,1) = {subjID};
output.acq = zeros(param.trials_per_run, 1); output.acq(:,1) = acq;
output.trial = nan(param.trials_per_run, 1);
output.stim_id = design.stim_id(:,acq);
output.stim_pair = design.stim_pair(:,acq);
output.stim_text = design.stim_text(:,acq);
output.mrl_prf = design.mrl_prf(:,acq);
output.pos_no_con = design.pos_no_con(:,acq);
output.trial_onset = nan(param.trials_per_run, 1); %absoute onset, for modeling

output.read_RT = nan(param.trials_per_run,1);
output.resp_RT = nan(param.trials_per_run,1);
output.resp = nan(param.trials_per_run,1);


%% Instructions and Text
% Instructions % TODO - use examples. Multiple instruction slides.
text.inst1 = ['You will read several statements.'...
    '\n\n\n For each, you will rate how much you think it is ABOUT FACTS.'];
text.inst2 = ['First, the statement will appear on its own.'...
    '\n\n\n When you are done reading it, press <SPACE>' ...
    '\n\n\n We will show you an example next.'];
text.inst3 = ['When you are done reading, a scale will appear below the statement.' ...
    '\n\n\n Use the LEFT and RIGHT ARROW KEYS to choose your answer' ...
    '\n\n\n To confirm your answer, press <SPACE>.' ...
    '\n\n We will show you an example next.'];
text.inst4 = ['If you take too long to provide an answer, then the experiment will advance on its own.' ...
    '\n\n\n So please answer as quickly as you can.'];
text.example = 'A circle is round.';
text.ready = ['Please remember:' ...
    '\n\n\n Rate each item on how much you think it is ABOUT FACTS.' ...
    '\n\n\n If you take too long to answer, the experiment will advance on its own.' ...
    '\n\n\n We are now ready to begin stimulation. Please let the experimenter know that you are finished reading the instructions.'];
%Text
text.rating = 'To what degree is this statement about FACTS?';
text.scale =  'Not at all                                                        Completely';

text.space_advance = 'Press <SPACE> to advance';
text.space_confirm = 'Press <SPACE> to confirm';
text.timeout = 'Please answer quickly';

%% Key Setup
devices = PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName); 
% kbd_devs = find(ismember(dev_names, 'Keyboard')==1); 
% Switch KbName into unified mode: 
KbName('UnifyKeyNames');
key.left = KbName('LeftArrow');
key.right = KbName('RightArrow');
key.space = KbName('space');

%% Window Setup

HideCursor; 
displays = Screen('screens');
screenRect = Screen('rect', displays(end));
% screenRect = [0, 0, 800, 600]; % DEBUG
window = Screen('OpenWindow', displays(end), [0 0 0], screenRect, 32);%identifies the screen we will be drawing to
Screen(window, 'TextSize', param.big);
[xCenter, yCenter] = RectCenter(screenRect); %sets center for screenRect(x,y)
[screenXpixels, screenYpixels] = Screen('WindowSize', window);


% response line setup
pixelsPerPress = ((screenXpixels*(2/3))-(screenXpixels*(1/3)))/100; % Set the amount we want our square to move on each button press
rectColor = 255;
baseRect = [0 0 screenYpixels*0.02 screenYpixels*0.02];
screen_range = (screenXpixels*(2/3)-screenXpixels*(1/3));

%% Instructions % TODO - improve
DrawFormattedText(window, text.inst1, 'center', yCenter/1.5, 255, param.wrap);
DrawFormattedText(window, text.space_advance,'center', yCenter*1.66, 255);
Screen('Flip', window);
WaitSecs(.5);
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        break
    end
end

DrawFormattedText(window, text.inst2, 'center', yCenter/1.5, 255, param.wrap);
DrawFormattedText(window, text.space_advance,'center', yCenter*1.66, 255);
Screen('Flip', window);
WaitSecs(.5);
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        break
    end
end

% Example of scenario screen.
Screen('TextSize', window, param.big);
DrawFormattedText(window, text.example, 'center', yCenter/1.5, 255, param.wrap); % put text 1/3 up screen
DrawFormattedText(window, text.space_advance,'center', yCenter*1.66, 255);
Screen('Flip',window, 0, 1);   
WaitSecs(.5);
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        break
    end
end

DrawFormattedText(window, text.inst3, 'center', yCenter/1.5, 255, param.wrap);
DrawFormattedText(window, text.space_advance,'center', yCenter*1.66, 255);
Screen('Flip', window);
WaitSecs(.5);
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        break
    end
end

% Example of trial.
Screen('TextSize', window, param.big);
DrawFormattedText(window, text.example, 'center', yCenter/1.5, 255, param.wrap); % put text 1/3 up screen
DrawFormattedText(window, text.space_advance,'center', yCenter*1.66, 255);
Screen('Flip',window, 0, 1);   
WaitSecs(.5);
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        break
    end
end

squareX = xCenter;
squareY = yCenter*1.4;
trial.ratestart = GetSecs;
while 1
    % Check the keyboard to see if a button has been pressed
    [keyIsDown,secs, keyCode] = KbCheck;
    centeredRect = CenterRectOnPointd(baseRect, squareX, squareY);
    Screen('TextSize', window, param.small);

    %this draws the line
    Screen('TextSize', window, param.big);
    DrawFormattedText(window, text.example, 'center', yCenter/1.5, 255, param.wrap); % put text 1/3 up screen
    DrawFormattedText(window, text.rating, 'center', yCenter, 255, param.wrap);
    DrawFormattedText(window, text.scale, 'centerblock', yCenter*1.3, 255);
    DrawFormattedText(window, text.space_confirm,'center', yCenter*1.66, 255);


    Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
    Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
    Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
    Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
    % We set bounds to make sure our square stays within rating line
    if squareX < screenXpixels*(1/3)
        squareX = screenXpixels*(1/3);
    elseif squareX > screenXpixels*(2/3)
        squareX = screenXpixels*(2/3);
    end

   % This draws the cursor
    Screen('FillRect', window, rectColor, centeredRect);
    Screen('Flip', window);

    % Depending on the button press, move ths position of the square
     if keyCode(key.left)
         squareX = squareX - pixelsPerPress;
     elseif keyCode(key.right)
         squareX = squareX + pixelsPerPress;
     elseif keyCode(key.space) && (GetSecs - trial.ratestart > .5)
        % display grey square, after redrawing display.
        squareX = squareX + 0;
        Screen('TextSize', window, param.big);
        DrawFormattedText(window, text.example, 'center', yCenter/1.5, 255, param.wrap); % put text 1/3 up screen
        DrawFormattedText(window, text.rating, 'center', yCenter, 255, param.wrap);
        DrawFormattedText(window, text.scale, 'centerblock', yCenter*1.3, 255);
        DrawFormattedText(window, text.space_confirm,'center', yCenter*1.66, 255);
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
        Screen('FillRect', window, 127.5, centeredRect);
        Screen('Flip', window);
        % wait a moment.
        WaitSecs(.5);
        break
     end
end

DrawFormattedText(window, text.inst4, 'center', yCenter/1.5, 255, param.wrap);
DrawFormattedText(window, text.space_advance,'center', yCenter*1.66, 255);
Screen('Flip', window);
WaitSecs(.5);
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        break
    end
end

% Ready screen.
DrawFormattedText(window, text.ready, 'center', 'center', 255, param.wrap);
Screen('Flip',window);

%% Trigger
while 1 %wait for someone to press '='
    FlushEvents;
    trig = GetChar;
    if trig == '='
        runStart = GetSecs; %experiment start time.
        break
    end
end
Screen('Flip', window);
cd(behavdir)
%% Rating Screens
for xx=1:param.trials_per_run
    trial.start = GetSecs;
    output.trial_onset(xx) = GetSecs - runStart;
    output.trial(xx) = xx;
   
    %trial info
    trial.text = output.stim_text(xx); % Read Text.
    % present statement
    Screen('TextSize', window, param.big);
    DrawFormattedText(window, char(trial.text), 'center', yCenter/1.5, 255, param.wrap); % put text 1/3 up screen
    DrawFormattedText(window, text.space_advance,'center', yCenter*1.66, 255);
    Screen('Flip',window, 0, 1);   
    WaitSecs(.5);
    
    while 1
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyIsDown == 1 && keyCode(key.space) 
            output.read_RT(xx) = GetSecs - trial.start;
            break
        end
        if GetSecs - trial.start > param.max_trial_len
            Screen('Flip', window);
            DrawFormattedText(window, text.timeout,'center', yCenter, 255);
            Screen('Flip', window);
            pause(1);
            break
        end
    end
    
    squareX = xCenter;
    squareY = yCenter*1.4;
    trial.ratestart = GetSecs;
    while GetSecs - trial.start < param.max_trial_len
        % Check the keyboard to see if a button has been pressed
        [keyIsDown,secs, keyCode] = KbCheck;
        centeredRect = CenterRectOnPointd(baseRect, squareX, squareY);
        Screen('TextSize', window, param.small);
        
        %this draws the line
        Screen('TextSize', window, param.big);
        DrawFormattedText(window, char(trial.text), 'center', yCenter/1.5, 255, param.wrap); % put text 1/3 up screen
        DrawFormattedText(window, text.rating, 'center', yCenter, 255, param.wrap);
        DrawFormattedText(window, text.scale, 'centerblock', yCenter*1.3, 255);
        DrawFormattedText(window, text.space_confirm,'center', yCenter*1.66, 255);
        
        
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
        % We set bounds to make sure our square stays within rating line
        if squareX < screenXpixels*(1/3)
            squareX = screenXpixels*(1/3);
        elseif squareX > screenXpixels*(2/3)
            squareX = screenXpixels*(2/3);
        end

       % This draws the cursor
        Screen('FillRect', window, rectColor, centeredRect);
        Screen('Flip', window);

        % Depending on the button press, move ths position of the square
         if keyCode(key.left)
             squareX = squareX - pixelsPerPress;
         elseif keyCode(key.right)
             squareX = squareX + pixelsPerPress;
         elseif keyCode(key.space) && (GetSecs - trial.ratestart > .5)
            % display grey square, after redrawing display.
            squareX = squareX + 0;
            Screen('TextSize', window, param.big);
            DrawFormattedText(window, char(trial.text), 'center', yCenter/1.5, 255, param.wrap); % put text 1/3 up screen
            DrawFormattedText(window, text.rating, 'center', yCenter, 255, param.wrap);
            DrawFormattedText(window, text.scale, 'centerblock', yCenter*1.3, 255);
            DrawFormattedText(window, text.space_confirm,'center', yCenter*1.66, 255);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
            Screen('FillRect', window, 127.5, centeredRect);
            Screen('Flip', window);
            % get output
            output.resp_RT(xx) = GetSecs - trial.ratestart;
            output.resp(xx) = (squareX-screenXpixels*(1/3))/screen_range*100;
            % wait a moment.
            WaitSecs(.5);
            break
         end
    end             
    
    % TODO - get fact/moral/preference ratings.
    
    if isnan(output.resp_RT(xx)) %TODO make sure this doesn't double.
        Screen('Flip', window);
        DrawFormattedText(window, text.timeout,'center', yCenter, 255);
        Screen('Flip', window);
        pause(1);
    end
    
    Screen('Flip',window);
    Screen('Flip',window);
    save(['data_sub-' subjID '_run-' num2str(acq) '_task-FPMTMS_' 'date-' param.time_date '.mat'],'acq','subjID', 'output', 'design')
end
% save .mat
runDur = GetSecs - runStart;
save(['data_sub-' subjID '_run-' num2str(acq) '_task-FPMTMS_' 'date-' param.time_date '.mat'],'acq','subjID', 'output', 'design', 'runDur')
% save .csv
output_table = struct2table(output);
cd(outputdir)
writetable(output_table, ['data_sub-' num2str(subjID) '_run-' num2str(acq) '_task-FPMTMS_' 'date-' param.time_date '.tsv'], 'FileType', 'text', 'Delimiter', '\t');

cd(rootdir)

sca
end