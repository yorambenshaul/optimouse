function varargout = analyze_behavior_mm(varargin)
% YBS 9/16
% ANALYZE_BEHAVIOR_MM MATLAB code for analyze_behavior_mm.fig
%      ANALYZE_BEHAVIOR_MM, by itself, creates a new ANALYZE_BEHAVIOR_MM or raises the existing
%      singleton*.
%
%      H = ANALYZE_BEHAVIOR_MM returns the handle to a new ANALYZE_BEHAVIOR_MM or the handle to
%      the existing singleton*.
%
%      ANALYZE_BEHAVIOR_MM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANALYZE_BEHAVIOR_MM.M with the given input arguments.
%
%      ANALYZE_BEHAVIOR_MM('Property','Value',...) creates a new ANALYZE_BEHAVIOR_MM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before analyze_behavior_mm_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to analyze_behavior_mm_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help analyze_behavior_mm

% Last Modified by GUIDE v2.5 24-Nov-2016 11:42:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @analyze_behavior_mm_OpeningFcn, ...
                   'gui_OutputFcn',  @analyze_behavior_mm_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before analyze_behavior_mm is made visible.
function analyze_behavior_mm_OpeningFcn(hObject, eventdata, handles, varargin)

default_path_filename = [get_user_dir 'default_start_dir.mat'];
if exist(default_path_filename) == 2
    D = load(default_path_filename,'folder_name');
    handles.video_dir_text.String = D.folder_name;
end


user_dir = get_user_dir;
% create a tag (keyword) file if it does not exist
tag_file = [user_dir 'optimouse_experiment_tags.txt'];
if ~exist(tag_file,'file')
    fileID = fopen(tag_file,'w');
    fprintf(fileID,'');
    fclose(fileID);
end

arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles)
% handles have to be updated after call
handles = guidata(hObject);

% Initialize the zones structure
handles.zones = [];

% Update handles structure
guidata(hObject, handles);

% Choose default command line output for calculate_positions_in_arena
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = analyze_behavior_mm_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in arena_folder_listbox.
function arena_folder_listbox_Callback(hObject, eventdata, handles)
orig_handles = handles; % for calling load zone

if ~isempty(handles.zone_listbox.String)
    answer = questdlg('are you sure you want to analyze a new file? current zones will be deleted','zone definitions','cancel','continue','cancel');
    if strcmp(answer,'cancel')
        return
    end
end

% Reset zone structure
handles.zones = [];
% Reset defined zone list
handles.zone_listbox.String = '';

% reset axes
cla(handles.original_video_axes)

% reset position strings
handles.X_pos_edit.String = '';
handles.Y_pos_edit.String = '';
handles.width_edit.String = '';
handles.height_edit.String = '';

% reset tags
handles.experiment_tags_edit.String = '';

% reset zone based analysis
handles.compare_zones_button.Enable = 'off';
handles.zone_visit_stats_button.Enable = 'off';
handles.zone_in_time_button.Enable = 'off';
handles.zone_totals_button.Enable = 'off';
handles.ignore_excluded_frames_checkbox.Enable = 'off';

D = dir([handles.video_dir_text.String filesep 'positions' filesep '*_arena*.mat']);

position_files = {D.name};

if isempty(position_files)
    return
end

% Take only relevant files
pattern = handles.file_name_filter_edit.String;
if ~isempty(pattern)
    pat_match = strfind(position_files, pattern);
    take_files = [];
    for i = 1:length(pat_match)
        if ~isempty(pat_match{i})
            take_files = [take_files i];
        end
    end
else
    take_files = 1:length(position_files);
end

position_files = position_files(take_files);
handles.arena_folder_listbox.String = position_files;

if isempty(position_files)
    return
end

handles.arena_folder_listbox.String = position_files;

% Getting the list twice is a bit of a waste, but the waste is negligible
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];

[~,F,~] = fileparts(position_file);
fs = findstr('_positions',F);
base_name = F(1:fs-1);

