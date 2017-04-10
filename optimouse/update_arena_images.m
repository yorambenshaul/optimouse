function update_arena_images(handles)
% upodate arena images from calculate position GUI
% YBS 9/16

% Get detection algorithm
head_method = handles.detection_method_menu.Value;

% Find if this is a user defined method
if ~isempty(handles.user_detection_functions)
    user_detection_functions_vals = cell2mat({handles.user_detection_functions.menuval});
else
    user_detection_functions_vals = [];
end
    
if ismember(head_method,user_detection_functions_vals)
    fid = find(head_method == user_detection_functions_vals);
    % and activate those that are relevant for this method
    param_names = handles.user_detection_functions(fid).param_names;
    % Error checking was already done
    for i = 1:length(param_names)
        eval([param_names{i} ' = str2num(handles.user_param' num2str(i) '_edit.String);']);    
    end
    cmd_str = handles.user_detection_functions(fid).runstring;
else
    cmd_str = 'Result = get_mouse_position_mm(ThisFrame,head_method,trim_cycles,GreyThresh_fact);';
end

plot_result = 1;
trim_cycles = handles.trim_level_menu.Value;
GreyThresh_fact = str2num(handles.detection_threshold_text.String);

contents = cellstr(get(handles.arena_folder_listbox,'String'));
tmp_file_folder = [handles.video_dir_text.String filesep contents{get(handles.arena_folder_listbox,'Value')}];

frame_idx = str2num(handles.current_frame_edit.String);

infostr = handles.current_frame_edit.String;

arena_folder = [handles.video_dir_text.String filesep 'arenas'];
base_name = contents{get(handles.arena_folder_listbox,'Value')};
info_file   = dir([arena_folder filesep base_name '*_info.mat']);
if isempty(info_file)
    return
end

iD = load([arena_folder filesep info_file(1).name]);

% Find the index into the frame
frame_file_num = iD.FrameInfo(frame_idx,1);
frame_ind_in_file = iD.FrameInfo(frame_idx,2);
frame_time_in_sec = iD.FrameInfo(frame_idx,3);
last_frame_time_in_sec = iD.FrameInfo(end,3);

% Get the frame file (there should be only one)
frame_file = dir([tmp_file_folder filesep '*_frames_*_' num2str(frame_file_num) '.mat']);
if isempty(frame_file)
    return
end
fD = load([tmp_file_folder filesep frame_file.name]);
VidFrame = fD.ROI_tmp_frames(:,:,frame_ind_in_file);

psz = length(VidFrame)/50;
psz2 = psz/2;

% Allow user control of median removal approach
if handles.mouse_brighter_radiobutton.Value
    MedianMethod = 1;
elseif handles.mouse_darker_radiobutton.Value
    MedianMethod = 2;
elseif handles.auto_determine_brighter_radiobutton.Value
    MedianMethod = determine_contrast_method(VidFrame);
end

% If the user defined background radiobutton  is active, this means that
% we have a user defined background image, which means that we do not need
% to check for the existence of the BackGroundImage field
if handles.use_median_as_background_radiobutton.Value
    BackGroundImage = iD.MedianImage;
    BackGroundType = 'Median';
elseif handles.user_defined_background_radiobutton.Value
    BackGroundImage = handles.CurrentUserBackGround;
    BackGroundType = 'User Defined';
elseif handles.nobackground_ratiobutton.Value
    if MedianMethod==1
        BackGroundImage = uint8(zeros(size(VidFrame)));
    elseif MedianMethod==2
        BackGroundImage = uint8(255*ones(size(VidFrame)));
    end
    BackGroundType = 'None';
end

% revised two lines below as a test to see whether this would help
if MedianMethod==1
    % mouse is lighter
    ThisFrame = VidFrame - BackGroundImage;
elseif MedianMethod==2
    % mouse is darker
    ThisFrame = BackGroundImage -VidFrame;
end


% for debugging the subtraction
% figure;
% subplot(1,3,1)
% imagesc(VidFrame); colormap gray; axis equal; axis tight; colorbar
% title(['original image'])
% subplot(1,3,2)
% imagesc(BackGroundImage); colormap gray; axis equal; axis tight; colorbar
% title(['background ' BackGroundType])
% subplot(1,3,3)
% imagesc(MedianRemovedImage); colormap gray; axis equal; axis tight; colorbar
% title('background corrected')
% figure;
% imagesc(255-VidFrame); colormap jet; axis equal; axis tight; colorbar
% title(['original image'])

% We need the try because we cannot take respobsibility for user functions
try
    eval(cmd_str);
        
    % in case user functions do not return all fields, add them here
    Result = add_fields_to_Result_structure(Result);
       
    % note that at this stage, we do not need all the parameters
    mouseCOM = Result.mouseCOM;
    nosePOS = Result.nosePOS;
    GreyThresh = Result.GreyThresh;    
    MouseBoundingBox = Result.BB;    
    PerimInds = Result.PerimInds;
    tailCOM = Result.tailCOM;
    thinmouseCOM = Result.thinmouseCOM;
    tailbasePOS  = Result.tailbasePOS;
    tailendPOS = Result.tailendPOS;
    ErrorMsg = Result.ErrorMsg;
