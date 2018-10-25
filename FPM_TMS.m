% must have psychtoolbox.
function FPM_TMS(subjID, acq)
Screen('Preference', 'SkipSyncTests', 1); 
Screen('Preference','VisualDebugLevel', 0);
Screen('Preference','Verbosity', 0);
rng('shuffle')
%% Directories
rootdir = '~/Desktop/FPM_TMS/experiment';
behavdir = fullfile(rootdir, 'behavioral');
% stimdir = fullfile(rootdir, 'stimuli');
outputdir = fullfile(rootdir, 'output');
%% Load design
cd(behavdir)
temp.subj_design = dir(['design_sub-' sprintf('%02d', subjID) '*']);
assert(numel(temp.subj_design) == 1, 'multiple (or zero) files returned for subjID. Check /behavioral folder.');
load(temp.subj_design.name)

%% Parameters
param.wrap = 70; %new line after this many characters
param.big = 40; %big font size
param.small = 24; %font size for ratings
param.wordsize = 72; %font size for word, shown with image.

% time and date for output file
param.time_date = datestr(now, 'mm-dd-yyyy_HH-MM');

param.max_trial_len = 14; % allow max 14 sec per trial
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
output.resp1_cat = cell(param.trials_per_run,1); output.resp1_cat(:,1) = design.q_order(1);
output.resp2_cat = cell(param.trials_per_run,1); output.resp2_cat(:,1) = design.q_order(2);
output.resp3_cat = cell(param.trials_per_run,1); output.resp3_cat(:,1) = design.q_order(3);
output.resp1_RT = nan(param.trials_per_run,1);
output.resp2_RT = nan(param.trials_per_run,1);
output.resp3_RT = nan(param.trials_per_run,1);
output.respAll_RT = nan(param.trials_per_run,1);
output.resp1 = nan(param.trials_per_run,1);
output.resp2 = nan(param.trials_per_run,1);
output.resp3 = nan(param.trials_per_run,1);

dynamicoutput.resp = zeros(1000,param.trials_per_run);
dynamicoutput.cat = cell(1000,param.trials_per_run);
dynamicoutput.time = zeros(1000,param.trials_per_run);

%% Instructions and Text
% Instructions % 
text.inst1 = ['You will read several statements.'...
    '\n\n\n For each, you will rate the degree that you think it is:' ...
    '\n\n', design.q_text{1}, '\n\n', design.q_text{2}, '\n\n and \n\n', design.q_text{3}];
text.inst2 = ['First, the statement will appear on its own.'...
    '\n\n\n When you are done reading it, press <SPACE>' ...
    '\n\n\n We will show you an example next.'];
text.inst3 = ['When you are done reading, three scales will appear below the statement.' ...
    '\n\n\n Use the "A" and "D" keys to move the cursor LEFT and RIGHT.' ...
    '\n\n\n To confirm your answer, press <SPACE>.' ...
    '\n\n\n After confirming, you will answer the next question down.' ...
    '\n\n We will show you an example next.'];
text.inst4 = ['If you take more than ', num2str(param.max_trial_len), ' seconds to provide an answer, then the experiment will advance on its own.' ...
    '\n\n\n So please answer as quickly as you can.'];
text.example = 'A circle is round.';
text.ready = ['Please remember:' ...
    '\n\n\n Rate each item on how much you think it is' ...
    '\n\n', design.q_text{1}, '\n\n', design.q_text{2}, '\n\n and \n\n', design.q_text{3} ...
    '\n\n\n If you take more than ', num2str(param.max_trial_len), ' seconds to answer then the experiment will advance on its own.'];
%Text
text.rating = 'To what degree is this statement...';
text.rate1 = [design.q_text{1}, '?']; % get About Fact, About Moral, About Preference Rating.
text.rate2 = [design.q_text{2}, '?'];
text.rate3 = [design.q_text{3}, '?'];
text.scale =  'Not at all                                            Completely';

text.space_advance = 'Press <SPACE> to advance';
text.space_confirm = 'Press <SPACE> to confirm';
text.space_doneTMS = 'When stimulation is finished, press <SPACE> to advance.';
text.timeout = 'Please answer quickly';

%% Key Setup
devices = PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName); 
% kbd_devs = find(ismember(dev_names, 'Keyboard')==1); 
% Switch KbName into unified mode: 
KbName('UnifyKeyNames');
% key.up = KbName('UpArrow');
% key.down = KbName('DownArrow');
% key.left = KbName('LeftArrow');
% key.right = KbName('RightArrow');
% key.up = KbName('w');
% key.down = KbName('s');
key.left = KbName('a');
key.right = KbName('d');
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
pixelsPerPress = ((screenXpixels*(2/3))-(screenXpixels*(1/3)))/50; % Set the amount we want our square to move on each button press
baseRect = [0 0 screenYpixels*0.02 screenYpixels*0.02];
screen_range = (screenXpixels*(2/3)-screenXpixels*(1/3));