info_file   = dir([handles.video_dir_text.String filesep 'arenas' filesep  base_name '_info.mat']);
if isempty(info_file)
    return
end
iD = load([handles.video_dir_text.String filesep 'arenas' filesep info_file(1).name]);

     
if isfield(iD,'user_string')
    handles.user_comment_edit.String = iD.user_string;
else
    handles.user_comment_edit.String = '';
end


vid_duration = iD.FrameInfo(end,3);
Nframes = size(iD.FrameInfo,1);

% time data for converting time to frames
data.duration = iD.FrameInfo(end,3);
data.SI       = diff(iD.FrameInfo(1:2,3));
data.nframes  = Nframes;
handles.data = data;

pD = load(position_file);

Nframes = size(iD.FrameInfo,1);
handles.Nframes = Nframes;

frame_file = dir([handles.video_dir_text.String filesep base_name filesep base_name '_1.mat']);

if isempty(frame_file)
    errorstr{1} = 'Cannot find frame file: ';
    errorstr{2} = [handles.video_dir_text.String filesep base_name filesep base_name '_1.mat'];   
    errordlg(errorstr,'moue position analysis')
    return
end
fD = load([handles.video_dir_text.String filesep base_name filesep frame_file.name]);
VidFrame = fD.ROI_tmp_frames(:,:,1);

axes(handles.original_video_axes);
handles.original_video_axes.XTickMode = 'manual';
handles.original_video_axes.YTickMode = 'manual';
handles.original_video_axes.XTickLabelMode = 'manual';
handles.original_video_axes.YTickLabelMode = 'manual';

current_image_h =imagesc(VidFrame);


FrameInfo = pD.arena_data.FrameInfo;
FrameTime = FrameInfo(1,3);
TotalFrameTime = FrameInfo(end,3);
info_str{1} = ['Frame 1 of ' num2str(Nframes)];
info_str{2} = [num2str(FrameTime,'%.2f') ' of ' num2str(TotalFrameTime,'%.2f') ' s'];
handles.frame_info_text.String = info_str;


%% provide general information about frames
% calculations here are a bit mroe elborate than required, but this is not
% a problem
if isfield(pD,'final_nose_positions')
    nosePOS = pD.final_nose_positions;
    bodyPOS = pD.final_body_positions;
    mouse_angles = pD.final_mouse_angles;
    % frames which are excluded, or do not have a position, are excluded from analysis        
    good_frames = true(size(pD.frame_class));    
    good_frames(isnan(mouse_angles))  = false;
    good_frames(pD.frame_class == 11) = false;       
    general_info_string{1}  = ['total frames: ' num2str(length(good_frames))];
    general_info_string{2}  = ['User excluded frames: ' num2str(sum((pD.frame_class == 11)))];
    general_info_string{3}  = ['Total excluded + NaN frames: ' num2str(sum(~good_frames))];    
else
    nosePOS = pD.position_results(1).nosePOS;
    bodyPOS = pD.position_results(1).mouseCOM;
    mouse_angles = atan2d(bodyPOS(:,2)-nosePOS(:,2),nosePOS(:,1)-bodyPOS(:,1));
    good_frames = true(size(mouse_angles));
    good_frames(isnan(mouse_angles)) = false;   
    general_info_string{1}  = ['total frames: ' num2str(length(good_frames))];
    general_info_string{2}  = ['User excluded frames: NA'];
    general_info_string{3}  = ['NaN frames: ' num2str(sum(~good_frames))];    
end
% update the string
handles.general_info_text.String = general_info_string;


%% check if we have any events, and if so, enable the events related buttons
if isfield(pD,'annotations') && ~isempty(pD.annotations)
    handles.events_as_position_button.Enable = 'on';
    handles.events_in_time_button.Enable ='on';
    handles.events_in_zones_button.Enable = 'on';
    handles.general_event_stats_button.Enable = 'on';
