%     Condition                           Movies
% 1 - Neutral One -                       1-4
% 2 - Neutral Two -                       5-8
% 3 - Negative High -                     9-12
% 4 - Negative Low -                      13-16
% 5 - Positive High -                     17-20
% 6 - Positive Low -                      21-24

% gstreamer must be installed.
% must have psychtoolbox.
function TVTask_scanner(subjID, acq)
Screen('Preference', 'SkipSyncTests', 1); 
Screen('Preference','VisualDebugLevel', 0);
Screen('Preference','Verbosity', 0);
rng('shuffle')
%PsychImaging('PrepareConfiguration');
%PsychImaging('AddTask', 'General', 'UseRetinaResolution');

%% Parameters

% rootdir =  '/Users/arba/Desktop/TaskFiles/TVTask_scanner';
rootdir =   '~/Desktop/TaskFiles/TVTask_scanner';
behavdir = fullfile(rootdir, 'Behavioral');
stimdir = fullfile(rootdir, 'Stimuli');
wrap = 65; %new line after this many characters
big = 40; %big font size
medium = 32;
small = 24; %font size for ratings
TR = 2.5;
trials_per_run=12;
min_trial_length = 20;
max_trial_length = 60;
rating_time = 6;
max_run_length = 420+2*rating_time; %run will stop at 7 minutes, plus 12 seconds for initial ratings.

%% PTB Stuff
devices = PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard')==4);

% Switch KbName into unified mode: 
KbName('UnifyKeyNames');
key.leftKey = KbName('1!');
key.rightKey = KbName('2@');
key.submit = KbName('4$');


HideCursor; 
displays = Screen('screens');
screenRect = Screen('rect', displays(end));
window = Screen('OpenWindow', displays(end), [0 0 0], screenRect, 32);%identifies the screen we will be drawing to
%% Setup for valence/arousal ratings
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
pixelsPerPress = ((screenXpixels*(2/3))-(screenXpixels*(1/3)))/100; % Set the amount we want our square to move on each button press
rectColor = 255;
baseRect = [0 0 screenYpixels*0.02 screenYpixels*0.02];
[xCenter, yCenter] = RectCenter(screenRect); %sets center for screenRect(x,y)
%% Load Design, or Setup movie files.
% Return full list of movie files from directory+pattern:
cd(behavdir)
try
    load([subjID, '.TV.design.mat']);
    cd (stimdir);
    load('stim_legend.mat'); %loads stimuli_index
catch
    cd (stimdir);
    load('stim_legend.mat'); %loads stimuli_index

    moviefiles=dir('*.mp4');
    for i=1:size(moviefiles,1)
        moviefiles(i).name = [ pwd filesep moviefiles(i).name ];
    end

    %Shuffle Movie Order
    design = repmat(Shuffle(1:6),4,1);
    items = zeros(4,6);

    items(find(design == 6))   = 21;
    items(find(design == 5))   = 17;
    items(find(design == 4))   = 13;
    items(find(design == 3))   = 9;
    items(find(design == 2))   = 5;
    items(find(design == 1))   = 1;

    items(2,:) = items(2,:)+1;
    items(3,:) = items(3,:)+2;
    items(4,:) = items(4,:)+3;

    order1 = Shuffle([1 2]);
    order2 = Shuffle([3 4]);
    design = [design(order1(1), :), design(order2(1), :), design(order1(2), :), design(order2(2), :)];
    items = [items(order1(1), :), items(order2(1), :), items(order1(2), :), items(order2(2), :)];
    cd(behavdir);
    save([subjID, '.TV.design.mat'], 'moviefiles', 'design', 'items', 'order1', 'order2');
end

design_run = design(((1+(acq-1)*trials_per_run)):(trials_per_run+(acq-1)*trials_per_run));
items_run = items(((1+(acq-1)*trials_per_run)):(trials_per_run+(acq-1)*trials_per_run));