catch    
    mouseCOM      = [nan nan];
    nosePOS       = [nan nan];
    GreyThresh    = 0;
    BB            = [];
    PerimInds     = [];
    tailCOM       = [nan nan];
    thinmouseCOM  = [nan nan];
    tailbasePOS   = [nan nan];
    tailendPOS    = [nan nan];
    ErrorMsg      = ['error running: ' cmd_str];
end

  
%%
periminds = [];
if handles.show_perimeter_checkbox.Value
    if ~isnan(mouseCOM(1)) &&  ~isnan(nosePOS(1))
        if ~isempty(PerimInds) && ~isempty(MouseBoundingBox)
        periminds = sub2ind(size(VidFrame),PerimInds{1}+floor(MouseBoundingBox(2)),PerimInds{2}+floor(MouseBoundingBox(1)));
        end
    end
end

axes(handles.original_video_axes)

cla
if handles.original_image_checkbox.Value
    VidFrame(periminds) = VidFrame(periminds)+max(VidFrame(:));
    imagesc(VidFrame);
elseif handles.median_corrected_image_checkbox.Value
    ThisFrame(periminds) = ThisFrame(periminds)+max(ThisFrame(:));
    imagesc(ThisFrame);
elseif handles.binary_image_checkbox.Value
    bwimage = int8(im2bw(ThisFrame, GreyThresh));
    bwimage(periminds) = bwimage(periminds) + 1;
    imagesc(bwimage);
end

colormap gray
axis equal;
axis tight;
set(gca,'XTickLabel',[],'YTickLabel',[])
hold on
info_str = [];
colorbar

if ~isnan(mouseCOM(1)) &&  ~isnan(nosePOS(1))
    handles.nose_text.Visible =  'on';
    handles.body_text.Visible =  'on';
        
    rectangle('Curvature', [1 1], 'Position', [mouseCOM(1)-psz2, mouseCOM(2)-psz2 psz psz],'edgecolor','k','facecolor','g');
    rectangle('Curvature', [1 1], 'Position', [nosePOS(1)-psz2, nosePOS(2)-psz2 psz psz],'edgecolor','k','facecolor','r');
    
    if ~isnan(tailbasePOS(1))
        rectangle('Curvature', [1 1], 'Position', [tailbasePOS(1)-psz2, tailbasePOS(2)-psz2 psz psz],'edgecolor','k','facecolor','y');
    end
    if ~isnan(tailendPOS(1))
        rectangle('Curvature', [1 1], 'Position', [tailendPOS(1)-psz2, tailendPOS(2)-psz2 psz psz],'edgecolor','k','facecolor','m');
    end
    
    if ~isempty(MouseBoundingBox)
        rectangle('Position', MouseBoundingBox,'edgecolor','y','facecolor','none');
        
        if handles.zoom_in_on_mouse.Value
            set(gca,'xlim',[floor(MouseBoundingBox(1))-psz2,floor(MouseBoundingBox(1)) + ceil(MouseBoundingBox(3))+psz2]);
            set(gca,'ylim',[floor(MouseBoundingBox(2))-psz2,floor(MouseBoundingBox(2)) + ceil(MouseBoundingBox(4))+psz2]);
        end
        
    end
    
    mouse_length = sqrt((mouseCOM(1)-nosePOS(1)).^2 + (mouseCOM(2)-nosePOS(2)).^2)/iD.pixels_per_mm;    
    % Note that the y dir is reversed. hence the order of terms
    mouse_angle = atan2d(mouseCOM(2)-nosePOS(2),nosePOS(1)-mouseCOM(1));
    if mouse_angle < 0
        mouse_angle = mouse_angle + 360;
    end
    
    info_str{1} = ['Frame ' num2str(frame_idx) ' of ' num2str(size(iD.FrameInfo,1))];
    info_str{2} = [num2str(frame_time_in_sec,'%.2f') ' of '  num2str(last_frame_time_in_sec,'%.2f') ' secs'];    
     
    % update figure titles
    handles.arena_files_info_text.String = info_str;
    
    if ~isnan(tailbasePOS(1))
        handles.tailbase_text.Visible =  'on';
    else
        handles.tailbase_text.Visible =  'off';
    end
    if ~isnan(tailendPOS(1))
        handles.tailend_text.Visible =  'on';
    else
        handles.tailend_text.Visible =  'off';
    end    
    
    handles.arena_files_info_text.FontSize = 14;
    handles.arena_files_info_text.ForegroundColor  = [0 0.447 0.741];


else    
    handles.nose_text.Visible =  'off';
    handles.body_text.Visible =  'off';
    handles.tailend_text.Visible =  'off';
    handles.tailbase_text.Visible =  'off';
    
    info_str{1} = ['Frame ' num2str(frame_idx) ' of ' num2str(size(iD.FrameInfo,1))];
    info_str{2} = [num2str(frame_time_in_sec,'%.2f') ' of '  num2str(last_frame_time_in_sec,'%.2f') ' secs' ];
    info_str{3} = 'Failure to detect object';
    info_str{4} = ErrorMsg;
    
    % update figure titles
    handles.arena_files_info_text.String = info_str;
    handles.arena_files_info_text.FontSize = 10;
    handles.arena_files_info_text.ForegroundColor  = 'r';
end


return