else
    handles.events_as_position_button.Enable = 'off';
    handles.events_in_time_button.Enable ='off';
    handles.events_in_zones_button.Enable = 'off';
    handles.general_event_stats_button.Enable = 'off';
end


colormap gray
axis equal;
axis tight
hold on
ylabel('cm')    ;

% % Show axes in cm
pixels_per_mm = iD.pixels_per_mm;
pixels_per_cm = 10*pixels_per_mm;
CF =  1/pixels_per_cm;

rescale_axes(handles.original_video_axes,CF);

handles.current_frame_slider.Max = Nframes;
handles.current_frame_slider.Min = 1;
handles.current_frame_slider.Value = 1;
handles.current_frame_edit.String = '1'; 
handles.current_time_edit.String = num2str(handles.data.SI,'%.2f');


onesecond = (1/data.duration);
oneminute = (onesecond*60);
try
    handles.current_frame_slider.SliderStep = [onesecond oneminute];
catch
end




handles.pixels_per_mm = pixels_per_mm;

XtickS = 1:pixels_per_cm*5:size(VidFrame,2);
YtickS = 1:pixels_per_cm*5:size(VidFrame,1);
handles.original_video_axes.XTick = XtickS;
handles.original_video_axes.YTick = YtickS;

handles.original_video_axes.FontSize = 8;

rescale_axes(handles.original_video_axes,CF);

guidata(hObject, handles);

return


function arena_folder_listbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function select_video_dir_button_Callback(hObject, eventdata, handles)

uiwait(msgbox(['Please select MAIN video directory'],'Select Dir','modal'));

folder_name = uigetdir(handles.video_dir_text.String,'select video file directory');
if folder_name
    handles.video_dir_text.String = folder_name;
    %
    %     D = dir([handles.video_dir_text.String filesep '*.mp4']);
    %     video_files = {D.name};
    %     handles.arena_folder_listbox.String = video_files;
    
    handles.arena_folder_listbox.Value = 1;
    arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles);
    
    
    arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles);    
    % save the directory as default for next time
    default_path_filename = [get_user_dir 'default_start_dir.mat'];
    save(default_path_filename,'folder_name')    
end

function calculate_mouse_positions_button_Callback(hObject, eventdata, handles)

function current_frame_edit_Callback(hObject, eventdata, handles)
editstr = get(handles.current_frame_edit,'String');

ok = check_framenum_string(editstr,1,handles.Nframes);
if ~ok
    errordlg(['frame number must be an integer between 1 and the ''end frame'' frame'],'frame range','modal');
    handles.current_frame_edit.String = '1';   
    handles.current_frame_slider.Value = 1;
    handles.current_time_edit.String = num2str(handles.data.SI,'%.2f');    
    return
end
handles.current_time_edit.String = num2str(str2num(editstr)*handles.data.SI,'%.2f');    
handles.current_frame_slider.Value = str2num(handles.current_frame_edit.String);
update_frame(handles);
zone_listbox_Callback(hObject, eventdata, handles)

function current_frame_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function current_frame_slider_Callback(hObject, eventdata, handles)
fn = round(get(hObject,'Value'));
handles.current_frame_edit.String = num2str(fn);
% Ca he frame callback wHich will update the image
current_frame_edit_Callback(hObject, eventdata, handles)


function current_frame_slider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function pushbutton8_Callback(hObject, eventdata, handles)



function new_zone_button_Callback(hObject, eventdata, handles,duplicate)
% Get the type of ROI to get
zone_type = handles.zone_type_menu.String{handles.zone_type_menu.Value};

% However, if we had the duplicate button we take the current object's type
if nargin == 4
    duplicate = 1;
    current_zone = handles.zone_listbox.String{handles.zone_listbox.Value};
    zone_names = {handles.zones.name};
    rel_ind = strcmp(current_zone,zone_names);
    zone_type = handles.zones(rel_ind).zone_type;
    orig_pos = getPosition(handles.zones(rel_ind).handle);