%% Setup output
output.subjID = cell(trials_per_run+1,1); output.subjID(:,1) = {subjID};
output.acq = zeros(trials_per_run+1, 1);
output.trial = zeros(trials_per_run+1, 1);
output.movie_start = zeros(trials_per_run+1, 1);
output.movie_duration = zeros(trials_per_run+1, 1);
output.movie_resp = cell(trials_per_run+1, 1);
output.item = zeros(trials_per_run+1, 1);
output.condition = zeros(trials_per_run+1, 1);
output.condition_name = cell(trials_per_run+1, 1);
output.video = cell(trials_per_run+1, 1);
output.val_RT = nan(trials_per_run+1, 1);
output.val_resp = nan(trials_per_run+1, 1);
output.val_onset = nan(trials_per_run+1, 1);
output.val_buttondown = cell(trials_per_run+1, 1);
output.val_submit = cell(trials_per_run+1, 1); 
output.val_submitRT = nan(trials_per_run+1, 1);
output.aro_RT = nan(trials_per_run+1, 1);
output.aro_resp = nan(trials_per_run+1, 1);
output.aro_onset = nan(trials_per_run+1,1);
output.aro_buttondown = cell(trials_per_run+1, 1);
output.aro_submit = cell(trials_per_run+1, 1);
output.aro_submitRT = nan(trials_per_run+1, 1);
%% Instructions and Text
affect_text = 'How UNPLEASANT or PLEASANT do you feel?';
%affect_anchors =  'Very Negative                              Neutral                                   Very Positive';
affect_anchors =  'Very Unpleasant              Neutral                  Very Pleasant';
arousal_text =    'How ACTIVATED do you feel?';
%arousal_anchors = 'Very non-activated/Sleepy                Neutral                          Very activated/Excited';
arousal_anchors = '  Most activated               Neutral                  Least activated';
         

Screen(window, 'TextSize', big);
DrawFormattedText(window, 'Now you will watch videos on TV just like you would at home.', 'center', 'center', 255, wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, ['There are 6 different TV channels. \n\n\nA TV channel will preview for several seconds.'...
    '\n\n\nThen an arrow will appear at the bottom of the screen.'...
    '\n\n\nYou can change the channel at any point after the arrow appears.'...
    '\n\n\nYou can also continue to watch the channel as long as you want.'], 'center', 'center', 255, wrap); 
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'To change the channel, press the button with your POINTER FINGER. \n\n\nThe channel might also change automatically.', 'center', 'center', 255, wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, ['After a channel changes, you will be asked to rate how ACTIVATED you feel.'...
    '\n\n\nThe MORE ACTIVATED you feel, the more you may feel jittery or awake.'...
    '\n\n\nThe LESS ACTIVATED you feel, the more you may feel quiet and still.'], 'center', 'center', 255, wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Then you will rate how UNPLEASANT or PLEASANT you feel.', 'center', 'center', 255, wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, ['You will rate your feelings on a sliding scale.'... 
    '\n\n\nTo move the slider left and right, use your POINTER and MIDDLE fingers.'...
    '\n\n\nUse your PINKY finger to "lock in" your rating. \n\n\nYou will have 6 seconds to make each rating.'], 'center', 'center', 255, wrap); 
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Please ask the experimenter if you have any questions.', 'center', 'center', 255, wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Ready to begin?', 'center', 'center', 255, wrap);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Waiting for scanner', 'center', 'center', 255, wrap);
Screen('Flip', window);
%% Give control to subject.
devices = PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard')==1);

% Switch KbName into unified mode: 
KbName('UnifyKeyNames');
key.leftKey = KbName('1!');
key.rightKey = KbName('2@');
key.submit = KbName('4$');

%% Trigger
while 1 %wait for the 1st trigger pulse
    FlushEvents;
    trig = GetChar;
    if trig == '='
        t1 = GetSecs; %experiment start time.
        break
    end
end

Screen('Flip', window);

%% First valence/arousal ratings
output.trial(1) = 0;

 %% First Arousal Rating
