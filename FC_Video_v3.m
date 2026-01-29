classdef FC_Video_v3 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        VideoSplitterUIFigure          matlab.ui.Figure
        FilePrefixEditField            matlab.ui.control.EditField
        FilePrefixEditFieldLabel       matlab.ui.control.Label
        ProcessVideosButton            matlab.ui.control.Button
        CompileVideosAsButtonGroup     matlab.ui.container.ButtonGroup
        AllTrialsButton                matlab.ui.control.RadioButton
        IndividualTrialsButton         matlab.ui.control.RadioButton
        CreateVideoSegmentsButton      matlab.ui.control.Button
        UITable2                       matlab.ui.control.Table
        TotalframesTextArea            matlab.ui.control.TextArea
        TotalframesTextAreaLabel       matlab.ui.control.Label
        FrameRatefpsTextArea           matlab.ui.control.TextArea
        FrameRatefpsTextAreaLabel      matlab.ui.control.Label
        CurrentvideofileTextArea       matlab.ui.control.TextArea
        CurrentvideofileTextAreaLabel  matlab.ui.control.Label
        GetVideoFileButton             matlab.ui.control.Button
        CurrentfileTextArea            matlab.ui.control.TextArea
        CurrentfileTextAreaLabel       matlab.ui.control.Label
        ClearTableandFilesButton       matlab.ui.control.Button
        TextArea                       matlab.ui.control.TextArea
        SetDefaultDirectoryButton      matlab.ui.control.Button
        UITable                        matlab.ui.control.Table
        GetEventFramepointsButton      matlab.ui.control.Button
        VideoPreviewAxes               matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        defaultDirectory % Path to the default directory
        VideoFrameRate;
        TotalVideoFrames;
        segmentInfo;
        VideoPath;
        ProgressBar;
        %VideoPreviewAxes;
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: GetEventFramepointsButton
        function GetEventFramepointsButtonPushed(app, event)
            
        % Check if default directory has been set
    if isempty(app.defaultDirectory)
        uialert(app.VideoSplitterUIFigure, 'Please set the default directory first.', 'Error');
        return;
    end
    
    % Prompt user to select CSV file, starting from the default directory
    [fileName, filePath] = uigetfile('*.csv', 'Select CSV file', app.defaultDirectory);
    if isequal(fileName, 0)
        disp('User selected Cancel');
        return;
    end
    fullFilePath = fullfile(filePath, fileName); % Use the path returned by uigetfile
    app.CurrentfileTextArea.Value=fullFilePath;

    % Read the CSV file
    data = readtable(fullFilePath);

    % Initialize the flags
    isTone = true;
    camCounter = 1;

    % Relabel "Mc1_" and "Cam1" events
    for i = 2:height(data)
        if strcmp(data{i, 1}, 'Mc1_')
            if isTone
                data{i, 1} = {'Tone'};
            else
                data{i, 1} = {'Shock'};
            end
            isTone = ~isTone;
        elseif strcmp(data{i, 1}, 'Cam1')
            data{i, 1} = {['Cam1' num2str(camCounter)]};
            camCounter = camCounter + 1;
        end
    end

    % Sort by Onset
    data = sortrows(data, 2);

    % Create a new table for the event frames with additional columns
    eventFrames = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'StartEvent', 'MarkerDuration_s', 'FrameNumber', 'AdjustedFrameReference', 'IntereventInterval_s'});

    % Extract frame numbers and build the table
    previousOnset = NaN; % Track previous onset time for interevent interval
    
    for i = 2:height(data)
        if strcmp(data{i, 1}, 'Tone') || strcmp(data{i, 1}, 'Shock')
            frameNumber = str2double(data{i-1, 1}{1}(5:end)); % Remove the leading '1'
            if isnan(frameNumber)
                continue;
            end
            adjustedFrame = frameNumber + (strcmp(data{i, 1}, 'Tone') * -200) + (strcmp(data{i, 1}, 'Shock') * 100);
            
            % Calculate event duration (offset - onset) from columns B and C
            eventOnset = data{i, 2}; % Column B (Onset)
            eventOffset = data{i, 3}; % Column C (Offset)
            eventDuration = eventOffset - eventOnset;
            
            % Calculate interevent interval (current onset - previous onset)
            if isnan(previousOnset)
                intereventInterval = NaN; % First event has no previous event
            else
                intereventInterval = eventOnset - previousOnset;
            end
            
            % Add row to table
            eventFrames = [eventFrames; {data{i, 1}{1}, eventDuration, frameNumber, adjustedFrame, intereventInterval}];
            
            % Update previous onset for next iteration
            previousOnset = eventOnset;
        end
    end

    % Display the table
    disp(eventFrames);

    % Display the table in the GUI
    app.UITable.Data = eventFrames;
    app.UITable.ColumnName = {'Event', 'Marker Duration (s)', 'Frame #', 'Adjusted Frame #', 'Interevent Interval (s)'}; % Set the column names

    % Save the table to a new CSV file
    %writetable(eventFrames, fullfile(filePath, 'EventFrames.csv'));

    disp('Data processed successfully.');
        end

        % Button pushed function: SetDefaultDirectoryButton
        function SetDefaultDirectoryButtonPushed(app, event)
            folder_name = uigetdir;
    if isequal(folder_name, 0)
       disp('User selected Cancel');
       return;
    else
       app.defaultDirectory = folder_name;
       app.TextArea.Value = folder_name;
       disp(['Default directory set to: ' folder_name]);
    end
        end

        % Button pushed function: ClearTableandFilesButton
        function ClearTableandFilesButtonPushed(app, event)

    app.UITable.Data = table(); % Clear the data in the table.
    app.UITable.ColumnName = {}; % Clear column names
    app.UITable2.Data = table(); % Clear the data in the table.
    app.UITable2.ColumnName = {}; % Clear column names
    app.CurrentfileTextArea.Value= ' ';
    app.CurrentvideofileTextArea.Value = ''; % Clear the displayed video file path
    app.FrameRatefpsTextArea.Value = ''; % Clear frame rate text box
    app.TotalframesTextArea.Value = ''; % Clear total frames text box
    disp('Table cleared.');

        end

        % Button pushed function: GetVideoFileButton
        function GetVideoFileButtonPushed(app, event)
            % Check if default directory has been set
    if isempty(app.defaultDirectory)
        uialert(app.VideoSplitterUIFigure, 'Please set the default directory first.', 'Error');
        return;
    end

    % Define the file types for video files
    videoFileTypes = {'*.avi;*.mp4;*.mov', 'Video Files (*.avi, *.mp4, *.mov)'};

    % Prompt user for video file, starting from the default directory
    [filename, path] = uigetfile(videoFileTypes, 'Select a video file', app.defaultDirectory);
    if isequal(filename, 0)
        disp('User selected Cancel');
        return;
    end
    videoPath = fullfile(path, filename);

    % Display the video file path
    app.CurrentvideofileTextArea.Value = videoPath;

   % Store the video path in the application's data
    app.VideoPath = videoPath; % Store it in app

    % Declare frameRate and totalFrames *before* the try block
    frameRate = NaN;  
    totalFrames = NaN;
   
   try
        % Open the video file
        v = VideoReader(videoPath);
        frameRate = v.FrameRate; % Get the frame rate
        totalFrames = floor(v.Duration * frameRate); % Calculate the total number of frames

        % Display frame rate and total frames in individual text boxes
        app.FrameRatefpsTextArea.Value = num2str(frameRate);
        app.TotalframesTextArea.Value = num2str(totalFrames);
        
        disp(['Video file loaded: ' videoPath]);
        disp(['Frame Rate: ' num2str(frameRate)]);
        disp(['Total Frames: ' num2str(totalFrames)]);

        % Display the first frame of the video in the UI axes
        i% Display the first 100 frames of the video in the UI axes
        if isgraphics(app.VideoPreviewAxes)
            app.VideoPreviewAxes.Visible = 'on'; % Make sure axes is visible
            for frameNum = 1:min(100, totalFrames) %display a max of 100 frames
                frame = read(v, frameNum);
                imshow(frame, 'Parent', app.VideoPreviewAxes);
                pause(0.1); % Adjust the pause duration as needed
            end
        end
    
   catch ME
        uialert(app.VideoSplitterUIFigure, ['Error loading video file: ' ME.message], 'Error');
        app.CurrentvideofileTextArea.Value = ''; % Clear the text area on error
        % Clear the video info text boxes on error
        app.FrameRatefpsTextArea.Value = '';
        app.TotalframesTextArea.Value = '';   
    end
        end

        % Button pushed function: CreateVideoSegmentsButton
        function CreateVideoSegmentsButtonPushed(app, event)
            % Extract start and end frames from the table in the app
    if isempty(app.UITable.Data)
        uialert(app.VideoSplitterUIFigure, 'No event frame data available. Please load and process event data first.', 'Error');
        return;
    end

    try
        % Get the data from the table
        tableData = app.UITable.Data;

        % Extract adjusted frame references for 'Tone'/'tone' and 'Shock'/'Mc1_' events
        startFrames = tableData.AdjustedFrameReference(strcmp(tableData.StartEvent, 'Tone') | strcmp(tableData.StartEvent, 'tone'));
        endFrames = tableData.AdjustedFrameReference(strcmp(tableData.StartEvent, 'Shock') | strcmp(tableData.StartEvent, 'Mc1_'));


    catch ME
        error('Error extracting frame references. Please check the event data.  Original error: %s', ME.message);
    end

    % Check for frame mismatches
     totalFrames = str2double(app.TotalframesTextArea.Value);
    if any(endFrames > totalFrames)
        warningMsg = sprintf('Warning: Source file has too few frames (%d) to be segmented as indicated. Do you wish to continue processing? (y/n): ', totalFrames);
        userResponse = input(warningMsg, 's');
        if lower(userResponse) ~= 'y', return; end
    end

    % Confirm the start and end points with the user
    %for i = 1:length(startFrames)
       % fprintf('Segment %d: Start Frame = %d, End Frame = %d\n', i, startFrames(i), endFrames(i));
    %end
    %confirm = input('Are these start and end points correct? (y/n): ', 's');
    %if lower(confirm) ~= 'y', return; end

    % Create table to display segment info
    segmentTable = table('Size', [length(startFrames), 3], 'VariableTypes', {'double', 'double', 'string'}, ...
        'VariableNames', {'StartFrame', 'EndFrame', 'SegmentName'});

    % Populate the table
    for i = 1:length(startFrames)
        segmentTable.StartFrame(i) = startFrames(i);
        segmentTable.EndFrame(i) = endFrames(i);
        segmentTable.SegmentName{i} = sprintf('Segment%d', i);
    end

    % Display the segment table in the GUI
    app.UITable2.Data = segmentTable;
    app.UITable2.ColumnName = {'Start Frame', 'End Frame', 'Segment Name'};

    disp('Video segments defined.');

    % Store segment information
    app.segmentInfo = segmentTable; % Store the segment information in the app
        end

        % Button pushed function: ProcessVideosButton
        function ProcessVideosButtonPushed(app, event)
            % Get the segment information from the app
    segmentInfo = app.segmentInfo;
    if isempty(segmentInfo)
        uialert(app.VideoSplitterUIFigure, 'No segment information available. Please define video segments first.', 'Error');
        return;
    end

    % Get the video file path
   % Get the video file path from the app's data
    videoPath = app.VideoPath; % Get from app
    if isempty(videoPath)
        uialert(app.VideoSplitterUIFigure, 'No video file selected. Please select a video file first.', 'Error');
        return;
    end

    % Get the file prefix
    filePrefix = app.FilePrefixEditField.Value;
    if isempty(filePrefix)
        uialert(app.VideoSplitterUIFigure, 'Please enter a file prefix.', 'Error');
        return;
    end

    % Get the output directory (same as the video file directory)
    [outputDir, ~, ~] = fileparts(videoPath);

    % Check if the video path is valid
    if ~ischar(videoPath) || isempty(videoPath)
        uialert(app.VideoSplitterUIFigure, 'Error: Invalid video file path.  Please select a valid video file.', 'Error');
        return;
    end
    
    % Display the video file path for debugging
    disp(['Video path being used: ' videoPath]);

    % Open the video file
    try
        v = VideoReader(videoPath);
        frameRate = v.FrameRate; % Get the frame rate
    catch ME
        uialert(app.VideoSplitterUIFigure, ['Error opening video file: ' ME.message], 'Error');
        return;
    end

  % Get the user's choice for single or combined video
    if app.IndividualTrialsButton.Value == 1
        % Write individual segment videos
        totalSegments = height(segmentInfo);
        % Initialize progress dialog
        pd = uiprogressdlg(app.VideoSplitterUIFigure, 'Title', 'Processing Videos', ...
            'Message', 'Writing video segments...', 'Indeterminate', 'off', 'Cancelable', 'on');
        
        for i = 1:totalSegments
            if pd.CancelRequested
                break; % Stop processing if user cancels
            end
            
            fprintf('Writing segment %d of %d...\n', i, totalSegments);
            % Create a new video writer
            outputVideo = VideoWriter(fullfile(outputDir, [filePrefix '_Trial_' num2str(i) '.avi']), 'Uncompressed AVI');
            outputVideo.FrameRate = frameRate;
            open(outputVideo);
            % Extract and write frames
            for j = segmentInfo.StartFrame(i):segmentInfo.EndFrame(i)
                frame = read(v, j);
                writeVideo(outputVideo, frame);
            end
            % Close the video writer
            close(outputVideo);
            fprintf('Segment %d complete!\n', i);
            pd.Value = i / totalSegments; % Update progress
            pd.Message = sprintf('Writing segment %d of %d', i, totalSegments);
        end
        
        if pd.CancelRequested
            disp('Video processing cancelled by user.');
        else
            disp('All individual video segments extracted successfully!');
            uialert(app.VideoSplitterUIFigure, 'All trials successfully written to individual video files!', 'Files written', 'Icon', 'success');
        end
        close(pd); % Close progress dialog
        
    elseif app.AllTrialsButton.Value == 1
    % Write a single video containing all segments with blank frame separators
    outputVideo = VideoWriter(fullfile(outputDir, [filePrefix '_All_Trials.avi']), 'Uncompressed AVI');
    outputVideo.FrameRate = frameRate;
    open(outputVideo);
    totalSegments = height(segmentInfo);
    
    % Read one frame to get dimensions for creating blank frames
    sampleFrame = read(v, 1);
    [height_img, width_img, numChannels] = size(sampleFrame);
    
    % Define number of blank frames to insert (e.g., 30 frames = 1 second at 30fps)
   % Define separator duration in seconds
      separatorDuration = 2; % Change this value as needed
      numBlankFrames = round(separatorDuration * frameRate);
    
    
    % Create a blank frame (black)
    blankFrame = zeros(height_img, width_img, numChannels, 'uint8');
    
    % Initialize progress dialog
    pd = uiprogressdlg(app.VideoSplitterUIFigure, 'Title', 'Processing Videos', ...
        'Message', 'Writing combined video...', 'Indeterminate', 'off', 'Cancelable', 'on');
    
    for i = 1:totalSegments
        if pd.CancelRequested
            break; % Stop processing if user cancels
        end
        fprintf('Writing segment %d of %d...\n', i, totalSegments);
        
        % Write the segment frames
        for j = segmentInfo.StartFrame(i):segmentInfo.EndFrame(i)
            frame = read(v, j);
            writeVideo(outputVideo, frame);
        end
        
        % Add blank frames between trials (except after the last trial)
        if i < totalSegments
            for k = 1:numBlankFrames
                writeVideo(outputVideo, blankFrame);
            end
            fprintf('Inserted %d blank frames after segment %d\n', numBlankFrames, i);
        end
        
        pd.Value = i/totalSegments;
        pd.Message = sprintf('Writing segment %d of %d', i, totalSegments);
    end
    close(outputVideo);
    
    if pd.CancelRequested
        disp('Video processing cancelled by user.');
    else
        disp('Single video with all segments extracted successfully!');
        uialert(app.VideoSplitterUIFigure, 'All trials successfully written to single video file!', 'File Written', 'Icon', 'success');
    end
    close(pd);
    else
        uialert(app.VideoSplitterUIFigure, 'Please select either Individual Trials or All Trials.', 'Error');
        return;
    end
    app.ProgressBar.Value = 0; % Reset
    
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create VideoSplitterUIFigure and hide until all components are created
            app.VideoSplitterUIFigure = uifigure('Visible', 'off');
            app.VideoSplitterUIFigure.Position = [100 100 1136 830];
            app.VideoSplitterUIFigure.Name = 'Video Splitter';

            % Create VideoPreviewAxes
            app.VideoPreviewAxes = uiaxes(app.VideoSplitterUIFigure);
            title(app.VideoPreviewAxes, 'PREVIEW')
            app.VideoPreviewAxes.GridLineWidth = 0.1;
            app.VideoPreviewAxes.XColor = [1 1 1];
            app.VideoPreviewAxes.XTick = [];
            app.VideoPreviewAxes.YColor = [1 1 1];
            app.VideoPreviewAxes.YTick = [];
            app.VideoPreviewAxes.ZColor = [1 1 1];
            app.VideoPreviewAxes.ZTick = [];
            app.VideoPreviewAxes.LineWidth = 0.1;
            app.VideoPreviewAxes.GridColor = [0 0 0];
            app.VideoPreviewAxes.Position = [688 512 292 200];

            % Create GetEventFramepointsButton
            app.GetEventFramepointsButton = uibutton(app.VideoSplitterUIFigure, 'push');
            app.GetEventFramepointsButton.ButtonPushedFcn = createCallbackFcn(app, @GetEventFramepointsButtonPushed, true);
            app.GetEventFramepointsButton.FontWeight = 'bold';
            app.GetEventFramepointsButton.Tooltip = {'Get  and sort .CSV file with camera and event markers'};
            app.GetEventFramepointsButton.Position = [232 702 146 22];
            app.GetEventFramepointsButton.Text = 'Get Event Framepoints';

            % Create UITable
            app.UITable = uitable(app.VideoSplitterUIFigure);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Position = [16 53 577 643];

            % Create SetDefaultDirectoryButton
            app.SetDefaultDirectoryButton = uibutton(app.VideoSplitterUIFigure, 'push');
            app.SetDefaultDirectoryButton.ButtonPushedFcn = createCallbackFcn(app, @SetDefaultDirectoryButtonPushed, true);
            app.SetDefaultDirectoryButton.FontWeight = 'bold';
            app.SetDefaultDirectoryButton.Position = [44 790 133 22];
            app.SetDefaultDirectoryButton.Text = 'Set Default Directory';

            % Create TextArea
            app.TextArea = uitextarea(app.VideoSplitterUIFigure);
            app.TextArea.Tag = 'DirectoryDisplayEditField';
            app.TextArea.Editable = 'off';
            app.TextArea.Position = [16 743 190 40];

            % Create ClearTableandFilesButton
            app.ClearTableandFilesButton = uibutton(app.VideoSplitterUIFigure, 'push');
            app.ClearTableandFilesButton.ButtonPushedFcn = createCallbackFcn(app, @ClearTableandFilesButtonPushed, true);
            app.ClearTableandFilesButton.BackgroundColor = [1 1 0];
            app.ClearTableandFilesButton.FontWeight = 'bold';
            app.ClearTableandFilesButton.Position = [477 798 134 22];
            app.ClearTableandFilesButton.Text = 'Clear Table and Files';

            % Create CurrentfileTextAreaLabel
            app.CurrentfileTextAreaLabel = uilabel(app.VideoSplitterUIFigure);
            app.CurrentfileTextAreaLabel.HorizontalAlignment = 'right';
            app.CurrentfileTextAreaLabel.Position = [218 752 62 22];
            app.CurrentfileTextAreaLabel.Text = 'Current file';

            % Create CurrentfileTextArea
            app.CurrentfileTextArea = uitextarea(app.VideoSplitterUIFigure);
            app.CurrentfileTextArea.Position = [289 743 291 40];

            % Create GetVideoFileButton
            app.GetVideoFileButton = uibutton(app.VideoSplitterUIFigure, 'push');
            app.GetVideoFileButton.ButtonPushedFcn = createCallbackFcn(app, @GetVideoFileButtonPushed, true);
            app.GetVideoFileButton.FontWeight = 'bold';
            app.GetVideoFileButton.Tooltip = {'Select matching video that corresponds with event framepoints'};
            app.GetVideoFileButton.Position = [784 798 100 22];
            app.GetVideoFileButton.Text = 'Get Video File';

            % Create CurrentvideofileTextAreaLabel
            app.CurrentvideofileTextAreaLabel = uilabel(app.VideoSplitterUIFigure);
            app.CurrentvideofileTextAreaLabel.HorizontalAlignment = 'right';
            app.CurrentvideofileTextAreaLabel.Position = [592 746 96 22];
            app.CurrentvideofileTextAreaLabel.Text = 'Current video file';

            % Create CurrentvideofileTextArea
            app.CurrentvideofileTextArea = uitextarea(app.VideoSplitterUIFigure);
            app.CurrentvideofileTextArea.Position = [703 723 244 68];

            % Create FrameRatefpsTextAreaLabel
            app.FrameRatefpsTextAreaLabel = uilabel(app.VideoSplitterUIFigure);
            app.FrameRatefpsTextAreaLabel.HorizontalAlignment = 'right';
            app.FrameRatefpsTextAreaLabel.Position = [954 768 96 22];
            app.FrameRatefpsTextAreaLabel.Text = 'Frame Rate (fps)';

            % Create FrameRatefpsTextArea
            app.FrameRatefpsTextArea = uitextarea(app.VideoSplitterUIFigure);
            app.FrameRatefpsTextArea.Position = [1056 767 40 24];

            % Create TotalframesTextAreaLabel
            app.TotalframesTextAreaLabel = uilabel(app.VideoSplitterUIFigure);
            app.TotalframesTextAreaLabel.HorizontalAlignment = 'right';
            app.TotalframesTextAreaLabel.Position = [961 732 70 22];
            app.TotalframesTextAreaLabel.Text = 'Total frames';

            % Create TotalframesTextArea
            app.TotalframesTextArea = uitextarea(app.VideoSplitterUIFigure);
            app.TotalframesTextArea.Position = [1036 731 60 23];

            % Create UITable2
            app.UITable2 = uitable(app.VideoSplitterUIFigure);
            app.UITable2.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable2.RowName = {};
            app.UITable2.Position = [647 166 407 311];

            % Create CreateVideoSegmentsButton
            app.CreateVideoSegmentsButton = uibutton(app.VideoSplitterUIFigure, 'push');
            app.CreateVideoSegmentsButton.ButtonPushedFcn = createCallbackFcn(app, @CreateVideoSegmentsButtonPushed, true);
            app.CreateVideoSegmentsButton.FontWeight = 'bold';
            app.CreateVideoSegmentsButton.Tooltip = {'Create the video segment points from the framepoint table'};
            app.CreateVideoSegmentsButton.Position = [777 491 148 22];
            app.CreateVideoSegmentsButton.Text = 'Create Video Segments';

            % Create CompileVideosAsButtonGroup
            app.CompileVideosAsButtonGroup = uibuttongroup(app.VideoSplitterUIFigure);
            app.CompileVideosAsButtonGroup.BorderColor = [0 0 0];
            app.CompileVideosAsButtonGroup.Tooltip = {'Option for multiple files or single file with all trials'};
            app.CompileVideosAsButtonGroup.HighlightColor = [0 0 0];
            app.CompileVideosAsButtonGroup.Title = 'Compile Videos As:';
            app.CompileVideosAsButtonGroup.BackgroundColor = [0.902 0.902 0.902];
            app.CompileVideosAsButtonGroup.FontSize = 14;
            app.CompileVideosAsButtonGroup.Position = [636 48 186 106];

            % Create IndividualTrialsButton
            app.IndividualTrialsButton = uiradiobutton(app.CompileVideosAsButtonGroup);
            app.IndividualTrialsButton.Text = 'Individual Trials';
            app.IndividualTrialsButton.FontSize = 14;
            app.IndividualTrialsButton.Position = [11 45 118 22];
            app.IndividualTrialsButton.Value = true;

            % Create AllTrialsButton
            app.AllTrialsButton = uiradiobutton(app.CompileVideosAsButtonGroup);
            app.AllTrialsButton.Text = 'All Trials';
            app.AllTrialsButton.FontSize = 14;
            app.AllTrialsButton.Position = [11 18 75 22];

            % Create ProcessVideosButton
            app.ProcessVideosButton = uibutton(app.VideoSplitterUIFigure, 'push');
            app.ProcessVideosButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessVideosButtonPushed, true);
            app.ProcessVideosButton.BackgroundColor = [0 1 0];
            app.ProcessVideosButton.FontSize = 24;
            app.ProcessVideosButton.FontWeight = 'bold';
            app.ProcessVideosButton.Position = [862 80 194 38];
            app.ProcessVideosButton.Text = 'Process Videos';

            % Create FilePrefixEditFieldLabel
            app.FilePrefixEditFieldLabel = uilabel(app.VideoSplitterUIFigure);
            app.FilePrefixEditFieldLabel.HorizontalAlignment = 'right';
            app.FilePrefixEditFieldLabel.Position = [636 15 58 22];
            app.FilePrefixEditFieldLabel.Text = 'File Prefix';

            % Create FilePrefixEditField
            app.FilePrefixEditField = uieditfield(app.VideoSplitterUIFigure, 'text');
            app.FilePrefixEditField.Tooltip = {'Enter file prefix for video(s) here'};
            app.FilePrefixEditField.Position = [709 15 100 22];

            % Show the figure after all components are created
            app.VideoSplitterUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = FC_Video_v3

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.VideoSplitterUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.VideoSplitterUIFigure)
        end
    end
end