else
    duplicate = 0;
end


Xlimits = handles.original_video_axes.XLim;
Ylimits = handles.original_video_axes.YLim;
IW = range(Xlimits);
IH = range(Ylimits);
W = min(IW,IH);

switch zone_type
    case 'circle'
        if duplicate
            start_pos = orig_pos;
        else
            start_pos = [W/2-W/10, W/2-W/10, W/5, W/5];
        end
        zone_h = imellipse(handles.original_video_axes,start_pos);
        fixedRatio = 1;
        setFixedAspectRatioMode(zone_h,fixedRatio);
        constrain_type = 'imellipse';
    case 'ellipse'
        if duplicate
            start_pos = orig_pos;
        else
            start_pos = [IW/2-IW/10, IH/2-IH/10, IW/5, IH/5];
        end
        zone_h = imellipse(handles.original_video_axes,start_pos);
        fixedRatio = 0;
        constrain_type = 'imellipse';
    case 'rectangle'
        if duplicate
            start_pos = orig_pos;
        else
            start_pos = [IW/2-IW/10, IH/2-IH/10, IW/5, IH/5];
        end
        zone_h = imrect(handles.original_video_axes,start_pos);
        fixedRatio = 0;
        constrain_type = 'imrect';
    case 'square'
        if duplicate
            start_pos = orig_pos;
        else
            start_pos = [W/2-W/10, W/2-W/10, W/5, W/5];
        end
        zone_h = imrect(handles.original_video_axes,start_pos);
        fixedRatio = 1;
        setFixedAspectRatioMode(zone_h,fixedRatio);
        constrain_type = 'imrect';
    case 'polygon'
        if duplicate
            zone_h = impoly(handles.original_video_axes,orig_pos);
        else
            zone_h = impoly(handles.original_video_axes);
            if isempty(zone_h)
                delete(zone_h);
                return
            end
            zone_position = wait(zone_h);
            if isempty(zone_position)
                delete(zone_h);
                return
            end
        end
        fixedRatio = 0;
        constrain_type = 'impoly';
    case 'freehand'
        if duplicate
            zone_h = imfreehand(handles.original_video_axes,orig_pos);
        else
            zone_h = imfreehand(handles.original_video_axes);
            if isempty(zone_h)
                delete(zone_h);
                return
            end
            zone_position = wait(zone_h);
            if isempty(zone_position)
                delete(zone_h);
                return
            end
        end
        fixedRatio = 0;
        constrain_type = 'imfreehand'; % ybs 5/2/2017
end

constrain_fcn = makeConstrainToRectFcn(constrain_type,get(gca,'XLim'),get(gca,'YLim'));
setPositionConstraintFcn(zone_h,constrain_fcn); 


% allow deleting only through GUI, not by right click
zone_h.Deletable = false;

% Add zone to handle structure - 
handles = guidata(hObject);

zones = handles.zones;
zind = length(zones) + 1;

if ~(zind == 1) % IF not the first one
    zone_names = {zones.name};
    good_name = 0;
    % Find a zone namethat is not taken
    gnc = 0;
    while ~good_name
        proposed_name= ['zone ' num2str(zind+gnc)];
        if ~ismember(proposed_name,zone_names)
            good_name = 1;
        end
        gnc = gnc + 1;
    end    
else
    proposed_name = ['zone ' num2str(zind)];   
end
    
zones(zind).name  = proposed_name;

zones(zind).handle = zone_h;
zones(zind).fixedRatio = fixedRatio;
zones(zind).zone_type = zone_type;

zone_id = rand;
zones(zind).unique_id = zone_id;
handles.zones = zones;

% define a callback that will make it active
zonecb = @(pos) update_zone_positions(zone_h,pos,zone_id);
addNewPositionCallback(zone_h,zonecb);

