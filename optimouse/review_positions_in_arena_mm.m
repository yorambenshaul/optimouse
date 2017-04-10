function varargout = review_positions_in_arena_mm(varargin)
% YBS 9/16
% REVIEW_POSITIONS_IN_ARENA_MM MATLAB code for review_positions_in_arena_mm.fig
%      REVIEW_POSITIONS_IN_ARENA_MM, by itself, creates a new REVIEW_POSITIONS_IN_ARENA_MM or raises the existing
%      singleton*.
%
%      H = REVIEW_POSITIONS_IN_ARENA_MM returns the handle to a new REVIEW_POSITIONS_IN_ARENA_MM or the handle to
%      the existing singleton*.
%
%      REVIEW_POSITIONS_IN_ARENA_MM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REVIEW_POSITIONS_IN_ARENA_MM.M with the given input arguments.
%
%      REVIEW_POSITIONS_IN_ARENA_MM('Property','Value',...) creates a new REVIEW_POSITIONS_IN_ARENA_MM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before review_positions_in_arena_mm_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to review_positions_in_arena_mm_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help review_positions_in_arena_mm

% Last Modified by GUIDE v2.5 09-Nov-2016 14:03:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @review_positions_in_arena_mm_OpeningFcn, ...
    'gui_OutputFcn',  @review_positions_in_arena_mm_OutputFcn, ...
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


% --- Executes just before review_positions_in_arena_mm is made visible.
function review_positions_in_arena_mm_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to review_positions_in_arena_mm (see VARARGIN)

% save the directory as default for next time
default_path_filename = [get_user_dir 'default_start_dir.mat'];
if exist(default_path_filename) == 2
    D = load(default_path_filename,'folder_name');
    handles.video_dir_text.String = D.folder_name;
end

% colors for each of the methods
method_col(1,:) = [0.4 0.6 1];
method_col(2,:) = [0 1 0];
method_col(3,:) = [1 0.6 0.6];
method_col(4,:) = [0 1 1];
method_col(5,:) = [1 0 0];
method_col(6,:) = [1 0 1];
method_col(10,:) = [1 0.843 0]; % user defined
method_col(11,:) = [0.5 0.5 0.5]; % excluded
method_col(12,:) = [0.871 0.49 0]; % auto interpolated
method_col(13,:) = [0.231 0.443 0.337]; % manual interpolated - not implemented
handles.method_col = method_col;

% plot the colors (for debugging)
% figure
% for i = 1:length(method_col)
%     bh = bar(i,1);
%     hold on
%     set(bh,'facecolor',method_col(i,:))
% end
% set(gca,'xtick',1:length(method_col));


handles.play_dir = 1;

handles.current_arena_folder_listbox_selection = '';

% Update handles structure
guidata(hObject, handles);


arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles)

% handles have to be updated after call
handles = guidata(hObject);
% Choose default command line output for review_positions_in_arena_mm
handles.output = hObject;
% define keypress functions
set(handles.figure1,'WindowKeyPressFcn', {@review_positions_keyPress,hObject,eventdata,handles});
% Update handles structure
guidata(hObject, handles);




% UIWAIT makes review_positions_in_arena_mm wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = review_positions_in_arena_mm_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in arena_folder_listbox.
function arena_folder_listbox_Callback(hObject, eventdata, handles)

% if this is not the first time, check if we changed the value
contents =         cellstr(get(handles.arena_folder_listbox,'String'));
if ~isempty(handles.current_arena_folder_listbox_selection) && ~isempty(contents)
    selected =         contents{get(handles.arena_folder_listbox,'Value')} ;    
    % if we selected something else, and that something is still on the
    % list
    if ~strcmp(handles.current_arena_folder_listbox_selection,selected) & ismember(handles.current_arena_folder_listbox_selection,contents)        
        ButtonName = questdlg('Sure you want to move to a new file? Any unsaved settings will be erased. Continue?', ...
            'Review Positions', ...
            'Continue', 'Cancel', 'Cancel');
        switch ButtonName,
            % If we do not want to change the file we go back to the
            % original file. THe list may have changed though, due to
            % filtering, hence we use the ismember here
            case 'Cancel'                
                hObject.Value = find(ismember(contents,handles.current_arena_folder_listbox_selection));
                return
        end
    end
end


cla(handles.original_video_axes)
cla(handles.parameter_axes)
handles.stop_if_above_edit.String = '';

D = dir([handles.video_dir_text.String filesep 'positions' filesep '*_arena*.mat']);

% keep only direcotories
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
    errordlg(['Arena file for selected position file not found'],'Review Positions','modal');
    return
end
iD = load([handles.video_dir_text.String filesep 'arenas' filesep info_file(1).name]);


% only if we got thtough to these stages, we have to update the value
handles.current_arena_folder_listbox_selection = contents{get(handles.arena_folder_listbox,'Value')};


if isfield(iD,'user_string')
    handles.user_comment_edit.String = iD.user_string;
else
    handles.user_comment_edit.String = '';
end


vid_duration = iD.FrameInfo(end,3);
Nframes = size(iD.FrameInfo,1);

pD = load(position_file);

% we either have none, or all
if ~isfield(pD,'user_defined_nosePOS')
    handles.user_defined_mouse_angle  = nan(size(pD.position_results(1).mouse_angle));
    handles.user_defined_nosePOS = nan(size(pD.position_results(1).nosePOS));
    handles.user_defined_mouseCOM = nan(size(pD.position_results(1).nosePOS));
    handles.interpolated_body_position = nan(size(pD.position_results(1).nosePOS));
    handles.interpolated_nose_position = nan(size(pD.position_results(1).nosePOS));
    handles.interpolated_mouse_angle = nan(size(pD.position_results(1).mouse_angle));