inst_text = arousal_text;
anchor_text = arousal_anchors;

rating_start = GetSecs;
screen_range = (screenXpixels*(2/3)-screenXpixels*(1/3));

squareX = xCenter;
squareY = yCenter*1.25;
output.aro_onset(1) = GetSecs - t1;

while GetSecs - rating_start <= rating_time
    % Check the keyboard to see if a button has been pressed
    [keyIsDown,secs, keyCode] = KbCheck;

     %get reaction time of first button press. Will stop recording after
     %button is pressed
     if keyIsDown == 1 && (keyCode(key.leftKey) || keyCode(key.rightKey) || keyCode(key.submit))
         output.aro_RT(1) = GetSecs - rating_start;
     end

    centeredRect = CenterRectOnPointd(baseRect, squareX, squareY);

    Screen(window, 'TextSize', medium);
    DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
    Screen(window, 'TextSize', small);
    DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
    DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
    Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
    Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
    Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
    Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
%   % We set bounds to make sure our square stays within rating line
    if squareX < screenXpixels*(1/3)
        squareX = screenXpixels*(1/3);
    elseif squareX > screenXpixels*(2/3)
        squareX = screenXpixels*(2/3);
    end

    Screen('FillRect', window, rectColor, centeredRect);
    Screen('Flip', window);
    
    % Depending on the button press, move ths position of the square
     if keyCode(key.leftKey)
         squareX = squareX - pixelsPerPress;
     elseif keyCode(key.rightKey)
         squareX = squareX + pixelsPerPress;
     elseif keyCode(key.submit)
         squareX = squareX + 0;
         Screen(window, 'TextSize', medium);
         DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
         Screen(window, 'TextSize', small);
         DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
         DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
         Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
         Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
         Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
         Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
         Screen('FillRect', window, 127.5, centeredRect);
         Screen('Flip', window);
         output.aro_submitRT(1) = GetSecs-rating_start;
         output.aro_resp(1) = (squareX-screenXpixels*(1/3))/((screenXpixels*(2/3)-screenXpixels*(1/3)))*100;
         WaitSecs(rating_time - (GetSecs-rating_start));
         output.aro_submit{1} = 'yes';
     end
     

      if (round(GetSecs - rating_start, 2) == rating_time) && keyIsDown == 1
          output.aro_buttondown{1} = 'yes';
      end
end
%% First Valence Rating
 
 inst_text = affect_text;
 anchor_text = affect_anchors;

 
 rating_start = GetSecs;
 screen_range = (screenXpixels*(2/3)-screenXpixels*(1/3));

 squareX = xCenter;
 squareY = yCenter*1.25;
 output.val_onset(1) = GetSecs - t1;

 while GetSecs - rating_start <= rating_time
     % Check the keyboard to see if a button has been pressed
     [keyIsDown,secs, keyCode] = KbCheck;
     centeredRect = CenterRectOnPointd(baseRect, squareX, squareY);
     Screen('TextSize', window, small);

     %get reaction time of first button press. Will stop recording after
     %button is pressed
     if keyIsDown == 1 && (keyCode(key.leftKey) || keyCode(key.rightKey) || keyCode(key.submit))
         output.val_RT(1) = GetSecs - rating_start;
     end
             
    %this draws the line
    Screen(window, 'TextSize', medium);
    DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
    Screen(window, 'TextSize', small);
    DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
    DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
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
     if keyCode(key.leftKey)
         squareX = squareX - pixelsPerPress;
     elseif keyCode(key.rightKey)
         squareX = squareX + pixelsPerPress;
     elseif keyCode(key.submit)
         squareX = squareX + 0;
         Screen(window, 'TextSize', medium);
         DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
         Screen(window, 'TextSize', small);
         DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
         output.val_resp(1) = (squareX-screenXpixels*(1/3))/screen_range*100;
         DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
         Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
         Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
         Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
         Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
         Screen('FillRect', window, 127.5, centeredRect);
         Screen('Flip', window);
         output.val_submitRT(1) = GetSecs-rating_start;
         WaitSecs(rating_time - (GetSecs-rating_start)); 
         output.val_submit{1} = 'yes';
     end
     
      if (round(GetSecs - rating_start, 2) == rating_time) && keyIsDown == 1
          output.val_buttondown{1} = 'yes';
      end
     
 end