% append zone name to list
% and make it current 
zone_list = handles.zone_listbox.String;
ll = length(zone_list);
zone_list{ll+1} = zones(zind).name;
handles.zone_listbox.String = zone_list;
handles.zone_listbox.Value = ll+1;


% Update handles structure
guidata(hObject, handles);

% to highlight the new zone
zone_listbox_Callback(hObject, eventdata, handles)



% --- Executes on selection change in zone_type_menu.
function zone_type_menu_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function zone_type_menu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function exclude_frames_checkbox_Callback(hObject, eventdata, handles)

function pushbutton11_Callback(hObject, eventdata, handles)

function zone_listbox_Callback(hObject, eventdata, handles)

if isempty(handles.zone_listbox.String)
    % reset zone based analysis
    handles.compare_zones_button.Enable = 'off';
    handles.zone_visit_stats_button.Enable = 'off';
    handles.zone_in_time_button.Enable = 'off';
    handles.zone_totals_button.Enable = 'off';
    handles.ignore_excluded_frames_checkbox.Enable = 'off';
    return
else
    handles.compare_zones_button.Enable = 'on';
    handles.zone_visit_stats_button.Enable = 'on';
    handles.zone_in_time_button.Enable = 'on';
    handles.zone_totals_button.Enable = 'on';
    handles.ignore_excluded_frames_checkbox.Enable = 'on';
end
    
    
current_zone = handles.zone_listbox.String{handles.zone_listbox.Value};
zone_names = {handles.zones.name};
rel_ind = strcmp(current_zone,zone_names);
setColor(handles.zones(rel_ind).handle,'r');

% update the position of the selected zone
zone_pos = getPosition(handles.zones(rel_ind).handle);

% Enter values in box
update_zone_pos(zone_pos,handles);

% Enable edit boxes if this is a rect or a circle
% disable otherwise
if size(zone_pos,2) == 4 % ellipse or rect
   enable_edits = 'on';
elseif size(zone_pos,2) == 2 % poly or freehand
   enable_edits = 'off';
end
handles.X_pos_edit.Enable = enable_edits;
handles.Y_pos_edit.Enable = enable_edits;
handles.width_edit.Enable = enable_edits;
handles.height_edit.Enable = enable_edits;

other_inds = find(~rel_ind);
for i = 1:length(other_inds)
    setColor(handles.zones(other_inds(i)).handle,'b'); 
end

guidata(hObject, handles);

function zone_listbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_zone_position_button_Callback(hObject, eventdata, handles)



function delete_zone_button_Callback(hObject, eventdata, handles)

if isempty(handles.zone_listbox.String)
    return
end
zone_strings = handles.zone_listbox.String;
current_zone = zone_strings{handles.zone_listbox.Value};
zone_names = {handles.zones.name};
rel_ind = strcmp(current_zone,zone_names);

zones = handles.zones;

% Remove it from the interface
delete(zones(rel_ind).handle);

% Remove the zone from the zone structure structure
zones(rel_ind) = [];
handles.zones = zones;


% remove the zone from the list
zone_strings(rel_ind) = [];
handles.zone_listbox.String = zone_strings;
% Make the last zone active
handles.zone_listbox.Value = length(zone_strings);
guidata(hObject, handles);

% and update the active region
zone_listbox_Callback(hObject, eventdata, handles)

return



function rename_zone_button_Callback(hObject, eventdata, handles)

if isempty(handles.zone_listbox.String)
    return
end

% active zone name from listbox
current_zone_name = handles.zone_listbox.String{handles.zone_listbox.Value};

% zone name index in structure
zones = handles.zones;
zone_names = {zones.name};
zone_name_ind = strcmp(current_zone_name,zone_names);

% Ask the user to give a new name
prompt = {['Enter new name for zone ' current_zone_name]};
dlg_title = 'rename zone';
num_lines = 1;
defaultans = {current_zone_name};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);

