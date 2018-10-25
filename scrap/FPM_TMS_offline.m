function FPM_TMS_offline(subjID, acq)
%% Description and Conditions

% Conditions:                                   Stories:
 % 0 - Preferences - Mid-Agree                     1-12
 % 1 - Preferences - High-Agree                    13-24
 % 2 - Morals - Mid-Agree                          25-36
 % 3 - Morals - High-Agree                         37-48   
 
 %To be run in 6 runs of 8.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %RUN AT 1280 x 800 RESOLUTION%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters

% rootdir = '/Experiments/FactPref';
rootdir = '/Users/Jordan/Copy/Work/Young Lab/My Work/Experiments/FPM_TMS/Code/offline';
behavDir  = fullfile(rootdir,'behavioural');
stimdir = fullfile(rootdir,'FPMstimuli');
wrap      = 55;%  new line after this many characters
big       = 22;%  big font size
small     = 22;%  small font size
trialtime = 12;%  seconds 

rand('twister', GetSecs);


%% Etiher Load First Run or Create First Run
cd(behavDir);

try % after first run, load the same sequence
    load([subjID '.FPMTMS.1.mat'],'design','items');
catch% first run
    
    % Conditions
    c_designs = [0 1 3 2;...
                 1 2 0 3;...
                 2 3 1 0;...
                 3 0 2 1];
    
    design = [];
    for ii=1:3
      order(1,:) = Shuffle(1:4);
        for i=1:4
            design = [design c_designs(order(1,i),:)]; 
        end
    end
    
    items = zeros(1,48);    
    items(find(design == 3))   = Shuffle(37:48);
    items(find(design == 2))   = Shuffle(25:36);
    items(find(design == 1))   = Shuffle(13:24);
    items(find(design == 0))   = Shuffle(1:12);
    %This is using the design array to feed in the relevant numbers into
    %the items matrix.
    
    save([subjID '.FPMTMS.' num2str(acq) '.mat'],'design','items');
end

%% Load Variables for Experiment

RT         = zeros(24,1); %So this looks like it does 10 runs to an output, 6 runs. Will make a separate output for each run.
key        = zeros(24,1);
items_run  =  items((acq*24)-23:acq*24); % 1:12, 13:24 ... %This is the set of items specifically for this run.
design_run = design((acq*24)-23:acq*24);
%%%
instructions = 'You will read several statements and will answer how much you think they are ABOUT FACTS.\n\n\n Use keys 1-7 to indicate your answer, with 1 indicating "Not at all" and 7 "Completely".\n\n\n Press <space> to begin.';
question = 'To what degree is this statement about facts?\n\n\n 1       2       3       4       5       6       7 \n Not at all                                 Completely';
%%%XX

%% PTB Stuff
% Identify attached keyboard devices:
LoadPsychHID
devices=PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard')==1);

HideCursor;
displays   = Screen('screens');
screenRect = Screen('rect', displays(end)); %
[x0,y0]    = RectCenter(screenRect); %sets Center for screenRect (x,y)
s          = Screen('OpenWindow', displays(end),[0 0 0], screenRect, 32);
% s Identifies the screen we will be drawing to.

%% Instructions and Trigger
Screen(s,'TextSize',big);

DrawFormattedText(s, instructions, 'center', 'center', 255,wrap);Screen('Flip',s);

while 1  % wait for the 1st trigger pulse
    FlushEvents;
    trig = GetChar;
    if trig == ' '
        break
    end
end
Screen('Flip',s);

%% Main Experiment
t0 = GetSecs; % used to time duration of experiment

pause(5) % Really this pause in only used just after the instructions. The pause is controlled in actual trials by trialtime.

for trial = 1:24
    trialStart = GetSecs;
    cd(stimdir);
    
     the_item = items_run(trial);
     storyname=sprintf('%s.txt',num2str(the_item));
     textfid = fopen(storyname);
     tline = fgetl(textfid);
%      
%     % present fact/preference
%     Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
%     
%     DrawFormattedText(s,the_item,'center',y0-250 , 255,wrap); Screen('Flip',s); pause(2);
%     
%     
      

    % present scenario
    Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
    DrawFormattedText(s,tline,'center','center' , 255,wrap);
    Screen('Flip',s); pause(6);
    
    
    % present question
    Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
    DrawFormattedText(s,question,'center','center' , 255,wrap);
    Screen('Flip',s); respond_start = GetSecs;
% %         %%TMS PULSE
% %            lptwrite(888,255);
% %            WaitSecs(0.001);
% %            lptwrite(888,0); %To decrease polling interval
% %         %%   
        % Collect responses using KbCheck to confirm they have read story
        while (GetSecs - respond_start) < 4
            [keyIsDown timeSecs keyCode] = KbCheck;
            [button number] = intersect(49:55, find(keyCode));
            if (RT(trial) == 0) & (number > 0)
                RT(trial) = GetSecs - respond_start;
                key(trial) = number;
            end
        end
        %Remove image from screen.
        Screen('Flip',s);
        
        while (GetSecs - respond_start) < 6
            [keyIsDown timeSecs keyCode] = KbCheck;
            [button number] = intersect(49:55, find(keyCode));
            if (RT(trial) == 0) & (number > 0)
                RT(trial) = GetSecs - respond_start;
                key(trial) = number;
            end
        end
        
        
    cd(behavDir);
    save([subjID '.FPMTMS.' num2str(acq) '.mat'],'RT','key','design','design_run','items','items_run','acq','subjID');
    
    %This is where the ISI pause is really happening. The one above the
    %loop only happens once.
    while GetSecs - trialStart < trialtime;end
    
