function update_frame(handles)
% based on replay_calculated_positions, but is much more basic.
% only video data, no position data is shown.
% Used in the analyze video display
% YBS 9/16

% load the info data
contents = cellstr(handles.arena_folder_listbox.String);
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
[~,F,~] = fileparts(position_file);
fs = findstr('_positions',F);
base_name = F(1:fs-1);
info_file   = dir([handles.video_dir_text.String filesep 'arenas' filesep  base_name '_info.mat']);
if isempty(info_file)
    return
end
arena_data = load([handles.video_dir_text.String filesep 'arenas' filesep info_file(1).name]);

MedianImage = arena_data.MedianImage;
FrameInfo = arena_data.FrameInfo;
TotalFrames = size(FrameInfo,1);

pixels_per_mm = arena_data.pixels_per_mm;

load(position_file);





%% Set image display
psz = length(MedianImage)/50;
psz2 = psz/2;
Ylimits = [1-psz size(MedianImage,1)+psz];
Xlimits = [1-psz size(MedianImage,2)+psz];

axes(handles.original_video_axes);

% Show axes in cm  (convert from pixels)
pixels_per_cm = 10*pixels_per_mm;
CF =  1/pixels_per_cm;


%% Get last frame and next frame to start at
frc =  str2num(handles.current_frame_edit.String);
if frc < 1 || frc > TotalFrames
    return
end

% Get the inforamtion about the tmp mat file containing this frame
rel_file_num = FrameInfo(frc,1);
% if file not loaded, then load it
load([handles.video_dir_text.String filesep base_name filesep base_name '_' num2str(rel_file_num) '.mat']);
%load([arena_folder filesep arena_name '_' num2str(rel_file_num) '.mat']);
rel_frame_in_file = FrameInfo(frc,2);

% Show the frame
images_to_delete = findobj(gca,'type','image');
delete(images_to_delete);
current_image_h = imagesc(ROI_tmp_frames(:,:,rel_frame_in_file));


FrameTime = FrameInfo(frc,3);
TotalFrameTime = FrameInfo(end,3);

info_str{1} = ['Frame ' num2str(frc) ' of ' num2str(TotalFrames)];
info_str{2} = [num2str(FrameTime,'%.2f') ' of ' num2str(TotalFrameTime,'%.2f') ' s'];
handles.frame_info_text.String = info_str;




uistack(current_image_h,'bottom')
guidata(gcf,handles);


return