if isempty(answer) || isempty(answer{1})
    errordlg(['A name must be given for the Zone'],'Rename Method','modal');
    return
end

new_name = answer{1};

% return if name not changed
if strcmp(new_name,current_zone_name)    
    return
end
% return if name exists
if ismember(new_name,zone_names)    
    errordlg(['The name ' new_name ' is already taken, reverting to name ' current_zone_name])
    return
end

% Change the zone name in the list
zone_names_in_listbox = handles.zone_listbox.String;
zone_names_in_listbox{handles.zone_listbox.Value} = new_name;
handles.zone_listbox.String = zone_names_in_listbox;

% change name in structure
zones(zone_name_ind).name = new_name;

% Update name change
handles.zones = zones;
guidata(hObject, handles);

% --- Executes on button press in duplicate_zone_button.
function duplicate_zone_button_Callback(hObject, eventdata, handles)
if isempty(handles.zone_listbox.String)
    return
end
new_zone_button_Callback(hObject, eventdata, handles,1)

function save_zone_button_Callback(hObject, eventdata, handles,zonefilename)
save_zone_file(handles)


% --- Executes on button press in load_zone_button.
function load_zone_button_Callback(hObject, eventdata, handles)

 
% now delete the current zones if they are present, but ask the user about
% them
if ~isempty(handles.zones)
    ButtonName = questdlg('Current zones will be deleted. Continue?', ...
        'Analyze Behavior', ...
        'continue', 'cancel', 'cancel');
    switch ButtonName,
        case 'cancel',
            return
    end % switch
end


zone_dir = [handles.video_dir_text.String filesep 'zones'];

% default zone file:
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
[~,pos_file_name,~] = fileparts(position_file);
defaultzonefilename = [pos_file_name '_zones.mat'];
fullzonename = [zone_dir filesep defaultzonefilename];

if exist(fullzonename,'file')
    filterspec = fullzonename;
else
    filterspec = [zone_dir filesep '*zones*.mat'];
end

[zone_file, zone_path, ~] = uigetfile(filterspec, 'select zone file');
if ~zone_file
    return
end
fullzonename = [zone_path zone_file];

zD = load(fullzonename);
new_pixels_per_mm = zD.arena_data.pixels_per_mm;

% it cannot be empty because otherwise we would not have saved it, 
% but we will check anyway
new_zones = zD.saved_zones;
if isempty(new_zones)
    return
end

contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];

pD = load(position_file);
orig_pixels_per_mm = pD.arena_data.pixels_per_mm;

new_mm_per_pixels = 1 /new_pixels_per_mm;
orig_mm_per_pixels = 1 /orig_pixels_per_mm;

mag_ratio = new_mm_per_pixels / orig_mm_per_pixels;

if ~(mag_ratio==1)
        warnstr{1} = 'Loaded zones were defined on an image with a different scale';
        warnstr{2} = 'Normalizing dimensions to fit new arena';
        warnstr{3} = 'Roundoff errors may occur';        
        warnstr{4} = 'Relative position on arena could change';        
        warnstr{5} = 'Images may appear outside of arena';        
        warnstr{6} = 'zone positions will not be constrained within arena limits!';        
        warndlg(warnstr, 'Load Zones', 'modal');        
end
       
% delete all present zones
present_zones = handles.zones;
for i = 1:length(present_zones)
% Remove it from the interface
    delete(present_zones(i).handle);
end

% Remove the zone from the zone structure structure
handles.zones = [];
% remove the zone from the list
handles.zone_listbox.String = '';
% updadte
guidata(hObject, handles);