else
    handles.user_defined_mouse_angle  = pD.user_defined_mouse_angle;
    handles.user_defined_nosePOS = pD.user_defined_nosePOS;
    handles.user_defined_mouseCOM = pD.user_defined_mouseCOM;
    handles.interpolated_body_position = pD.interpolated_body_position;
    handles.interpolated_nose_position = pD.interpolated_nose_position;
    handles.interpolated_mouse_angle = pD.interpolated_mouse_angle;
end
% This should be present always from now on
if isfield(pD,'frame_class')
    handles.frame_class = pD.frame_class;
else
    % Which means that we make the first method the default one - which
    % kinda makes sense
    handles.frame_class = ones(1,Nframes);
end


% check for an annotation file
found_annotation = 0;
if exist('user_annotation_events') == 2
    annot_events = user_annotation_events;
    if ~isempty(annot_events)
        % Get field names
        % annot_fields = fieldnames(annotations);
        handles.annotation_menu.String = annot_events;
        found_annotation = 1;
    end
    handles.annotation_menu.Enable = 'on';
    handles.apply_annotation_to_frame_button.Enable  = 'on';
    handles.apply_annotation_to_segment_button.Enable  = 'on';
    handles.remove_annotation_from_segment_button.Enable  = 'on';
    handles.remove_annotation_to_frame_button.Enable  = 'on';
else
    msgstr{1} = 'User list of annotated events empty (or file not found)';
    msgstr{2} = 'These can be defined in';
    msgstr{3} = '''user_annotation_events.m''';
    msgbox(msgstr,'Review Positions')
    handles.annotation_menu.Enable = 'off';
    handles.apply_annotation_to_frame_button.Enable  = 'off';
    handles.apply_annotation_to_segment_button.Enable  = 'off';
    handles.remove_annotation_from_segment_button.Enable  = 'off';
    handles.remove_annotation_to_frame_button.Enable  = 'off';
end

% Check for annotation variables - load or add them
if found_annotation && ~isfield(pD,'annotations')
    annotations = [];
    annot_events = user_annotation_events;    
    if ~isempty(annot_events)
        for i = 1:length(annot_events)
            if ~isfield(annotations,annot_events{i})
                eval(['annotations.' annot_events{i} ' = sparse(1,Nframes);']);
            end
        end
    end
else
    % otherwise, we already have the field names
    % we assume they are the same as those in the list, otherwise, erros
    % may occur
    annotations = pD.annotations;
end

% update the handles structure
handles.annotations = annotations;

Nframes = size(iD.FrameInfo,1);
handles.Nframes = Nframes;

% time data for converting time to frames
data.duration = iD.FrameInfo(end,3);
data.SI       = diff(iD.FrameInfo(1:2,3));
data.nframes  = Nframes;
handles.data = data;


handles.frame_select_slider.Max = Nframes;
handles.frame_select_slider.Min = 1;
handles.frame_select_slider.Value = 1;
% set the slider step for a second a minute
onesecond = (1/data.duration); 
oneminute = (onesecond*60); 
try
handles.frame_select_slider.SliderStep = [onesecond oneminute];
catch
end

handles.current_frame_edit.String = '1';
handles.current_time_edit.String = num2str(data.SI,'%.2f');

% start the frame subset variable
frame_subset_to_show = false(size(handles.frame_class));
handles.frame_subset_to_show = frame_subset_to_show;


handles.show_selected_checkbox.Enable = 'off';
handles.stop_playback_checkbox.Enable = 'off';
handles.previous_abovethresh_button.Enable = 'off';
handles.next_abovethresh_button.Enable = 'off';
handles.show_selected_checkbox.Value = 0;
handles.stop_playback_checkbox.Value = 0;
handles.n_selected_text.String = ['0 frames marked'];