%% Main Experiment
AssertOpenGL; % Child protection
% Endless loop, runs until ESC key pressed:
for trial=1:trials_per_run
    output.trial(trial+1) = trial;
    output.acq(trial+1) = acq;
    stopmovie = 0;
    while stopmovie == 0
        if (mod(round(GetSecs - t1, 3), TR) == 0) %Wait to start each trial until the start of a TR. Accurate at 1 ms.
            response_start = GetSecs; %start of each trial.
            output.item(trial+1) = items_run(trial);
            output.condition(trial+1) = design_run(trial);

            %Find trial in stimuli_index
            movie_index = find(cell2mat(stimuli_index(:,1)) == items_run(trial));
            moviename = stimuli_index(movie_index,2);
            output.video{trial+1} = moviename{1}; %TODO, movie needs to not be an embdedded cell.

            moviefile=moviefiles(movie_index).name;
            Screen('Flip', window);

            % Open movie file and retrieve basic info about movie:
            [movie movieduration fps imgw imgh] = Screen('OpenMovie', window, moviefile);
                    % Seek to start of movies (timeindex 0):
            Screen('SetMovieTimeIndex', movie, GetSecs-response_start);
            rate=1; %movie play rate. Could speed up. 1 is normal rate.

            % Start playback of movies. This will start
            % the realtime playback clock and playback of audio tracks, if any.
            % Play 'movie', at a playbackrate = 1, with endless loop=1 and
            % 1.0 == 100% audio volume.
            Screen('PlayMovie', movie, rate, 1, 1.0);

            % Fetch video frames and display them...
            % Time is longer than allowable in conditionals below, so
            % should be fine.
            while((GetSecs-response_start)<max_trial_length)
                %default RT is NaN
                output.movie_duration(trial+1) = nan;
                if (abs(rate)>0)
                    % Return next frame in movie, in sync with current playback
                    % time and sound.
                    % tex either the texture handle or zero if no new frame is
                    % ready yet.
                    tex = Screen('GetMovieImage', window, movie, 0);

                    % Valid texture returned?
                    if tex > 0
                        % Draw the new texture immediately to screen:
                        Screen('DrawTexture', window, tex, []);
                        % Release texture:
                        Screen('Close', tex);
                    end

                    % Update display if there is anything to update:
                    if (tex > 0)
                        % We use clearmode=1, aka don't clear on flip. This is
                        % needed to avoid flicker...
                        Screen('Flip', window, 0, 1);
                    else
                        % Sleep a bit before next poll...
                        WaitSecs('YieldSecs', 0.001);
                    end
                end

                % Get keypress
                [keyIsDown,secs,keyCode]=KbCheck; 

                %if button is pressed (after 20 seconds) then the channel will
                %change, the screen will flip, and the movie will stop.
                if (keyIsDown==1 && keyCode(key.leftKey)  && (floor(GetSecs - response_start) > min_trial_length))
                    output.movie_duration(trial+1) = GetSecs - response_start;
                    output.movie_resp{trial+1} = 'next';
                    Screen('Flip', window);
                    Screen('Flip', window);
                    Screen('PlayMovie', movie, 0);
                    Screen('CloseMovie', movie);
                    stopmovie = 1;
                    break
                %break if we run out of time in the run, but collect
                %ratings below.
                elseif ((GetSecs-t1)>max_run_length)
                    output.movie_duration(trial+1) = GetSecs - response_start;
                    output.movie_resp{trial+1} = 'run_over';
                    Screen('Flip', window);
                    Screen('Flip', window);
                    Screen('PlayMovie', movie, 0);
                    Screen('CloseMovie', movie);
                    stopmovie = 1;
                    break
                %break if we run over the max trial length.
                % slightly shorter (10ms) to make sure the while loop
                % doesn't break first.
                elseif ((GetSecs-response_start)>=(max_trial_length-.01))
                    output.movie_duration(trial+1) = GetSecs - response_start;
                    output.movie_resp{trial+1} = 'trial_over';
                    Screen('Flip', window);
                    Screen('Flip', window);
                    Screen('PlayMovie', movie, 0);
                    Screen('CloseMovie', movie);
                    stopmovie = 1;
                    break
                end
            end
        end
    end

    
    %% Start Arousal Rating
        inst_text = arousal_text;
        anchor_text = arousal_anchors;

        output.aro_resp(trial+1) = nan;
        output.aro_RT(trial+1) = nan;
        output.aro_buttondown{trial+1} = 'no';

        rating_start = GetSecs;
        screen_range = (screenXpixels*(2/3)-screenXpixels*(1/3));
        
        squareX = xCenter;
        squareY = yCenter*1.25;
        output.aro_onset(trial+1) = GetSecs - t1;

        while GetSecs - rating_start <= rating_time
            % Check the keyboard to see if a button has been pressed
            [keyIsDown,secs, keyCode] = KbCheck;

            

             %get reaction time of first button press. Will stop recording after
             %button is pressed
             if keyIsDown == 1 && (keyCode(key.leftKey) || keyCode(key.rightKey) || keyCode(key.submit))
                 output.aro_RT(trial+1) = GetSecs - rating_start;
             end

            centeredRect = CenterRectOnPointd(baseRect, squareX, squareY);
            
            Screen(window, 'TextSize', medium);
            DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
            Screen(window, 'TextSize', small);
            DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
            DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
        %   % We set bounds to make sure our square stays within rating line
            if squareX < screenXpixels*(1/3)
                squareX = screenXpixels*(1/3);
            elseif squareX > screenXpixels*(2/3)
                squareX = screenXpixels*(2/3);
            end

            Screen('FillRect', window, rectColor, centeredRect);
            Screen('Flip', window);
            
            % Depending on the button press, move ths position of the square
             if keyCode(key.leftKey)
                 squareX = squareX - pixelsPerPress;
             elseif keyCode(key.rightKey)
                 squareX = squareX + pixelsPerPress;
             elseif keyCode(key.submit)
                 squareX = squareX + 0;
                 Screen(window, 'TextSize', medium);
                 DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
                 Screen(window, 'TextSize', small);
                 DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
                DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
                 Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
                 Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
                 Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
                 Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
                 Screen('FillRect', window, 127.5, centeredRect);
                 Screen('Flip', window);
                 output.aro_submitRT(trial+1) = GetSecs-rating_start;
                 output.aro_resp(trial+1) = (squareX-screenXpixels*(1/3))/((screenXpixels*(2/3)-screenXpixels*(1/3)))*100;
                 WaitSecs(rating_time - (GetSecs-rating_start));
                 output.aro_submit{trial+1} = 'yes';
             end
             
            if (round(GetSecs - rating_start, 2) == rating_time) && keyIsDown == 1
                output.aro_buttondown{trial+1} = 'yes';
            end
        end
        