textY = yCenter*.5;
rateY = yCenter*.75;
scaleY = yCenter*1.6;
spaceY = yCenter*1.9;

%% Instructions % 
% Ready screen.
DrawFormattedText(window, text.ready, 'center', 'center', 255, param.wrap);
Screen('Flip',window);
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        break
    end
end

DrawFormattedText(window, text.ready, 'center', 'center', 255, param.wrap);
DrawFormattedText(window, text.space_doneTMS,'center', spaceY, 255);
Screen('Flip',window);
WaitSecs(2);
%% Trigger
while 1 %wait for someone to press 'space'
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(key.space)
        Screen('Flip', window);
        runStart = GetSecs; %experiment start time.
        break
    end
end
Screen('Flip', window);
cd(behavdir)
%% Rating Screens
for xx=1:param.trials_per_run
% for xx=1:2 % debug
    trial.start = GetSecs;
    output.trial_onset(xx) = GetSecs - runStart;
    output.trial(xx) = xx;
   
    %trial info
    trial.text = output.stim_text(xx); % Read Text.
    % present statement
    Screen('TextSize', window, param.big);
    DrawFormattedText(window, char(trial.text), 'center', textY, 255, param.wrap); % put text 1/3 up screen
    DrawFormattedText(window, text.space_advance,'center', spaceY, 255);
    Screen('Flip',window, 0, 1);   
    WaitSecs(.5);
    
    while GetSecs - trial.start < param.max_trial_len
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyIsDown == 1 && keyCode(key.space) 
            output.read_RT(xx) = GetSecs - trial.start;
            break
        end
    end

    % positions
    squareX1 = xCenter;
    squareX2 = xCenter;
    squareX3 = xCenter;
    squareY1 = yCenter;
    squareY2 = yCenter*1.2;
    squareY3 = yCenter*1.4;

    squareSelect = 1; % 1 = Fact, 2 = Preference, 3 = Moral
    trial.ratestart = GetSecs;
    yy = 1; % dynamicoutput row marker
    while squareSelect < 4 && GetSecs - trial.start < param.max_trial_len
        % Check the keyboard to see if a button has been pressed
        [keyIsDown,secs, keyCode] = KbCheck;

        Screen('TextSize', window, param.small);

        %this draws the text
        Screen('TextSize', window, param.big);
        DrawFormattedText(window, char(trial.text), 'center', textY, 255, param.wrap); 
        DrawFormattedText(window, text.rating, 'center', rateY, 255, param.wrap);
        DrawFormattedText(window, text.scale, 'centerblock', scaleY, 255);
        % ratings
        DrawFormattedText(window, text.rate1, screenXpixels*(1/14), squareY1, 255);
        DrawFormattedText(window, text.rate2, screenXpixels*(1/14), squareY2, 255);
        DrawFormattedText(window, text.rate3, screenXpixels*(1/14), squareY3, 255);
        % confirm
        DrawFormattedText(window, text.space_confirm,'center', spaceY, 255);

        % We set bounds to make sure our square stays within rating line
        if squareX1 < screenXpixels*(1/3)
            squareX1 = screenXpixels*(1/3);
        elseif squareX1 > screenXpixels*(2/3)
            squareX1 = screenXpixels*(2/3);
        end

        if squareX2 < screenXpixels*(1/3)
            squareX2 = screenXpixels*(1/3);
        elseif squareX2 > screenXpixels*(2/3)
            squareX2 = screenXpixels*(2/3);
        end

        if squareX3 < screenXpixels*(1/3)
            squareX3 = screenXpixels*(1/3);
        elseif squareX3 > screenXpixels*(2/3)
            squareX3 = screenXpixels*(2/3);
        end

        %this draws the line
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY1, screenXpixels*(2/3), squareY1, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY1+10, screenXpixels*(1/3), squareY1-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY1+10, screenXpixels*(2/3), squareY1-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY1+10, screenXpixels*(1/2), squareY1-10, 5);

        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY2, screenXpixels*(2/3), squareY2, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY2+10, screenXpixels*(1/3), squareY2-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY2+10, screenXpixels*(2/3), squareY2-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY2+10, screenXpixels*(1/2), squareY2-10, 5);

        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY3, screenXpixels*(2/3), squareY3, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY3+10, screenXpixels*(1/3), squareY3-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY3+10, screenXpixels*(2/3), squareY3-10, 5);
        Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY3+10, screenXpixels*(1/2), squareY3-10, 5);

       % This draws the cursor
        centeredRectF = CenterRectOnPointd(baseRect, squareX1, squareY1);
        centeredRectP = CenterRectOnPointd(baseRect, squareX2, squareY2);
        centeredRectM = CenterRectOnPointd(baseRect, squareX3, squareY3);

        % select answer
        if squareSelect == 1
            Screen('FillRect', window, 127.5, centeredRectF);
            Screen('FillRect', window, 255, centeredRectP);
            Screen('FillRect', window, 255, centeredRectM);
        elseif squareSelect == 2
            Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY1 - 20, screenXpixels*(2/3)+20, squareY1 + 20], 5); 
            Screen('FillRect', window, 255, centeredRectF);
            Screen('FillRect', window, 127.5, centeredRectP);
            Screen('FillRect', window, 255, centeredRectM);
        elseif squareSelect == 3
            Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY1 - 20, screenXpixels*(2/3)+20, squareY1 + 20], 5); 
            Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY2 - 20, screenXpixels*(2/3)+20, squareY2 + 20], 5);     
            Screen('FillRect', window, 255, centeredRectF);
            Screen('FillRect', window, 255, centeredRectP);
            Screen('FillRect', window, 127.5, centeredRectM);
        end
        Screen('Flip', window);
        
        % Depending on the button press, move ths position of the square