n_methods = length(pD.detection_methods);
% there is a maximum of 6 methods (limit is set by number of buttons in the GUI, but this
% seems to be more than enough
n_methods = min(n_methods,6);

method_names = {pD.detection_methods.name};

% 
for i = 1:6
    eval(['handles.classify_method' num2str(i) '_button.Visible = ''off'';'])
    eval(['handles.classify_method' num2str(i) '_button.Enable = ''off'';'])    
    eval(['handles.setframeas_method' num2str(i) '_button.Enable = ''off'';'])
    eval(['handles.setframeas_method' num2str(i) '_button.Visible = ''off'';'])    
end
for i = 1:n_methods
    eval(['handles.classify_method' num2str(i) '_button.Visible = ''on'';'])
    eval(['handles.classify_method' num2str(i) '_button.Enable = ''on'';'])
    eval(['handles.classify_method' num2str(i) '_button.String = ''' method_names{i} ''';'])
    eval(['handles.setframeas_method' num2str(i) '_button.Enable = ''on'';'])
    eval(['handles.setframeas_method' num2str(i) '_button.Visible = ''on'';'])
    eval(['handles.setframeas_method' num2str(i) '_button.String = ''' method_names{i} ''';'])
end



handles.x_axes_method_menu.String = method_names;
handles.y_axes_method_menu.String = method_names;

% Set the strings in the display menu
show_menu_string{1} = 'nose position';
show_menu_string{2} = 'body position';
show_menu_string{3} = 'active setting';
show_menu_string{4} = 'angle change';
show_menu_string{5} = 'mouse angle';
show_menu_string{6} = 'body speed';
show_menu_string{7} = 'nose speed';
if found_annotation
    show_menu_string{8} = 'annotated events';
    show_menu_string{9} = 'parameter pairs';
else
    show_menu_string{8} = 'parameter pairs';
end

handles.show_menu.Value = 1;
handles.show_menu.String = show_menu_string;

% disable the param pair axes, (until they are chosen)
handles.x_axes_parameter_menu.Enable = 'off';
handles.x_axes_method_menu.Enable = 'off';
handles.y_axes_parameter_menu.Enable = 'off';
handles.y_axes_method_menu.Enable = 'off';

% reset the values for all these menus to 1
handles.x_axes_parameter_menu.Value = 1;
handles.x_axes_method_menu.Value = 1;
handles.y_axes_parameter_menu.Value = 1;
handles.y_axes_method_menu.Value = 1;



% Get the first frame file (there should be only one)
frame_file = dir([handles.video_dir_text.String filesep base_name filesep '*_frames_*_1.mat']);

if isempty(frame_file)
    return
end

fD = load([handles.video_dir_text.String filesep base_name filesep frame_file.name]);
VidFrame = fD.ROI_tmp_frames(:,:,1);

axes(handles.original_video_axes)
imagesc(VidFrame);
colormap gray
axis equal;
axis tight
hold on
ylabel('cm')    ;
% % Show axes in cm
pixels_per_mm = iD.pixels_per_mm;
pixels_per_cm = 10*pixels_per_mm;
CF =  1/pixels_per_cm;

for xi = 1:length(handles.original_video_axes.XTick)
    newXticklabels{xi} = num2str(round(handles.original_video_axes.XTick(xi)*CF));
end

for yi = 1:length(handles.original_video_axes.YTick)
    newYticklabels{yi} = num2str(round(handles.original_video_axes.YTick(yi)*CF));
end

handles.original_video_axes.XTickLabel = newXticklabels;
handles.original_video_axes.YTickLabel = newYticklabels;

% reset the frame selection edit box
handles.exclude_frames_by_number_edit.String = '';

% This is a way to get fieldnames, but it is better to define
% specific field names as are defined here
% base_fieldnames = fieldnames(pD.position_results);

% Define field names in the pop up menus
X_FieldNames{1} = 'body x';
X_FieldNames{2} = 'body y';
X_FieldNames{3} = 'nose x';
X_FieldNames{4} = 'nose y';
X_FieldNames{5} = 'grey threshold';
X_FieldNames{6} = 'trim factor';
X_FieldNames{7} = 'mouse area';
X_FieldNames{8} = 'mouse length';
X_FieldNames{9} = 'mouse angle';
X_FieldNames{10} = 'mouse perimeter';
X_FieldNames{11} = 'thinned mouse perimeter';
X_FieldNames{12} = 'perimeter ratio';
X_FieldNames{13} = 'background intensity (mean)';
X_FieldNames{14} = 'mouse intensity mean';
X_FieldNames{15} = 'mouse intensity var';
X_FieldNames{16} = 'mouse intensity range';
X_FieldNames{17} = 'frame number';

Y_FieldNames{1} = 'body x';
Y_FieldNames{2} = 'body y';
Y_FieldNames{3} = 'nose x';
Y_FieldNames{4} = 'nose y';
Y_FieldNames{5} = 'grey threshold';
Y_FieldNames{6} = 'trim factor';
Y_FieldNames{7} = 'mouse area';
Y_FieldNames{8} = 'mouse length';
Y_FieldNames{9} = 'mouse angle';
Y_FieldNames{10} = 'mouse perimeter';
Y_FieldNames{11} = 'thinned mouse perimeter';
Y_FieldNames{12} = 'perimeter ratio';
Y_FieldNames{13} = 'background intensity (mean)';
Y_FieldNames{14} = 'mouse intensity mean';
Y_FieldNames{15} = 'mouse intensity var';
Y_FieldNames{16} = 'mouse intensity range';
Y_FieldNames{17} = 'frame number';



% handles.select_param_menu.String = FieldNames;
handles.x_axes_parameter_menu.String = X_FieldNames;
handles.y_axes_parameter_menu.String = Y_FieldNames;

% This will initialize as a body X body Y spatial plot
handles.x_axes_parameter_menu.Value = 1;
% This will put the curent nose position sot hat the x VAlue is irrlevant
% actually
handles.y_axes_parameter_menu.Value = 2;



method_names{10} = 'user defined';
method_names{11} = 'excluded';
method_names{12} = 'interpolated';
method_names{13} = 'interpolated (manual)';

handles.method_names = method_names;

% for saving the zoom setting ont he dot display axes
handles.hold_dotdisplay_zoom = 0;



% if they do not already exist, set the limits for all parameters in the
% position file
guidata(handles.figure1,handles);

update_position_histograms_mm(handles);
handles = guidata(handles.figure1);
replay_calculated_positions_mm(handles.figure1,handles,2);

handles = guidata(handles.figure1);

guidata(handles.figure1, handles);

return % end of list box callback

% --- Executes during object creation, after setting all properties.
function arena_folder_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to arena_folder_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function arena_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to arena_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in select_video_dir_button.
function select_video_dir_button_Callback(hObject, eventdata, handles)
% hObject    handle to select_video_dir_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiwait(msgbox(['Please select MAIN video directory'],'Select Dir','modal'));

folder_name = uigetdir(handles.video_dir_text.String,'select video file directory');
if folder_name
    handles.video_dir_text.String = folder_name;
    %     D = dir([handles.video_dir_text.String filesep '*.mp4']);
    %     video_files = {D.name};
    %     handles.arena_folder_listbox.String = video_files;
    %     arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles);
    handles.arena_folder_listbox.Value = 1;
    arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles);
    % save the directory as default for next time
    default_path_filename = [get_user_dir 'default_start_dir.mat'];
    save(default_path_filename,'folder_name')
end


% --- Executes on button press in play_pause_toggle.
function play_pause_toggle_Callback(hObject, eventdata, handles)

% If not running
if strcmp(handles.play_pause_toggle.String,'PLAY')
    handles.play_dir = 1;
    %handles.play_pause_toggle.Value = 1;
    handles.do_play   = 1;    
    handles.play_pause_toggle.String = 'PAUSE';
    handles.PLAYBACK_BUTTON.Enable = 'off';    
    % disable dot display menus
    handles.show_menu.Enable = 'off';
    handles.x_axes_method_menu.Enable = 'off';
    handles.x_axes_parameter_menu.Enable = 'off';
    handles.y_axes_method_menu.Enable = 'off';
    handles.y_axes_parameter_menu.Enable = 'off';
    %guidata(hObject);
    % Update handles structure
    guidata(hObject, handles);
    replay_calculated_positions_mm(hObject,handles,0);
elseif strcmp(handles.play_pause_toggle.String,'PAUSE')    
    %handles.play_pause_toggle.Value = 0;
    handles.do_play   = 0;
    handles.play_pause_toggle.String = 'PLAY';
    handles.PLAYBACK_BUTTON.Enable = 'on';  
    % enable dot display menus
    handles.show_menu.Enable = 'on';
    contents = cellstr(get(handles.show_menu,'String'));
    selection = contents{get(handles.show_menu,'Value')};
    if strmatch(selection,'parameter pairs','exact')
        handles.x_axes_method_menu.Enable = 'on';
        handles.x_axes_parameter_menu.Enable = 'on';
        handles.y_axes_method_menu.Enable = 'on';
        handles.y_axes_parameter_menu.Enable = 'on';
    end    
    guidata(hObject, handles);
    % guidata(hObject);
end




function down_sample_factor_edit_Callback(hObject, eventdata, handles)
content = handles.down_sample_factor_edit.String;
val = str2num(content);
if ~(length(val) == 1)
    errordlg(['value must be an integer larger than 0'],'skip frames','modal');
    handles.down_sample_factor_edit.String = '1';
    return
end
if val < 1
    errordlg(['value must be an integer larger than 0'],'skip frames','modal');
    handles.down_sample_factor_edit.String = '1';
    return
end
if rem(val,1)
    errordlg(['value must be an integer larger than 0'],'skip frames','modal');
    handles.down_sample_factor_edit.String = '1';
    return
end

% --- Executes during object creation, after setting all properties.
function down_sample_factor_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to down_sample_factor_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function pause_between_frames_edit_Callback(hObject, eventdata, handles)
content = handles.pause_between_frames_edit.String;
val = str2num(content);
if ~(length(val) == 1)
    errordlg(['value must be numerical between 0 and 1'],'delay','modal');
    handles.pause_between_frames_edit.String = '0';
    return
end
if val > 1
    errordlg(['value must be numerical between 0 and 1'],'delay','modal');
    handles.pause_between_frames_edit.String = '1';
    return
end
if val < 0 
    errordlg(['value must be numerical between 0 and 1'],'delay','modal');
    handles.pause_between_frames_edit.String = '0';
    return
end



% --- Executes during object creation, after setting all properties.
function pause_between_frames_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pause_between_frames_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called





% --- Executes during object creation, after setting all properties.
function bad_segment_length_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bad_segment_length_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function file_name_filter_edit_Callback(hObject, eventdata, handles)
handles.arena_folder_listbox.Value = 1;
arena_folder_listbox_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function file_name_filter_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_name_filter_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in x_axes_parameter_menu.
function x_axes_parameter_menu_Callback(hObject, eventdata, handles)
update_position_histograms_mm(handles)

% --- Executes during object creation, after setting all properties.
function x_axes_parameter_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x_axes_parameter_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in y_axes_method_menu.
function y_axes_method_menu_Callback(hObject, eventdata, handles)
update_position_histograms_mm(handles)

% --- Executes during object creation, after setting all properties.
function y_axes_method_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y_axes_method_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in x_axes_method_menu.
function x_axes_method_menu_Callback(hObject, eventdata, handles)
update_position_histograms_mm(handles)

% --- Executes during object creation, after setting all properties.
function x_axes_method_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x_axes_method_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in y_axes_parameter_menu.
function y_axes_parameter_menu_Callback(hObject, eventdata, handles)
update_position_histograms_mm(handles)

% --- Executes during object creation, after setting all properties.
function y_axes_parameter_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y_axes_parameter_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in show_method_details_button.
function show_method_details_button_Callback(hObject, eventdata, handles)
show_method_details(handles)

% --- Executes on button press in classify_method1_button.
function classify_method1_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,1)

% --- Executes on button press in classify_method2_button.
function classify_method2_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,2)

% --- Executes on button press in classify_method3_button.
function classify_method3_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,3)

% --- Executes on button press in classify_method4_button.
function classify_method4_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,4)

% --- Executes on button press in classify_method5_button.
function classify_method5_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,5)

% --- Executes on button press in classify_method6_button.
function classify_method6_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,6)

% --- Executes on button press in classify_exclude_button.
function classify_exclude_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,11)


% --- Executes on mouse press over axes background.
function parameter_axes_ButtonDownFcn(hObject, eventdata, handles)
% define callback function for the parameter axis
%set(handles.parameter_axes,'ButtonDownFcn', {@getCurrentFrame, handles.figure1});
getCurrentFrame(handles);


% --- Executes on button press in setframeas_method1_button.
function setframeas_method1_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,1)

% --- Executes on button press in setframeas_method2_button.
function setframeas_method2_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,2)

% --- Executes on button press in setframeas_method3_button.
function setframeas_method3_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,3)

% --- Executes on button press in setframeas_method4_button.
function setframeas_method4_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,4)

% --- Executes on button press in setframeas_method5_button.
function setframeas_method5_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,5)

% --- Executes on button press in setframeas_method6_button.
function setframeas_method6_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,6)

% --- Executes on button press in frame_exclude_button.
function frame_exclude_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,11)



function current_frame_edit_Callback(hObject, eventdata, handles)

editstr = get(handles.current_frame_edit,'String');

ok = check_framenum_string(editstr,1,handles.Nframes);
if ~ok
    errordlg(['frame number must be an integer between 1 and the ''end frame'' frame'],'frame range','modal');
    handles.frame_select_slider.Value = 1;
    handles.current_time_edit.String = num2str(handles.data.SI,'%.2f');            
    handles.current_frame_edit.String = '1';
    return
end

replay_calculated_positions_mm(handles.current_frame_edit,handles,2);

% --- Executes during object creation, after setting all properties.
function current_frame_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to current_frame_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function frame_select_slider_Callback(hObject, eventdata, handles)
frameval = get(hObject,'Value');
frameval = round(frameval);
handles.current_frame_edit.String = num2str(frameval);
guidata(hObject, handles);
replay_calculated_positions_mm(hObject,handles,2);


% --- Executes during object creation, after setting all properties.
function frame_select_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frame_select_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in previous_frame_button.
function previous_frame_button_Callback(hObject, eventdata, handles)
this_frame = str2num(handles.current_frame_edit.String);
if this_frame > 1
    prev_frame = this_frame - 1;
    handles.current_frame_edit.String = num2str(prev_frame);
    guidata(hObject, handles);
    replay_calculated_positions_mm(hObject,handles,2);
end


% --- Executes on button press in next_frame_button.
function next_frame_button_Callback(hObject, eventdata, handles)
this_frame = str2num(handles.current_frame_edit.String);
if this_frame < handles.Nframes
    next_frame = this_frame + 1;
    handles.current_frame_edit.String = num2str(next_frame);
    guidata(hObject, handles);
    replay_calculated_positions_mm(hObject,handles,2);
end



% --- Executes on button press in set_manual_position_button.
function set_manual_position_button_Callback(hObject, eventdata, handles)
set_manual_position(handles)


% --- Executes on button press in zoom_in_on_mouse_button.
function zoom_in_on_mouse_button_Callback(hObject, eventdata, handles)
zoom_on_review_axes(handles.original_video_axes);


% --- Executes on button press in reset_zoom_button.
function reset_zoom_button_Callback(hObject, eventdata, handles)
replay_calculated_positions_mm(handles.figure1,handles,2);


% --- Executes on button press in zoom_in_on_params_button.
function zoom_in_on_params_button_Callback(hObject, eventdata, handles)
zoom_on_review_axes(handles.parameter_axes);
handles.hold_dotdisplay_zoom = 1;
handles.hold_xlims = handles.parameter_axes.XLim;
handles.hold_ylims = handles.parameter_axes.YLim;
guidata(handles.figure1,handles);




% --- Executes on button press in reset_zoom_in_on_params_button.
function reset_zoom_in_on_params_button_Callback(hObject, eventdata, handles)
handles.hold_dotdisplay_zoom = 0;
guidata(handles.figure1,handles);
update_position_histograms_mm(handles);


% --- Executes on button press in select_frames_to_show_button.
function select_frames_to_show_button_Callback(hObject, eventdata, handles)
define_points_by_polygon(handles,2807);


% --- Executes on button press in show_selected_checkbox.
function show_selected_checkbox_Callback(hObject, eventdata, handles)
handles.suppress_line_update = 1;
guidata(handles.figure1,handles);
update_position_histograms_mm(handles)




% --- Executes during object creation, after setting all properties.
function minimal_transition_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minimal_transition_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setframeas_interpolated_button.
function setframeas_interpolated_button_Callback(hObject, eventdata, handles)
set_frame_as_class(handles,12)


% --- Executes on button press in segment_start_button.
function segment_start_button_Callback(hObject, eventdata, handles)
handles.segment_start_text.String = handles.current_frame_edit.String;

% --- Executes on button press in segment_end_button.
function segment_end_button_Callback(hObject, eventdata, handles)
handles.segment_end_text.String = handles.current_frame_edit.String;

% --- Executes on button press in manual_interpolation_button.
function manual_interpolation_button_Callback(hObject, eventdata, handles)
interpolate_positions_manually(handles)


% --- Executes on button press in reverse_checkbox.
function reverse_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to reverse_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reverse_checkbox


% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)

% Get the position file
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];

pD = load(position_file);

% get the relevant fields
frame_class = handles.frame_class;
user_defined_mouse_angle = handles.user_defined_mouse_angle;
user_defined_nosePOS     = handles.user_defined_nosePOS;
user_defined_mouseCOM = handles.user_defined_mouseCOM;
interpolated_body_position = handles.interpolated_body_position;
interpolated_nose_position = handles.interpolated_nose_position;
interpolated_mouse_angle = handles.interpolated_mouse_angle;


% start with body position
final_nose_positions = nan(size(pD.position_results(1).mouseCOM));
final_body_positions = nan(size(pD.position_results(1).mouseCOM));
final_mouse_angles = nan(1,length(pD.position_results(1).BackGroundMean));

n_methods = length(pD.detection_methods);
for mi = 1:n_methods
    these_inds = find(handles.frame_class == mi);
    final_nose_positions(these_inds,:) = pD.position_results(mi).nosePOS(these_inds,:);
    final_body_positions(these_inds,:) = pD.position_results(mi).mouseCOM(these_inds,:);
    final_mouse_angles(these_inds) = pD.position_results(mi).mouse_angle(these_inds);
end
% look at the user defined values
user_defined_inds = find(handles.frame_class == 10);
final_nose_positions(user_defined_inds,:) = handles.user_defined_nosePOS(user_defined_inds,:);
final_body_positions(user_defined_inds,:) = handles.user_defined_mouseCOM(user_defined_inds,:);
final_mouse_angles(user_defined_inds) = handles.user_defined_mouse_angle(user_defined_inds);

% look at the interpolated values
interpolated_inds = find(handles.frame_class == 12);
final_nose_positions(interpolated_inds,:) = handles.interpolated_nose_position(interpolated_inds,:);
final_body_positions(interpolated_inds,:) = handles.interpolated_body_position(interpolated_inds,:);
final_mouse_angles(interpolated_inds) = handles.interpolated_mouse_angle(interpolated_inds);

% save the annotation events
annotations = handles.annotations;

save(position_file,'frame_class','user_defined_mouse_angle','user_defined_nosePOS',...
    'user_defined_mouseCOM','interpolated_body_position','interpolated_nose_position',...
    'interpolated_mouse_angle','annotations',...
    'final_nose_positions','final_body_positions','final_mouse_angles','-append');


% --- Executes on button press in reset_segment_button.
function reset_segment_button_Callback(hObject, eventdata, handles)
handles.segment_start_text.String = '';
handles.segment_end_text.String = '';


% --- Executes on selection change in show_menu.
function show_menu_Callback(hObject, eventdata, handles)
contents = cellstr(get(handles.show_menu,'String'));
selection = contents{get(handles.show_menu,'Value')};

handles.suppress_line_update = 0;
guidata(hObject, handles);

if strmatch(selection,'parameter pairs','exact')
    handles.x_axes_method_menu.Enable = 'on';
    handles.x_axes_parameter_menu.Enable = 'on';
    handles.y_axes_method_menu.Enable = 'on';
    handles.y_axes_parameter_menu.Enable = 'on';
else
    handles.x_axes_method_menu.Enable = 'off';
    handles.x_axes_parameter_menu.Enable = 'off';
    handles.y_axes_method_menu.Enable = 'off';
    handles.y_axes_parameter_menu.Enable = 'off';
end

handles.hold_dotdisplay_zoom = 0;
guidata(handles.figure1,handles);

update_position_histograms_mm(handles)


% --- Executes during object creation, after setting all properties.
function show_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to show_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function show_selected_methods_radiobutton_Callback(hObject, eventdata, handles);
replay_calculated_positions_mm(hObject,handles,2);

function show_applied_method_radiobutton_Callback(hObject, eventdata, handles);
replay_calculated_positions_mm(hObject,handles,2);


% --- Executes during object creation, after setting all properties.
function show_selected_methods_radiobutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to show_selected_methods_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in annotation_menu.
function annotation_menu_Callback(hObject, eventdata, handles)
% hObject    handle to annotation_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns annotation_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from annotation_menu


% --- Executes during object creation, after setting all properties.
function annotation_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to annotation_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in apply_annotation_to_frame_button.
function apply_annotation_to_frame_button_Callback(hObject, eventdata, handles)
manage_annotation_events(handles,'frame+');



function annotation_edit_Callback(hObject, eventdata, handles)
% hObject    handle to annotation_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of annotation_edit as text
%        str2double(get(hObject,'String')) returns contents of annotation_edit as a double


% --- Executes during object creation, after setting all properties.
function annotation_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to annotation_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function segment_start_text_Callback(hObject, ~, handles)
ok = check_framenum_string(hObject.String,1,handles.Nframes);
if ~ok
    hObject.String = '';
end



function segment_end_text_Callback(hObject, ~,handles)
ok = check_framenum_string(hObject.String,1,handles.Nframes);
if ~ok
    hObject.String = '';
end


function review_positions_keyPress(src,e,hObject,eventdata,handles)

% need to get an updated handles structure
handles = guidata(hObject);


% If the value was entered into one of he edit boxes, thenr eturn
GCO = gco;
fiEldnames = fieldnames(GCO);
if ismember('Style',fiEldnames)
    if ~isempty(strfind(lower(GCO.Style), 'edit'))
        return
    end
end


% Determine action according to modifier
if isempty(e.Modifier)
    Action = 'onestep';
else
    switch lower(e.Modifier{1})
        case 'alt'
            Action = 'play';
        case 'shift'
            Action = 'onesecond';
        case 'control'
            Action = 'marked';
        otherwise
            Action = 'onestep';
    end
end

switch e.Key
    case 'rightarrow'
        switch Action
            case 'onestep'
                next_frame_button_Callback(hObject, eventdata, handles)
            case 'onesecond'
                this_frame = str2num(handles.current_frame_edit.String);
                if this_frame+round(1/handles.data.SI) <= handles.Nframes
                    handles.current_frame_edit.String = num2str(this_frame+round(1/handles.data.SI));
                    guidata(hObject, handles);
                    replay_calculated_positions_mm(hObject,handles,2);
                end
            case 'marked'
                if strcmp(handles.next_abovethresh_button.Enable,'on')
                    next_abovethresh_button_Callback(hObject, eventdata, handles);
                end
            case 'play'
                if strcmp(handles.play_pause_toggle.Enable,'on')
                    play_pause_toggle_Callback(hObject, eventdata, handles)
                end
        end
    case 'leftarrow'
        switch Action
            case 'onestep'
                previous_frame_button_Callback(hObject, eventdata, handles)
            case 'onesecond'
                this_frame = str2num(handles.current_frame_edit.String);
                if this_frame-round(1/handles.data.SI) >= 1
                    handles.current_frame_edit.String = num2str(this_frame-round(1/handles.data.SI));
                    guidata(hObject, handles);
                    replay_calculated_positions_mm(hObject,handles,2);
                end
            case 'marked'
                if strcmp(handles.previous_abovethresh_button.Enable,'on')
                    previous_abovethresh_button_Callback(hObject, eventdata, handles);
                end
            case 'play'
                if strcmp(handles.PLAYBACK_BUTTON.Enable,'on')
                    PLAYBACK_BUTTON_Callback(hObject, eventdata, handles)
                end
        end
    case '1'
        if handles.setframeas_method1_button.Visible
            set_frame_as_class(handles,1)
        end
    case '2'
        if handles.setframeas_method2_button.Visible
            set_frame_as_class(handles,2)
        end
    case '3'
        if handles.setframeas_method3_button.Visible
            set_frame_as_class(handles,3)
        end
    case '4'
        if handles.setframeas_method4_button.Visible
            set_frame_as_class(handles,4)
        end
    case '5'
        if handles.setframeas_method5_button.Visible
            set_frame_as_class(handles,5)
        end
    case '6'
        if handles.setframeas_method6_button.Visible
            set_frame_as_class(handles,6)
        end
    case {'i','I'}
        interpolate_positions_manually(handles)
%         if handles.setframeas_interpolated_button.Visible
%             set_frame_as_class(handles,12)
%         end
    case {'x','X'}
        if strcmp(handles.frame_exclude_button.Visible,'on')
            set_frame_as_class(handles,11)
        end
    case {'s','S'}
        segment_start_button_Callback(hObject, eventdata, handles)
    case {'e','E'}        
        segment_end_button_Callback(hObject, eventdata, handles)
    case {'a','A'}
        if ~isempty(handles.annotation_menu.String)
            manage_annotation_events(handles,'frame+');
        end
    case {'r','R'}
        if ~isempty(handles.annotation_menu.String)
            manage_annotation_events(handles,'frame-');
        end    
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
replay_calculated_positions_mm(handles.figure1,handles,2);





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


% --- Executes on button press in remove_annotation_to_frame_button.
function remove_annotation_to_frame_button_Callback(hObject, eventdata, handles)
manage_annotation_events(handles,'frame-');

% --- Executes on button press in hide_excluded_checkbox.
function hide_excluded_checkbox_Callback(hObject, eventdata, handles)
update_position_histograms_mm(handles)


% --- Executes on button press in PLAYBACK_BUTTON.
function PLAYBACK_BUTTON_Callback(hObject, eventdata, handles)
% If not running
if strcmp(handles.PLAYBACK_BUTTON.String,'YALP')
    handles.play_dir = -1;
    handles.do_play   = 1;
    handles.PLAYBACK_BUTTON.String = 'PAUSE';
    handles.play_pause_toggle.Enable = 'off';    
    % disable dot display menus
    handles.show_menu.Enable = 'off';
    handles.y_axes_parameter_menu.Enable = 'off';
    handles.y_axes_method_menu.Enable = 'off';
    handles.x_axes_parameter_menu.Enable = 'off';
    handles.x_axes_method_menu.Enable = 'off';            
    % Update handles structure
    guidata(hObject, handles);
    replay_calculated_positions_mm(hObject,handles,0);
elseif strcmp(handles.PLAYBACK_BUTTON.String,'PAUSE')    
    %handles.PLAYBACK_BUTTON.Value = 0;
    handles.do_play = 0;
    handles.PLAYBACK_BUTTON.String = 'YALP';
    handles.play_pause_toggle.Enable = 'on';    
     % enable dot display menus
    handles.show_menu.Enable = 'on';
    contents = cellstr(get(handles.show_menu,'String'));
    selection = contents{get(handles.show_menu,'Value')};
    if strmatch(selection,'parameter pairs','exact')
        handles.x_axes_method_menu.Enable = 'on';
        handles.x_axes_parameter_menu.Enable = 'on';
        handles.y_axes_method_menu.Enable = 'on';
        handles.y_axes_parameter_menu.Enable = 'on';
    end
    
    % Update handles structure
    guidata(hObject, handles);
end



function stop_if_above_edit_Callback(hObject, eventdata, handles)

handles.suppress_line_update = 0;

% update the transition threshold
val = str2num(get(hObject,'String'));
if ~(length(val) == 1)    
    guidata(hObject, handles);
    update_position_histograms_mm(handles)
    handles = guidata(handles.figure1);
    replay_calculated_positions_mm(handles.figure1,handles,2);   
    return
end

y_data = handles.scatter_plot_y_data;
if val > max(y_data) 
    val = max(y_data) + realmin;
    handles.stop_if_above_edit.String = num2str(val,'%.2f');
end
if val < min(y_data)
    val = min(y_data) - realmin;
    handles.stop_if_above_edit.String = num2str(val,'%.2f');
end

handles.thresh_line_h.YData = [val val];
frame_subset_to_show = false(size(handles.frame_class));
in = y_data > val;
frame_subset_to_show(in) = 1;

if sum(in) > 0
    handles.show_selected_checkbox.Enable = 'on';
    handles.stop_playback_checkbox.Enable = 'on';
    handles.previous_abovethresh_button.Enable = 'on';
    handles.next_abovethresh_button.Enable = 'on';    
    handles.show_selected_checkbox.Value = 1;
    if sum(in) > 1
        percent_string = num2str(100* sum(in)/handles.data.nframes,'%.1f');
        handles.n_selected_text.String = [num2str(sum(in)) ' frames marked (' percent_string '%)'];        
    else
        handles.n_selected_text.String = [num2str(sum(in)) ' frame marked'];
    end       
else
    handles.show_selected_checkbox.Enable = 'off';
    handles.stop_playback_checkbox.Enable = 'off';
    handles.previous_abovethresh_button.Enable = 'off';
    handles.next_abovethresh_button.Enable = 'off';    
    handles.show_selected_checkbox.Value = 0;
    handles.stop_playback_checkbox.Value = 0;
    handles.n_selected_text.String = ['0 frames marked'];
end
handles.frame_subset_to_show = frame_subset_to_show;   

% This will prevent the update position histograms to change the treshold
handles.suppress_line_update = 1;

guidata(handles.figure1,handles);
update_position_histograms_mm(handles)
handles = guidata(handles.figure1);
replay_calculated_positions_mm(handles.figure1,handles,2);





% --- Executes during object creation, after setting all properties.
function stop_if_above_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stop_if_above_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in stop_if_above_checkbox.
function stop_if_above_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to stop_if_above_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stop_if_above_checkbox


% --- Executes on key press with focus on play_pause_toggle and none of its controls.
function play_pause_toggle_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to play_pause_toggle (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in previous_abovethresh_button.
function previous_abovethresh_button_Callback(hObject, eventdata, handles)
% get current frame
frame = str2num(handles.current_frame_edit.String);

% get values of frames above threshold
% stop_thresh = str2num(get(handles.stop_if_above_edit,'String'));
% stop_frames = find(handles.scatter_plot_y_data > stop_thresh);
stop_frames = find(handles.frame_subset_to_show);

% get the next ...
stop_frames = stop_frames(stop_frames < frame);

if ~isempty(stop_frames)
    next_frame = stop_frames(end);
    % set the next value in the edit box
    handles.current_frame_edit.String = num2str(next_frame);
    current_frame_edit_Callback(hObject, eventdata, handles)
end




% --- Executes on button press in next_abovethresh_button.
function next_abovethresh_button_Callback(hObject, eventdata, handles)

% get current frame
frame = str2num(handles.current_frame_edit.String);

% get values of frames above threshold
%stop_thresh = str2num(get(handles.stop_if_above_edit,'String'));
%stop_frames = find(handles.scatter_plot_y_data > stop_thresh);

stop_frames = find(handles.frame_subset_to_show);

% get the next ...
stop_frames = stop_frames(stop_frames > frame);

if ~isempty(stop_frames)
    next_frame = stop_frames(1);
    % set the next value in the edit box
    handles.current_frame_edit.String = num2str(next_frame);
    current_frame_edit_Callback(hObject, eventdata, handles)
end


% --- Executes on button press in stop_playback_checkbox.
function stop_playback_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to stop_playback_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stop_playback_checkbox


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


% --- Executes on button press in auto_correct_button.
function auto_correct_button_Callback(hObject, eventdata, handles)
correct_fast_transitions(handles);




function bad_thresh_edit_Callback(hObject, eventdata, handles)
y_data  = handles.scatter_plot_y_data;
content = handles.bad_thresh_edit.String;
bad_thresh = str2num(content);
if ~(length(bad_thresh) == 1)
    errordlg(['bad threshold must be a number between 60 and 180'],'correct transitions','modal');
    % bad_thresh = min(90,prctile(y_data,95));
    bad_thresh = prctile(y_data,95);
    bad_thresh = max(60,bad_thresh);
elseif (bad_thresh <= 60 || bad_thresh >= 180)
    errordlg(['bad threshold must be a number between 60 and 180'],'correct transitions','modal');
    % bad_thresh = min(90,prctile(y_data,95));
    bad_thresh = prctile(y_data,95);
    bad_thresh = max(60,bad_thresh);
end
% if ~(bad_thresh < max(handles.scatter_plot_y_data))
%     errordlg(['bad threshold must be a smaller than maximum data value'],'correct transitions','modal');
%     bad_thresh = min(90,prctile(y_data,95));
%     bad_thresh = max(60,bad_thresh);
% end

handles.bad_thresh_edit.String = num2str(bad_thresh,'%.1f');
lh = findobj('tag','bad_thresh_line');
if isempty(lh)
    handles.bad_thresh_line_h    = line(get(handles.parameter_axes,'XLim'),[bad_thresh bad_thresh],'color','r','linewidth',1,'tag','bad_thresh_line');
else
    lh.YData = [bad_thresh bad_thresh];
end
    


% --- Executes during object creation, after setting all properties.
function bad_thresh_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bad_thresh_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function good_thresh_edit_Callback(hObject, eventdata, handles)
y_data  = handles.scatter_plot_y_data;
content = handles.good_thresh_edit.String;
good_thresh = str2num(content);
if ~(length(good_thresh) == 1)
    errordlg(['value must be a positive number, smaller than 30 and the 80th data percentile'],'correct transitions','modal');
    good_thresh = min(30,prctile(y_data,80));
elseif (good_thresh <= 0 || good_thresh >= 30)
    errordlg(['value must be a positive number, smaller than 30 and the 80th data percentile'],'correct transitions','modal');
    good_thresh = min(30,prctile(y_data,80));
end

handles.good_thresh_edit.String = num2str(good_thresh,'%.1f');
lh = findobj('tag','good_thresh_line');
if isempty(lh)
    handles.good_thresh_line_h    = line(get(handles.parameter_axes,'XLim'),[good_thresh good_thresh],'color','r','linewidth',1,'tag','good_thresh_line');
else
    lh.YData = [good_thresh good_thresh];
end



% --- Executes during object creation, after setting all properties.
function good_thresh_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to good_thresh_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in max_transient_length_menu.
function max_transient_length_menu_Callback(hObject, eventdata, handles)
% hObject    handle to max_transient_length_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns max_transient_length_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from max_transient_length_menu


% --- Executes during object creation, after setting all properties.
function max_transient_length_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_transient_length_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