% now we put the zones on the arena
% We need some error checking
% check that pixel ratio is the same - at least warn if not
% also warn if not defined on same dimensions
for i = 1:length(new_zones)
    
    % Get the type of ROI to get
    zone_type = new_zones(i).zone_type;
  
    new_pos = mag_ratio*new_zones(i).positions;
    
    switch zone_type
        case {'circle','ellipse'}
            zone_h = imellipse(handles.original_video_axes,new_pos);
            setFixedAspectRatioMode(zone_h,new_zones(i).fixedRatio);
            fixedRatio = new_zones(i).fixedRatio;
            constrain_type = 'imellipse';
        case {'rectangle','square'}
            zone_h = imrect(handles.original_video_axes,new_pos);
            setFixedAspectRatioMode(zone_h,new_zones(i).fixedRatio);
            fixedRatio = new_zones(i).fixedRatio;
            constrain_type = 'imrect';
        case 'polygon'
            zone_h = impoly(handles.original_video_axes,new_pos);
            fixedRatio = new_zones(i).fixedRatio;
            constrain_type = 'impoly';
        case 'freehand'
            zone_h = imfreehand(handles.original_video_axes,new_pos);
            fixedRatio = new_zones(i).fixedRatio;
            constrain_type = 'imfreehand';
    end       
    
    % Setting a position constrain function when zones are defined on a
    % different arena makes no sense, and requires fancy error handling.
    if (mag_ratio==1)
        constrain_fcn = makeConstrainToRectFcn(constrain_type,get(gca,'XLim'),get(gca,'YLim'));
        setPositionConstraintFcn(zone_h,constrain_fcn);
    end
%     
    % allow deleting only through GUI, not by right click
    zone_h.Deletable = false;
    % Add zone to handle structure -
    handles = guidata(hObject);
    
    zones = handles.zones;
    zind = length(zones) + 1;
    
    zones(zind).name = new_zones(i).name;
    zones(zind).handle = zone_h;
    zones(zind).fixedRatio = fixedRatio;
    zones(zind).zone_type = zone_type;
    
    zone_id = rand;
    zones(zind).unique_id = zone_id;
    handles.zones = zones;
    
    % define a callback that will make it active
    zonecb = @(pos) update_zone_positions(zone_h,pos,zone_id); 
    addNewPositionCallback(zone_h,zonecb);
        
    
    % append zone name to list
    % and make it current
    % zone_list =
    zone_list = handles.zone_listbox.String;
    ll = length(zone_list);
    zone_list{ll+1} = zones(zind).name;
    handles.zone_listbox.String = zone_list;
    handles.zone_listbox.Value = ll+1;
       
    % Update handles structure
    guidata(hObject, handles);
    
end

% to highlight the new zone
zone_listbox_Callback(hObject, eventdata, handles)






function X_pos_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)


function X_pos_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Y_pos_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function Y_pos_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function width_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function width_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function height_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)


function height_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function file_name_filter_edit_Callback(hObject, eventdata, handles)
handles.arena_folder_listbox.Value = 1;
arena_folder_listbox_Callback(hObject, eventdata, handles)


function file_name_filter_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function smooth_window_seconds_edit_Callback(hObject, eventdata, handles)
% hObject    handle to smooth_window_seconds_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smooth_window_seconds_edit as text
%        str2double(get(hObject,'String')) returns contents of smooth_window_seconds_edit as a double


% --- Executes during object creation, after setting all properties.
function smooth_window_seconds_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smooth_window_seconds_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function max_speed_edit_Callback(hObject, eventdata, handles)
% hObject    handle to max_speed_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of max_speed_edit as text
%        str2double(get(hObject,'String')) returns contents of max_speed_edit as a double


% --- Executes during object creation, after setting all properties.
function max_speed_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_speed_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function speed_histogram_resolution_Callback(hObject, eventdata, handles)
% hObject    handle to speed_histogram_resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of speed_histogram_resolution as text
%        str2double(get(hObject,'String')) returns contents of speed_histogram_resolution as a double


% --- Executes during object creation, after setting all properties.
function speed_histogram_resolution_CreateFcn(hObject, eventdata, handles)
% hObject    handle to speed_histogram_resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_zones_checkbox.
function save_zones_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to save_zones_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of save_zones_checkbox



