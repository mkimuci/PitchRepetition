% Clear workspace and close figures
close all; clear; sca;

% Check OS for file management
disp('Checking os...')
if ismac
    Screen('Preference', 'SkipSyncTests', 1);
    paths.slashChar = '/';
elseif ispc
    paths.slashChar = '\';
end

% Experiment parameters
Instructions = 'Instructions';  % Update with real instructions
InstructionWaitTime = 5;  % Display duration for instructions (seconds)
countdown = 3;  % Countdown before experiment starts

% Define number of trials for each trial type
numTrialsType0 = 8; 
numTrialsType1 = 8; 
numTrialsType2 = 8; 
numTrialsType3 = 8; 
numTrialsType4 = 8; 
numTrials = numTrialsType0 + numTrialsType1 + numTrialsType2 + ...
            numTrialsType3 + numTrialsType4; % Total number of trials

% Navigate to script directory
cd(fileparts(which('RoP.m')));

% Directory of audio/visual stimu
stimuliDir = './stimuli/';
imgDir = [stimuliDir 'visual/'];
audioDir = [stimuliDir 'audio/'];

% Load task images
[rest, ~, ~] = imread([imgDir '1.png']);
[listen, ~, ~] = imread([imgDir '2.png']);
[repeat, ~, ~] = imread([imgDir '3.png']);
[hum, ~, ~] = imread([imgDir '4.png']);
[mic, ~, alpha] = imread([imgDir 'mic.png']);

% Setup Psychtoolbox
PsychDefaultSetup(2);
rng('shuffle');  % Shuffle random numbers
screenNumber = max(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Full window
% [window, ~] = PsychImaging('OpenWindow', screenNumber, black);

% Debugging Window
winRect = [100, 100, 900, 700];
[window, ~] = PsychImaging('OpenWindow', screenNumber, 0, winRect);

Screen('Flip', window);
Screen('TextSize', window, 60);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Get participant's ID
prompt = 'Please enter participant ID:';
participantID = GetEchoStringFreeResponse(window, prompt, 0, 20, ...
                                          [255 255 255], [0 0 0]);

% Display instructions & countdown
DrawFormattedText(window, Instructions, 'center', 'center', white);
Screen('flip', window);
WaitSecs(InstructionWaitTime);

for ii = 1:countdown
    timerMsg = sprintf('The experiment\nwill begin in:\n\n%d', ...
                       countdown-ii+1);
    DrawFormattedText(window, timerMsg, 'center', 'center', white);
    Screen('flip', window);
    WaitSecs(1);
end
Screen('flip', window);
WaitSecs(2);

% Load audio stimuli
wavFiles = dir([audioDir '*.wav']);
numFiles = length(wavFiles);

for ii = 1:numFiles
    path2file = fullfile(audioDir, wavFiles(ii).name);
    [sounds{ii}, freq{ii}] = audioread(path2file);
end
whiteNoise = audioread([stimuliDir 'white_noise.wav']);

% Randomly order trials
TrialType = [repelem(0, numTrialsType0), ...
             repelem(1, numTrialsType1), repelem(2, numTrialsType2), ...
             repelem(3, numTrialsType3), repelem(4, numTrialsType4)];
TrialTypeShuffled = TrialType(randperm(numTrials));

% Generate timestamp for filename
filenameTimestamp = datestr(now, 'yyyy-mm-dd_HHMMSS');
logFilename = sprintf("./logs/%s_log_%s.csv", ...
                      participantID, filenameTimestamp);

% Open CSV file for writing
CSVoutput = fopen(logFilename, 'w');
fprintf(CSVoutput, "TrialType, WAVFile, Timestamp, T1, T2\n");

% Record start time of the experiment
experimentStartTime = tic;

% Main experiment loop
for ii = 1:numTrials
    randSound = randi([1 numFiles]);
    T1 = rand(1) * (1 - 0) + 0; % Uniform[0, 1] seconds
    T2 = rand(1) * (5 - 3) + 3; % Uniform[3, 5] seconds
    
    % Select the icon and play the sound based on the trial type
    switch TrialTypeShuffled(ii)
        case 0
            icon = rest;
            sound(whiteNoise);
            wavFileName = 'white_noise.wav';
        case 1
            icon = listen;
            sound(sounds{randSound}, freq{randSound});
            wavFileName = wavFiles(randSound).name;
        case 2
            icon = listen;
            sound(sounds{randSound}, freq{randSound});
            wavFileName = wavFiles(randSound).name;
        case 3
            icon = repeat;
            sound(sounds{randSound}, freq{randSound});
            wavFileName = wavFiles(randSound).name;
        case 4
            icon = hum;
            sound(sounds{randSound}, freq{randSound});
            wavFileName = wavFiles(randSound).name;
    end

    iconTexture = Screen('MakeTexture', window, icon);
    Screen('DrawTexture', window, iconTexture);
    Screen('Flip', window);
    WaitSecs(3+T1); % Wait for T1 seconds with the trial type image displayed

    % After T1, display "mic.png"
    mic(:,:,4) = alpha; % Add alpha channel for transparency
    micTexture = Screen('MakeTexture', window, mic);
    Screen('DrawTexture', window, micTexture);
    Screen('Flip', window);
    WaitSecs(3); % Display "mic.png" for 3 seconds

    % Display fixation cross
    DrawFormattedText(window, '+', 'center', 'center', white);
    Screen('Flip', window);
    WaitSecs(T2); % Display fixation cross for T2 seconds

    % Calculate elapsed time from the start of the experiment
    elapsedTime = toc(experimentStartTime);

    % Record trial type, WAV file, elapsed time, T1, and T2
    fprintf(CSVoutput, "%d, %s, %f, %f, %f\n", ...
            TrialTypeShuffled(ii), wavFileName, elapsedTime, T1, T2);
end

% End experiment, get feedback (now commented out)
% prompt = 'Evaluate participant performance:';
% feedback = GetEchoStringFreeResponse(window, prompt, 0, 20, ...
%                                      [255 255 255], [0 0 0]);
% fprintf(CSVoutput, "%s\n", feedback);

fclose(CSVoutput);

% Cleanup
sca;