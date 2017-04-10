function prepare_arenas(videofilename,arenafilename,FirstFrame,LastFrame,framesperblock,user_string)
% extract images from ROIs and save as mat files for further processing
% For each defined area - we take a rectangle that captures the entire
% shape, but a mask is applied to set regions outside the ROI to 0.
% YBS 9/16


% fraction of frames which will be used for median calculation.
% In the future, we may use running average medians to account for changing
% lighting conditions in the arena
mff = 10; 

% Total frames to convert
TotalFrames = LastFrame-FirstFrame+1;

% Create videoobject and get sampling rate in seconds
VideoObj = VideoReader(videofilename);
SR = 1/VideoObj.FrameRate;

% This array will provide information about the file and frame indices
% within the tmp matrices for each frame in the movie
FrameInfo = zeros(TotalFrames,3);

% Get arena file data which includes the ROIs.
aD = load(arenafilename);

n_rois = length(aD.ROIs);

% get arena file name
[~, tmpname, ~] = fileparts(arenafilename);
cind = findstr('arenas',tmpname);
arenaname = tmpname(cind:end);

% Generate names for temporary (.mat) files and folders
[P, F, ~] = fileparts(videofilename);
for i = 1:n_rois
    tmpvidfiledirs{i} = [P filesep F '_' arenaname '_' aD.ROIs(i).name '_frames_' num2str(FirstFrame) '_'  num2str(LastFrame)];
    basefname{i}      = [F '_' arenaname '_' aD.ROIs(i).name];    
end
% Create these directories
for i = 1:n_rois
    if ~(exist(tmpvidfiledirs{i}) == 7)
        mkdir(tmpvidfiledirs{i})
    end
end

% Find rectnagular regions that contain each of the ROIs
for i = 1:n_rois
    % NOte that the X and Y indices are different for the image and the vertex
    % definitions
    minX = floor(min(aD.ROIs(i).vertices(:,1)));
    if minX < 1
        minX = 1;
    end
    maxX = ceil(max(aD.ROIs(i).vertices(:,1)));
    if maxX > aD.ImageSizeInPixels(2)
        maxX = aD.ImageSizeInPixels(2);
    end
    minY = floor(min(aD.ROIs(i).vertices(:,2)));
    if minY < 1
        minY = 1;
    end
    maxY = ceil(max(aD.ROIs(i).vertices(:,2)));
    if maxY > aD.ImageSizeInPixels(1)
        maxY = aD.ImageSizeInPixels(1);
    end
    % Indices into rectangular regions
    R1{i} = [minX:maxX];
    R2{i} = [minY:maxY];
end

% Initialize to save time, since we are using a loop to fill the matrices
fulltmpframes = uint8(zeros(VideoObj.Height, VideoObj.Width,framesperblock));

% Define the start and end frames for each set
framestarts = [FirstFrame:framesperblock:LastFrame];
frameends   = [framestarts(2:end)-1 LastFrame];

% index for frames used for median
fmi = 1; 

% Progress bar (cannot be deleted or used to cancel)
progbar_h = waitbar(0,['converting ' num2str(TotalFrames) ' frames and calculating median for ' num2str(n_rois) ' arenas'],'Name','Generating grayscale arena files');

%counter of frames
frc = 1; 

% sc is the counter of segments
for sc = 1:length(framestarts)
    % Read frames in current segment
    frames = read(VideoObj,[framestarts(sc) frameends(sc)]);    
    % convert each frame into an RGB image and save information about
    % segment indices (sc), indec within segment (k), and total time 
    for k = 1:size(frames,4)
        fulltmpframes(:,:,k) = rgb2gray(frames(:,:,:,k));
        FrameInfo(frc,:) = [sc,k,frc*SR];
        frc = frc+1;
    end
        
    % Each arena is processed separately
    for roi_ind = 1:n_rois                
        
        % Create mask for this arena - the result is masked_frames
        m = aD.ImageSizeInPixels(1);
        n = aD.ImageSizeInPixels(2);        
        masked_frames = fulltmpframes;
        c = aD.ROIs(roi_ind).vertices(:,1);
        r = aD.ROIs(roi_ind).vertices(:,2);
        arena_mask_2D = poly2mask(c,r,m,n);
        arena_mask_3D = repmat(arena_mask_2D,1,1,size(fulltmpframes,3));        
        
        masked_frames(~arena_mask_3D) =  median(fulltmpframes(:));               
        
        % extract the relevant rectangular region from the (masked) image
        % saving it until the index k should cae of the last segment which 
        % typically is smaller (unless the entire number of frames is exactly
        % a multiple of framesperblock)
        ROI_tmp_frames = masked_frames(R2{roi_ind},R1{roi_ind},1:k);   

        % Save into file name for this segment        
        thisfilename = [tmpvidfiledirs{roi_ind},filesep,basefname{roi_ind},'_frames_' num2str(FirstFrame) '_'  num2str(LastFrame) '_' num2str(sc) '.mat'];                        
        % The arena mask 2D may be used if we want to reverse the color of
        % the mask (in case mouse is darker and user selects no median)
        save(thisfilename,'ROI_tmp_frames','arena_mask_2D');
        
        % If we have more frames than the fraction used for median
        % calculation, then use the appropriate fraction for median
        % calculation
        if k > mff 
            % median frame indices
            mfis = floor([1:k/mff:k]);                         
            % Append these frames to the frame4median array
            nmf = length(mfis); % number of median frames      
            frames4median{roi_ind}(:,:,fmi:fmi+nmf-1) =  ROI_tmp_frames(:,:,mfis);            
        end      
    end
    
    % update indiex for the next time we append file for median
    fmi = size(frames4median{roi_ind},3) + 1; 
    % update wait bar
    if ishandle(progbar_h)
        waitbar(sc/length(framestarts),progbar_h,['converting ' num2str(TotalFrames) ' frames and calculating median for ' num2str(n_rois) ' arenas']);
    else
        msgbox('Arena preparation terminated by user','OptiMouse - prepare Arenas');
        return
    end
        
end % conversion done

% Calcualte the median for each arena
for roi_ind = 1:n_rois
   RoiMedian{roi_ind} = uint8(median(frames4median{roi_ind},3));
end


% Arena info is saved for each arena separately - other general information
% is also included for later processing
OriginalImageSizeInPixels = aD.ImageSizeInPixels;
pixels_per_mm = aD.pixels_per_mm;
frames_in_original_video = [FirstFrame LastFrame];
for roi_ind = 1:n_rois    
    thisfilename = [P filesep 'arenas' filesep basefname{roi_ind},'_frames_' num2str(FirstFrame) '_'  num2str(LastFrame),'_info.mat'];    
    MedianImage =  RoiMedian{roi_ind};
    arena_info    =   aD.ROIs(roi_ind);    
    save(thisfilename,'MedianImage','FrameInfo','pixels_per_mm','videofilename','arenafilename','OriginalImageSizeInPixels','arena_info','frames_in_original_video','user_string');
end

% done
delete(progbar_h); 


return