function heat_map_resolution_edit_Callback(hObject, eventdata, handles)
% hObject    handle to heat_map_resolution_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of heat_map_resolution_edit as text
%        str2double(get(hObject,'String')) returns contents of heat_map_resolution_edit as a double


% --- Executes during object creation, after setting all properties.
function heat_map_resolution_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to heat_map_resolution_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function heat_map_std_range_edit_Callback(hObject, eventdata, handles)
% hObject    handle to heat_map_std_range_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of heat_map_std_range_edit as text
%        str2double(get(hObject,'String')) returns contents of heat_map_std_range_edit as a double


% --- Executes during object creation, after setting all properties.
function heat_map_std_range_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to heat_map_std_range_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function experiment_tags_edit_Callback(hObject, eventdata, handles)
% check validity of tags entered in analysis GUI

% check the string in the file
exp_tags = strsplit(handles.experiment_tags_edit.String);

% no need checking further if the edit box is empty
if isempty(exp_tags)
    return
end

user_dir = get_user_dir;
tag_file = [user_dir 'optimouse_experiment_tags.txt'];


% read the tags in the text file
fileID = fopen(tag_file,'r');
C = textscan(fileID,'%s');
fclose(fileID);
valid_tags = C{1};

% check which edit box tags are in the tag file -  and inform the user if they
% are missing
for i = 1:length(exp_tags)
    if ~ismember(exp_tags{i},valid_tags)
        error_str{1} = ['string ''' exp_tags{i} ''' is not a valid experimental tag'];
        error_str{2} = ['and will not be saved!'];
        error_str{3} = ['tags must be specified in file:'];
        error_str{4} = [tag_file];
        errordlg(error_str,'experimental tags');
    end
end

return



% --- Executes during object creation, after setting all properties.
function experiment_tags_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to experiment_tags_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function user_comment_edit_Callback(hObject, eventdata, handles)
% hObject    handle to user_comment_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of user_comment_edit as text
%        str2double(get(hObject,'String')) returns contents of user_comment_edit as a double


% --- Executes during object creation, after setting all properties.
function user_comment_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to user_comment_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function current_time_edit_Callback(hObject, eventdata, handles)

framestr = get(handles.current_frame_edit,'String');
frametimestr = get(handles.current_time_edit,'String');

ok = check_frametime_string(frametimestr,0,handles.data.duration);
if ~ok
    errordlg(['Time value valid or out of movie range'],'frame range','modal');
    hObject.String = num2str(str2num(framestr)*handles.data.SI, '%.2f');
    return
end

frametime = str2num(frametimestr);

% find the closest time to this frame
all_times = [1:handles.data.nframes]*handles.data.SI;
[~,fn] = min(abs(all_times - frametime));

handles.current_frame_edit.String = num2str(fn);
current_frame_edit_Callback(hObject, eventdata, handles);



% --- Executes during object creation, after setting all properties.
function current_time_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to current_time_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ButtonName = questdlg('Really close? Any unsaved settings will be erased. Continue?', ...
    'Optimouse', 'Cancel', 'Close', 'Cancel');
if strcmp(ButtonName,'Cancel')
        return        
end
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in exclude_nan_frames_checkbox.
function exclude_nan_frames_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to exclude_nan_frames_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of exclude_nan_frames_checkbox


% --- Executes on button press in ignore_excluded_frames_checkbox.
function ignore_excluded_frames_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to ignore_excluded_frames_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ignore_excluded_frames_checkbox






% --- Executes on button press in distance_button.
function distance_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function show_tracks_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)



function body_angle_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function heat_map_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function speed_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function zone_totals_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function zone_in_time_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function compare_zones_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function zone_visit_stats_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function general_event_stats_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function events_in_time_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function events_as_position_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function events_in_zones_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function save_to_mat_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)

function show_result_in_cmd_line_button_Callback(hObject, eventdata, handles)
run_position_and_zone_analysis(handles,hObject)