%% Start Valence Rating
        inst_text = affect_text;
        anchor_text = affect_anchors;

        output.val_resp(trial+1) = nan;
        output.val_RT(trial+1) = nan;
        output.val_buttondown{trial+1} = 'no';

        rating_start = GetSecs;
        screen_range = (screenXpixels*(2/3)-screenXpixels*(1/3));
        
        squareX = xCenter;
        squareY = yCenter*1.25;
        output.val_onset(trial+1) = GetSecs - t1;

        while GetSecs - rating_start <= rating_time
            % Check the keyboard to see if a button has been pressed
            [keyIsDown,secs, keyCode] = KbCheck;
            
            centeredRect = CenterRectOnPointd(baseRect, squareX, squareY);
            Screen('TextSize', window, small);

            
             %get reaction time of first button press. Will stop recording after
             %button is pressed
             if keyIsDown == 1 && (keyCode(key.leftKey) || keyCode(key.rightKey) || keyCode(key.submit))
                 output.val_RT(trial+1) = GetSecs - rating_start;
             end

            %this draws the line
            Screen(window, 'TextSize', medium);
            DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
            Screen(window, 'TextSize', small);
            DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
            DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
            Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
        %   % We set bounds to make sure our square stays within rating line
            if squareX < screenXpixels*(1/3)
                squareX = screenXpixels*(1/3);
            elseif squareX > screenXpixels*(2/3)
                squareX = screenXpixels*(2/3);
            end

           % This draws the cursor
            Screen('FillRect', window, rectColor, centeredRect);
           
            Screen('Flip', window);
            
            % Depending on the button press, move ths position of the square
             if keyCode(key.leftKey)
                 squareX = squareX - pixelsPerPress;
             elseif keyCode(key.rightKey)
                 squareX = squareX + pixelsPerPress;
             elseif keyCode(key.submit)
                 squareX = squareX + 0;
                 Screen(window, 'TextSize', medium);
                 DrawFormattedText(window, inst_text, 'center', squareY*.6, 255, wrap);
                 Screen(window, 'TextSize', small);
                 DrawFormattedText(window, anchor_text, 'centerblock', yCenter*1.1, 255);
                 DrawFormattedText(window, ' 0                               50                             100', 'centerblock', yCenter*1.2,  255);
                 Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY, screenXpixels*(2/3), squareY, 5);
                 Screen('DrawLine', window, 255, screenXpixels*(1/3), squareY+10, screenXpixels*(1/3), squareY-10, 5);
                 Screen('DrawLine', window, 255, screenXpixels*(2/3), squareY+10, screenXpixels*(2/3), squareY-10, 5);
                 Screen('DrawLine', window, 255, screenXpixels*(1/2), squareY+10, screenXpixels*(1/2), squareY-10, 5);
                 Screen('FillRect', window, 127.5, centeredRect);
                 Screen('Flip', window);
                 output.val_submitRT(trial+1) = GetSecs-rating_start;
                 output.val_resp(trial+1) = (squareX-screenXpixels*(1/3))/screen_range*100;
                 WaitSecs(rating_time - (GetSecs-rating_start));  
                 output.val_submit{trial+1} = 'yes';
             end


            if (round(GetSecs - rating_start, 2) == rating_time) && keyIsDown == 1
                output.val_buttondown{trial+1} = 'yes';
            end
        end



    output.movie_start(trial+1) = response_start - t1;

    cd(behavdir)
    save([subjID '.TV.' num2str(acq) '.mat'],'acq','subjID', 'output')
    
    if ((GetSecs-t1)>max_run_length)
        break
    end
end

experimentDur = GetSecs - t1;

output.condition_name(find(output.condition==1)) = {'Neutral_One'}; 
output.condition_name(find(output.condition==2)) = {'Neutral_Two'}; 
output.condition_name(find(output.condition==3)) = {'Neg_High'}; 
output.condition_name(find(output.condition==4)) = {'Neg_Low'}; 
output.condition_name(find(output.condition==5)) = {'Pos_High'}; 
output.condition_name(find(output.condition==6)) = {'Pos_Low'}; 

save([subjID '.TV.' num2str(acq) '.mat'],'acq','subjID', 'output', 'experimentDur')
output_table = struct2table(output);
writetable(output_table, [subjID '.TV.' num2str(acq) '.csv']);

while ((GetSecs-t1)<max_run_length+(2*rating_time))
    early_finish = 'Thank you for watching! The scan will end shortly.';
    Screen(window, 'TextSize', big);
    DrawFormattedText(window, early_finish, 'center', 'center', 255, wrap);
    Screen('Flip',window); 
end

% Close screens
sca;
ShowCursor;    % TODO Remove this when we know we can give input during scan.
end