end

experimentDur = GetSecs - t0;

cd(behavDir); save([subjID '.FPMTMS.' num2str(acq) '.mat'],'acq','RT','key','design','design_run','items','items_run', 'experimentDur','subjID');

ShowCursor; Screen('CloseAll');

cd(rootdir)
clear all;

%% Rai & Holyoak Measure
% 
% if postOrder==acq
%     
%     trial=1;
%     wrap      = 90;%  new line after this many characters
%     trialtime = 46;
%     
%     trialStart = GetSecs;
%     cd(stimdir);
%     story = 'Imagine that you are at the grocery store and saw an item that you regularly purchase but the price had clearly been mismarked. Instead of 4 dollars, it is listed as only costing 4 cents.';
%     questiontext1 = 'How willing would you be to go to the self-checkout lane and purchase the item for 4 cents, then leave the store?';
%     question1 = '1       2       3       4       5       6       7 \n Would never do this ever                    Totally and completely willing to do this';
%     questiontext2 = 'To what extent does your position on this story reflect your core moral beliefs and convictions?';
%     question2 = '1       2       3       4       5 \n Not at all                                 Very much';
%     questiontext3 = 'To what extent is your position on this story connected to your fundamental beliefs about right and wrong?';
%     question3 = '1       2       3       4       5 \n Not at all                                 Very much';
%     
%     Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
%     DrawFormattedText(s,story,'center',y0-250 , 255,wrap); 
%     Screen('Flip',s); pause(10);
%     
%     DrawFormattedText(s,[story '\n\n ' questiontext1],'center',y0-250 ,255,wrap); 
%     Screen('Flip',s); pause(6);
%     
%     DrawFormattedText(s,[story '\n\n ' questiontext1 '\n\n' question1],'center',y0-250 ,255,wrap); 
%     Screen('Flip',s); pause(4);    
%     respond_start = GetSecs;
%     
%         % Collect responses using KbCheck to answer question
%         while (GetSecs - respond_start) < 4
%             [keyIsDown timeSecs keyCode] = KbCheck;
%             [button number] = intersect(49:55, find(keyCode));
%             if (RT(trial) == 0) & (number > 0)
%                 RT(trial) = GetSecs - respond_start;
%                 key(trial) = number;
%             end
%         end
%         
%     % RE-present story
%     Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
%     DrawFormattedText(s,story,'center',y0-250 , 255,wrap); 
%     Screen('Flip',s); pause(2);
%         
%         while (GetSecs - respond_start) < 6
%             [keyIsDown timeSecs keyCode] = KbCheck;
%             [button number] = intersect(49:55, find(keyCode));
%             if (RT(trial) == 0) & (number > 0)
%                 RT(trial) = GetSecs - respond_start;
%                 key(trial) = number;
%             end
%         end
%         
%     trial=2;
%     % present next question
%     Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
%     DrawFormattedText(s,[story '\n\n ' questiontext2],'center',y0-250 ,255,wrap); 
%     Screen('Flip',s); pause(6);
%     
%     DrawFormattedText(s,[story '\n\n ' questiontext2 '\n\n' question2],'center',y0-250 ,255,wrap); 
%     Screen('Flip',s); pause(4); 
%     respond_start = GetSecs;
%     
%         % Collect responses using KbCheck to confirm they have read story
%         while (GetSecs - respond_start) < 4
%             [keyIsDown timeSecs keyCode] = KbCheck;
%             [button number] = intersect(49:53, find(keyCode));
%             if (RT(trial) == 0) & (number > 0)
%                 RT(trial) = GetSecs - respond_start;
%                 key(trial) = number;
%             end
%         end
%         
%     % RE-present story
%     Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
%     DrawFormattedText(s,story,'center',y0-250 , 255,wrap); 
%     Screen('Flip',s); pause(2);
%         
%         while (GetSecs - respond_start) < 6
%             [keyIsDown timeSecs keyCode] = KbCheck;
%             [button number] = intersect(49:53, find(keyCode));
%             if (RT(trial) == 0) & (number > 0)
%                 RT(trial) = GetSecs - respond_start;
%                 key(trial) = number;
%             end
%         end
%         
%     trial=3;
%     % present next question
%     Screen('FillRect',s,[0 0 0], screenRect);Screen(s,'TextSize',small);
%     DrawFormattedText(s,[story '\n\n ' questiontext3],'center',y0-250 ,255,wrap); 
%     Screen('Flip',s); pause(6);
%     
%     DrawFormattedText(s,[story '\n\n ' questiontext3 '\n\n' question3],'center',y0-250 ,255,wrap); 
%     Screen('Flip',s);    
%     respond_start = GetSecs;
%     
%         % Collect responses using KbCheck to confirm they have read story
%         while (GetSecs - respond_start) < 4
%             [keyIsDown timeSecs keyCode] = KbCheck;
%             [button number] = intersect(49:53, find(keyCode));
%             if (RT(trial) == 0) & (number > 0)
%                 RT(trial) = GetSecs - respond_start;
%                 key(trial) = number;
%             end
%         end
%         %Remove image from screen.
%         Screen('Flip',s);
%         
%         while (GetSecs - respond_start) < 6
%             [keyIsDown timeSecs keyCode] = KbCheck;
%             [button number] = intersect(49:53, find(keyCode));
%             if (RT(trial) == 0) & (number > 0)
%                 RT(trial) = GetSecs - respond_start;
%                 key(trial) = number;
%             end
%         end
%     
%     while GetSecs - trialStart < trialtime;end
%     
% else
%     
% end
%     
% clear all;
end % main function


