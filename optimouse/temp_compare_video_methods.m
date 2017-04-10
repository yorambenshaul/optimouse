% a script to compare_video_reader_methods

videofilename = 'C:\Users\yoramb\Documents\DATA\OksanaVideoData\07-04-16_00025Copy.mp4';

FPS = 100; % Frames per segment

% old method
VideoObj = VideoReader(videofilename);

Duration = VideoObj.Duration;
FrameRate = VideoObj.FrameRate;
vidWidth = VideoObj.Width;
vidHeight = VideoObj.Height;

% Time per segment
TPS = FPS / FrameRate;

segtimes = [0:TPS:Duration];

s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'));

tfc = 1;

for SI = 1:length(segtimes)-1
    startT = segtimes(SI);
    endT   = segtimes(SI+1);
    VideoObj.CurrentTime = startT;
    
    tic
    k = 1;
    while VideoObj.CurrentTime <= endT
        s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'));
        s(k).cdata = readFrame(VideoObj);
        k = k+1;
        tfc = tfc + 1;
    end
    disp(length(s));
    disp(tfc);
    toc
    
end



videofilename = 'C:\Users\yoramb\Documents\DATA\OksanaVideoData\07-04-16_00025Copy.mp4';

FPS = 100; % Frames per segment

% old method
VideoObj = VideoReader(videofilename);

LastFrame = VideoObj.NumberOfFrames;
FirstFrame = 1;

% Total frames to convert
TotalFrames = LastFrame-FirstFrame+1;

% Define the start and end frames for each set
framestarts = [FirstFrame:FPS:LastFrame];
frameends   = [framestarts(2:end)-1 LastFrame];

tic
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'));
toc

for sc = 1:length(framestarts)
    % Read frames in current segment
    tic
    frames = read(VideoObj,[framestarts(sc) frameends(sc)]);
    % s.cdata = read(VideoObj,[framestarts(sc) frameends(sc)]);
    disp(toc)
end
    