%         if keyCode(key.down)
%             squareSelect = squareSelect + 1;
%             WaitSecs(.2);
%             if squareSelect > 3 % go no higher than 3 (moral)
%                 squareSelect = 3;
%             end
%         elseif keyCode(key.up)
%             squareSelect = squareSelect - 1;
%             WaitSecs(.2);
%             if squareSelect < 1 % go no lower than 1 (fact)
%                 squareSelect = 1;
%             end
         if keyCode(key.left)
            if squareSelect == 1
                squareX1 = squareX1 - pixelsPerPress;
                output.resp1_RT(xx) = GetSecs - trial.ratestart;
                dynamicoutput.cat(yy,xx) = design.q_order(squareSelect);
                dynamicoutput.resp(yy,xx) = (squareX1-screenXpixels*(1/3))/screen_range*100;
                dynamicoutput.time(yy,xx) = GetSecs - trial.ratestart;
                yy = yy+1;
            elseif squareSelect == 2
                squareX2 = squareX2 - pixelsPerPress;
                output.resp2_RT(xx) = GetSecs - trial.ratestart;
                dynamicoutput.cat(yy,xx) = design.q_order(squareSelect);
                dynamicoutput.resp(yy,xx) = (squareX2-screenXpixels*(1/3))/screen_range*100;
                dynamicoutput.time(yy,xx) = GetSecs - trial.ratestart;
                yy = yy+1;
            elseif squareSelect == 3
                squareX3 = squareX3 - pixelsPerPress;
                output.resp3_RT(xx) = GetSecs - trial.ratestart;
                dynamicoutput.cat(yy,xx) = design.q_order(squareSelect);
                dynamicoutput.resp(yy,xx) = (squareX3-screenXpixels*(1/3))/screen_range*100;
                dynamicoutput.time(yy,xx) = GetSecs - trial.ratestart;
                yy = yy+1;
            end
         elseif keyCode(key.right)
            if squareSelect == 1
                squareX1 = squareX1 + pixelsPerPress;
                output.resp1_RT(xx) = GetSecs - trial.ratestart;
                dynamicoutput.cat(yy,xx) = design.q_order(squareSelect);
                dynamicoutput.resp(yy,xx) = (squareX1-screenXpixels*(1/3))/screen_range*100;
                dynamicoutput.time(yy,xx) = GetSecs - trial.ratestart;
                yy = yy+1;
            elseif squareSelect == 2
                squareX2 = squareX2 + pixelsPerPress;
                output.resp2_RT(xx) = GetSecs - trial.ratestart;
                dynamicoutput.cat(yy,xx) = design.q_order(squareSelect);
                dynamicoutput.resp(yy,xx) = (squareX2-screenXpixels*(1/3))/screen_range*100;
                dynamicoutput.time(yy,xx) = GetSecs - trial.ratestart;
                yy = yy+1;
            elseif squareSelect == 3
                squareX3 = squareX3 + pixelsPerPress;
                output.resp3_RT(xx) = GetSecs - trial.ratestart;
                dynamicoutput.cat(yy,xx) = design.q_order(squareSelect);
                dynamicoutput.resp(yy,xx) = (squareX3-screenXpixels*(1/3))/screen_range*100;
                dynamicoutput.time(yy,xx) = GetSecs - trial.ratestart;
                yy = yy+1;
            end
         elseif keyCode(key.space) && (GetSecs - trial.ratestart > .5)
            % text
            Screen('TextSize', window, param.big);
            DrawFormattedText(window, char(trial.text), 'center', textY, 255, param.wrap); % put text 1/3 up screen
            DrawFormattedText(window, text.rating, 'center', rateY, 255, param.wrap);
            DrawFormattedText(window, text.scale, 'centerblock', scaleY, 255);
            DrawFormattedText(window, text.space_confirm,'center', spaceY, 255);
            % ratings
            DrawFormattedText(window, text.rate1, screenXpixels*(1/14), squareY1, 255);
            DrawFormattedText(window, text.rate2, screenXpixels*(1/14), squareY2, 255);
            DrawFormattedText(window, text.rate3, screenXpixels*(1/14), squareY3, 255);
            % lines
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY1, screenXpixels*(2/3), squareY1, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY1+10, screenXpixels*(1/3), squareY1-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY1+10, screenXpixels*(2/3), squareY1-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY1+10, screenXpixels*(1/2), squareY1-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY2, screenXpixels*(2/3), squareY2, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY2+10, screenXpixels*(1/3), squareY2-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY2+10, screenXpixels*(2/3), squareY2-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY2+10, screenXpixels*(1/2), squareY2-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY3, screenXpixels*(2/3), squareY3, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY3+10, screenXpixels*(1/3), squareY3-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY3+10, screenXpixels*(2/3), squareY3-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY3+10, screenXpixels*(1/2), squareY3-10, 5);
            % cursor
            centeredRectF = CenterRectOnPointd(baseRect, squareX1, squareY1);
            centeredRectP = CenterRectOnPointd(baseRect, squareX2, squareY2);
            centeredRectM = CenterRectOnPointd(baseRect, squareX3, squareY3);
            Screen('FillRect', window, 255, centeredRectF);
            Screen('FillRect', window, 255, centeredRectP);
            Screen('FillRect', window, 255, centeredRectM);
            % draw confirmation border
            if squareSelect == 1
                Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY1 - 20, screenXpixels*(2/3)+20, squareY1 + 20], 5); 
                output.resp1(xx) = (squareX1-screenXpixels*(1/3))/screen_range*100;
                Screen('Flip', window);            
            elseif squareSelect == 2
                Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY1 - 20, screenXpixels*(2/3)+20, squareY1 + 20], 5); 
                Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY2 - 20, screenXpixels*(2/3)+20, squareY2 + 20], 5); 
                output.resp2(xx) = (squareX2-screenXpixels*(1/3))/screen_range*100;
                Screen('Flip', window);  
            elseif squareSelect == 3
                Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY1 - 20, screenXpixels*(2/3)+20, squareY1 + 20], 5); 
                Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY2 - 20, screenXpixels*(2/3)+20, squareY2 + 20], 5); 
                Screen('FrameRect', window, 255, [screenXpixels*(1/3)-20, squareY3 - 20, screenXpixels*(2/3)+20, squareY3 + 20], 5); 
                output.resp3(xx) = (squareX3-screenXpixels*(1/3))/screen_range*100;
                output.respAll_RT(xx) = GetSecs - trial.ratestart;
                Screen('Flip', window);  
            end
            % get output
            WaitSecs(.25);
            squareSelect = squareSelect + 1;
         end
    end           
    
    
    if isnan(output.respAll_RT(xx))
        Screen('Flip', window);
        DrawFormattedText(window, text.timeout,'center', yCenter, 255);
        Screen('Flip', window);
        pause(1);
    end
    
    Screen('Flip',window);
    Screen('Flip',window);
    save(['data_sub-' sprintf('%02d', subjID) '_run-' num2str(acq) '_task-FPMTMS_' 'date-' param.time_date '.mat'],'acq','subjID', 'output', 'design')
end
% save .mat
runDur = GetSecs - runStart;
save(['data_sub-' sprintf('%02d', subjID) '_run-' num2str(acq) '_task-FPMTMS_' 'date-' param.time_date '.mat'],'acq','subjID', 'output', 'dynamicoutput', 'design', 'runDur')
% save .csv
output_table = struct2table(output);
cd(outputdir)
writetable(output_table, ['data_sub-' sprintf('%02d', subjID) '_run-' num2str(acq) '_task-FPMTMS_' 'date-' param.time_date '.tsv'], 'FileType', 'text', 'Delimiter', '\t');

output_table = struct2table(dynamicoutput);
cd(outputdir)
writetable(output_table, ['DYNAMICdata_sub-' sprintf('%02d', subjID) '_run-' num2str(acq) '_task-FPMTMS_' 'date-' param.time_date '.tsv'], 'FileType', 'text', 'Delimiter', '\t');

cd(rootdir)

sca
end