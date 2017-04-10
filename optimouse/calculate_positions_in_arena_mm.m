function varargout = calculate_positions_in_arena_mm(varargin)
% YBS 9/16
% CALCULATE_POSITIONS_IN_ARENA_MM MATLAB code for calculate_positions_in_arena_mm.fig
%      CALCULATE_POSITIONS_IN_ARENA_MM, by itself, creates a new CALCULATE_POSITIONS_IN_ARENA_MM or raises the existing
%      singleton*.
%
%      H = CALCULATE_POSITIONS_IN_ARENA_MM returns the handle to a new CALCULATE_POSITIONS_IN_ARENA_MM or the handle to
%      the existing singleton*.
%
%      CALCULATE_POSITIONS_IN_ARENA_MM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALCULATE_POSITIONS_IN_ARENA_MM.M with the given input arguments.
%
%      CALCULATE_POSITIONS_IN_ARENA_MM('Property','Value',...) creates a new CALCULATE_POSITIONS_IN_ARENA_MM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before calculate_positions_in_arena_mm_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to calculate_positions_in_arena_mm_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help calculate_positions_in_arena_mm

% Last Modified by GUIDE v2.5 09-Nov-2016 14:00:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @calculate_positions_in_arena_mm_OpeningFcn, ...
    'gui_OutputFcn',  @calculate_positions_in_arena_mm_OutputFcn, ...
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


% --- Executes just before calculate_positions_in_arena_mm is made visible.
function calculate_positions_in_arena_mm_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to calculate_positions_in_arena_mm (see VARARGIN)

% save the directory as default for next time
default_path_filename = [get_user_dir 'default_start_dir.mat'];
if exist(default_path_filename) == 2
    D = load(default_path_filename,'folder_name');
    handles.video_dir_text.String = D.folder_name;
end

handles = guidata(hObject);

% update detection methods list - (iuf there are any user defined methods)
method_strings = handles.detection_method_menu.String;
n_methods = length(method_strings);

% if we have a valid user definition function on the search path
if exist('user_defined_detection_function_description') == 2
    user_detection_functions = user_defined_detection_function_description;
    if ~isempty(user_detection_functions)
        user_method_names = {user_detection_functions.name};
        for i = 1:length(user_method_names)
            method_strings{n_methods+i} = [num2str(n_methods+i) ' (' user_method_names{i} ')'];
            user_detection_functions(i).menuval = n_methods+i;
        end
    end
else
    msgstr{1} = 'User defined detection function descriptions not found';
    msgstr{2} = 'Functions can be defined in:';
    msgstr{3} = '''user_defined_detection_function_description.m''';
    
    msgbox(msgstr,'Calculate Positions')
    user_detection_functions = [];
end

handles.detection_method_menu.String = method_strings;
handles.user_detection_functions = user_detection_functions;
handles.current_arena_folder_listbox_selection = '';

% update the handles before sending to arena - this is actually required to
% prevent errors in some cases
guidata(hObject, handles);

arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles)
% Get handles after running the arena listbox
handles = guidata(hObject);

% Choose default command line output for calculate_positions_in_arena_mm
handles.output = hObject;

% initiate handle methods structure
handles.detection_methods = [];

% define keypress functions
set(handles.figure1,'WindowKeyPressFcn', {@calculate_positions_keyPress,hObject,eventdata,handles});


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes calculate_positions_in_arena_mm wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = calculate_positions_in_arena_mm_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in arena_folder_listbox.
function arena_folder_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to arena_folder_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if this is not the first time, check if we changed the value
contents =         cellstr(get(handles.arena_folder_listbox,'String'));
if ~isempty(handles.current_arena_folder_listbox_selection) && ~isempty(contents)
    selected =         contents{get(handles.arena_folder_listbox,'Value')} ;    
    % if we selected something else, and that something is still on the
    % list
    if ~strcmp(handles.current_arena_folder_listbox_selection,selected) & ismember(handles.current_arena_folder_listbox_selection,contents)        
        ButtonName = questdlg('Sure you want to move to a new file? Any unsaved settings will be erased. Continue?', ...
            'Calculate Positions', ...
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


D = dir([handles.video_dir_text.String filesep '*_arena*']);
% keep only direcotories
D = D([D.isdir]);
arena_folders = {D.name};

% Take only relevant files
pattern = handles.file_name_filter_edit.String;
if ~isempty(pattern)
    pat_match = strfind(arena_folders, pattern);
    take_files = [];
    for i = 1:length(pat_match)
        if ~isempty(pat_match{i})
            take_files = [take_files i];
        end
    end
else
    take_files = 1:length(arena_folders);
end

arena_folders = arena_folders(take_files);
handles.arena_folder_listbox.String = arena_folders;

% Getting the list twice is a bit of a waste, but the waste is negligible
contents = cellstr(get(handles.arena_folder_listbox,'String'));
if isempty(contents)
    cla(handles.original_video_axes)
    handles.define_arena_button.Enable = 'off';
    return
else
    contents = cellstr(get(handles.arena_folder_listbox,'String'));
    arena_folder = [handles.video_dir_text.String filesep 'arenas'];
    base_name = contents{get(handles.arena_folder_listbox,'Value')};
    
    info_file   = dir([arena_folder filesep base_name '*_info.mat']);
    if isempty(info_file)
        errorstr{1} = 'Cannot detect positions for chosen Arena';
        errorstr{2} = ['Arena info file not found for ' base_name];
        errordlg(errorstr,'Detect Positions')
        return
    end
    iD = load([arena_folder filesep info_file(1).name]);
                
    handles.full_info_file_name = [arena_folder filesep info_file(1).name];
    
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
    handles.current_frame_edit.String = '1';
    handles.go_to_time_edit.String = num2str(data.SI,'%.2f');

    % set the slider step for a second a minute
    onesecond = (1/data.duration);
    oneminute = (onesecond*60);
    try
        handles.frame_select_slider.SliderStep = [onesecond oneminute];
    catch
    end
    
    
    guidata(handles.figure1, handles);
    
    
    handles.use_median_as_background_radiobutton.Value = 1;
    handles.user_defined_background_radiobutton.Value = 0;
    handles.user_defined_background_radiobutton.Enable = 'off';
    
    % Reset the current method and the user defined method settings
    % This is the max distance nose from tail
    handles.detection_method_menu.Value = 6;
    detection_method_menu_Callback(hObject, eventdata, handles)
                          
    % initiate handle methods structure
    handles.method_listbox.String = '';
    handles.method_listbox.Value = 1;
    handles.detection_methods = [];
           
    if isfield(iD,'user_string')
        handles.user_comment_edit.String = iD.user_string;
    else
        handles.user_comment_edit.String = '';
    end
    
    
    update_arena_images(handles);
    
end

% only if we got thtough to these stages, we have to update the value
handles.current_arena_folder_listbox_selection = contents{get(handles.arena_folder_listbox,'Value')};


guidata(hObject, handles);



return

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

% % % 
% % % % --- Executes on selection change in arena_listbox.
% % % function arena_listbox_Callback(hObject, eventdata, handles)
% % % % hObject    handle to arena_listbox (see GCBO)
% % % % eventdata  reserved - to be defined in a future version of MATLAB
% % % % handles    structure with handles and user data (see GUIDATA)
% % % 
% % % % Hints: contents = cellstr(get(hObject,'String')) returns arena_listbox contents as cell array
% % % %        contents{get(hObject,'Value')} returns selected item from arena_listbox
% % % 
% % % % First update thje list
% % % D = dir([handles.video_dir_text.String filesep '*_arenas_*.mat']);
% % % arena_files = {D.name};
% % % handles.arena_listbox.String = arena_files;
% % % 
% % % 
% % % contents = cellstr(get(handles.arena_folder_listbox,'String'));
% % % vidfilename = [handles.video_dir_text.String filesep contents{get(handles.arena_folder_listbox,'Value')}];
% % % 
% % % contents = cellstr(get(handles.arena_listbox,'String'));
% % % if ~isempty(contents)
% % %     arenafilename = [handles.video_dir_text.String filesep contents{get(handles.arena_listbox,'Value')}];
% % % else
% % %     return
% % % end
% % % 
% % % vD = handles.data;
% % % aD = load(arenafilename);
% % % 
% % % % check if the current video file and the file on which the ROI was defined
% % % % have the same dimensions:
% % % same_height = vD.VideoHeight == aD.ImageSizeInPixels(1);
% % % same_width  = vD.VideoWidth  == aD.ImageSizeInPixels(2);
% % % if ~(same_height&&same_width)
% % %     msgbox('cannot apply arena: current video file does not have the same dimensions as file used for arena definition');
% % %     return
% % % end
% % % 
% % % % Check if the same file was used to generate them and if not, warn the user
% % % if ~strcmp(vD.vidfilename,aD.vidfilename)
% % %     queststr = ['Arena was not defined on current arena file. Apply anyway?'];
% % %     ButtonName = questdlg(queststr ,'Apply Arena','Apply','Cancel','Apply');
% % %     switch ButtonName,
% % %         case 'Cancel',
% % %             update_display = 0;
% % %         case 'Apply'
% % %             update_display = 1;
% % %     end
% % % else
% % %     update_display = 1;
% % % end
% % % 
% % % if update_display
% % %     % Delete all rectangles and accompanying text if they exist on the figure
% % %     delete(findobj(handles.figure1,'Type','rectangle'));
% % %     delete(findobj(handles.figure1,'Tag','ImrectText'));
% % %     axes(handles.original_video_axes);
% % %     for i = 1:length(aD.ROIs)
% % %         thispos = aD.ROIs(i).roi_position_in_pixels;
% % %         rh = rectangle('Position', thispos,'EdgeColor',aD.ROIs(i).roi_color,'LineWidth',1);
% % %         th = text(thispos(1)+thispos(3)/2,thispos(2)+thispos(4)/2,aD.ROIs(i).roi_name);
% % %         set(th,'Color',aD.ROIs(i).roi_color,'Tag','ImrectText','HorizontalAlignment','Center', 'VerticalAlignment','middle');
% % %     end
% % % end
% % % 
% % % guidata(hObject, handles);
% % % 
% % % return

% % % 
% % % % --- Executes during object creation, after setting all properties.
% % % function arena_listbox_CreateFcn(hObject, eventdata, handles)
% % % % hObject    handle to arena_listbox (see GCBO)
% % % % eventdata  reserved - to be defined in a future version of MATLAB
% % % % handles    empty - handles not created until after all CreateFcns called
% % % 
% % % % Hint: listbox controls usually have a white background on Windows.
% % % %       See ISPC and COMPUTER.
% % % if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
% % %     set(hObject,'BackgroundColor','white');
% % % end
% % % 

% --- Executes on button press in select_video_dir_button.
function select_video_dir_button_Callback(hObject, eventdata, handles)
% hObject    handle to select_video_dir_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiwait(msgbox(['Please select MAIN video directory'],'Select Dir','modal'));

folder_name = uigetdir(handles.video_dir_text.String,'select video file directory');
if folder_name
    handles.video_dir_text.String = folder_name;
    %D = dir([handles.video_dir_text.String filesep '*.mp4']);
    %video_files = {D.name};
    %handles.arena_folder_listbox.String = video_files;    
    
    handles.arena_folder_listbox.Value = 1;
    arena_folder_listbox_Callback(handles.arena_folder_listbox,[], handles);
    
    % save the directory as default for next time
    default_path_filename = [get_user_dir 'default_start_dir.mat'];
    save(default_path_filename,'folder_name')    
end

% --- Executes on button press in define_arena_button.
function define_arena_button_Callback(hObject, eventdata, handles)
% If the button is enabled, then the video listbox should not be empty
contents = cellstr(get(handles.arena_folder_listbox,'String'));
vidfilename = [handles.video_dir_text.String filesep contents{get(handles.arena_folder_listbox,'Value')}];

defineArena(vidfilename,handles);


function other_arenas_listbox_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function other_arenas_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to other_arenas_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calculate_mouse_positions_button.
function calculate_mouse_positions_button_Callback(hObject, eventdata, handles)
% hObject    handle to calculate_mouse_positions_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in random_frame_button.
function random_frame_button_Callback(hObject, eventdata, handles)
update_arena_images(handles);


% --- Executes on selection change in detection_method_menu.
function detection_method_menu_Callback(hObject, eventdata, handles)

val = handles.detection_method_menu.Value;

% user_detection_functions_names = {handles.user_detection_functions.name};
if ~isempty(handles.user_detection_functions)
    user_detection_functions_vals = cell2mat({handles.user_detection_functions.menuval});
else
    user_detection_functions_vals = [];
end

% reset all methods
for i = 1:5 % maximum number of
    eval(['handles.user_param' num2str(i) '_text.Visible = ''off'';']);
    eval(['handles.user_param' num2str(i) '_edit.Visible = ''off'';']);
end


if ismember(val,user_detection_functions_vals)
    fid = find(val == user_detection_functions_vals);
    % handles.user_defined_params_text.Visible = 'on';
    % handles.user_defined_method_panel.Visible = 'on';
    
    
    % and activate those that are relevant for this method
    param_names = handles.user_detection_functions(fid).param_names;
    for i = 1:length(param_names)
        eval(['handles.user_param' num2str(i) '_text.Visible = ''on'';']);
        eval(['handles.user_param' num2str(i) '_edit.Visible = ''on'';']);
        eval(['handles.user_param' num2str(i) '_text.String = param_names{i};']);
        
        def_par_str = num2str(handles.user_detection_functions(fid).param_range{i}(1));
        eval(['handles.user_param' num2str(i) '_edit.String = ' def_par_str ';']);
    end
end

update_arena_images(handles);


% --- Executes during object creation, after setting all properties.
function detection_method_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to detection_method_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calculate_position_button.
function calculate_position_button_Callback(hObject, eventdata, handles, batch_mode)
% This one works witht he handles structure, but I want to run it without
% passing the handles directly

if nargin == 3
    batch_mode = 0;
end

contents = cellstr(get(handles.arena_folder_listbox,'String'));
tmp_file_folder = [handles.video_dir_text.String filesep contents{get(handles.arena_folder_listbox,'Value')}];

arena_folder = [handles.video_dir_text.String filesep 'arenas'];
base_name = contents{get(handles.arena_folder_listbox,'Value')};
info_file   = dir([arena_folder filesep base_name '*_info.mat']);

% for loading the tmp files
full_tmp_file_base_name =  [tmp_file_folder filesep  base_name ];

if isempty(info_file)
    return
end
arena_file_name = [arena_folder filesep info_file(1).name];

position_dir = [handles.video_dir_text.String filesep 'positions' ];

if ~exist(position_dir,'dir')
    mkdir(position_dir)
end

% position file
position_file = [position_dir filesep base_name '_positions.mat'];

% Check if the file exists, and if so, warn the user
if exist(position_file,'file')
    queststr = ['Positions were already calculated for this data. Overwrite?'];
    ButtonName = questdlg(queststr ,'Calculate positions','Continue','Cancel','Cancel');
    switch ButtonName
        case 'Cancel'
            return
    end
end

% Define the detection settings folder (create it if it does not exist)
detection_settings_folder = [handles.video_dir_text.String filesep 'detection_settings'];
if ~exist(detection_settings_folder,'dir')
    mkdir(detection_settings_folder);
end


detection_methods = handles.detection_methods;
DATEstr = regexprep(datestr(now),':','_');
detection_methods_file_name = [detection_settings_folder filesep 'detection_settings_' base_name DATEstr '.mat'];
save(detection_methods_file_name,'detection_methods','arena_file_name','position_file','full_tmp_file_base_name');

cmdstr = ['calculate_positions_mm(''' detection_methods_file_name ''')'];

if ~batch_mode
    % profile on    
    msgbox(['methods saved in ' detection_methods_file_name ],'Calculate Positions')
    tic % for testing for article
    eval(cmdstr);
    toc % for testing for article
    % profile report
else
    batch_file = [get_user_dir  'calculate_positions_batch.m'];
    [~,AF,~] = fileparts(arena_file_name);
    [~,PF,~] = fileparts(position_file);
    fileID = fopen(batch_file,'a');
    
    cleandmdstr = cmdstr;
    cleandmdstr((findstr('''',cleandmdstr))) = [];
    
    comment_str = ['% batch command from ' datestr(now) ];
    fprintf(fileID,'%s\n',comment_str);
    fprintf(fileID,'%s\n',['% arena file: ' AF]);
    fprintf(fileID,'%s\n',['% position file: ' PF]);
    fprintf(fileID,'%s\n',['disp(''now running '  cleandmdstr    ''')' ]);
    fprintf(fileID,'%s\n\n',cmdstr);
    fclose(fileID);
end


function current_frame_edit_Callback(hObject, eventdata, handles);

editstr = get(handles.current_frame_edit,'String');

ok = check_framenum_string(editstr,1,handles.Nframes);
if ~ok
    errordlg(['frame number must be an integer between 1 and the ''end frame'' frame'],'frame range','modal');
    handles.current_frame_edit.String = '1';    
    handles.go_to_time_edit.String = num2str(handles.data.SI,'%.2f');  
    handles.frame_select_slider.Value = 1;
    return
end

handles.go_to_time_edit.String = num2str(str2num(editstr)*handles.data.SI,'%.2f');    
handles.frame_select_slider.Value = str2num(hObject.String);

update_arena_images(handles);


% --- Executes during object creation, after setting all properties.
function current_frame_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function trim_level_menu_Callback(hObject, eventdata, handles)
update_arena_images(handles);


function trim_level_menu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function detection_threshold_slider_Callback(hObject, eventdata, handles)
val = get(handles.detection_threshold_slider,'Value');
handles.detection_threshold_text.String = num2str(val);
update_arena_images(handles);


function detection_threshold_slider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function detection_threshold_text_Callback(hObject, eventdata, handles)

editstr = get(handles.detection_threshold_text,'String');
val = str2num(editstr);

minV = handles.detection_threshold_slider.Min;
maxV = handles.detection_threshold_slider.Max;

if ~(length(val) == 1)
    errordlg(['Threshold must be a number between ' num2str(minV) ' and ' num2str(maxV)],'image threshold','modal');
    handles.detection_threshold_text.String = '0.5';
    return
end

if val < handles.detection_threshold_slider.Min || val > handles.detection_threshold_slider.Max
    errordlg(['Threshold must be a number between ' num2str(minV) ' and ' num2str(maxV)],'image threshold','modal');
    handles.detection_threshold_text.String = '0.5';
    return
end

handles.detection_threshold_slider.Value = str2num(editstr);
update_arena_images(handles);



function detection_threshold_text_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function down_sample_factor_edit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function down_sample_factor_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function frame_select_slider_Callback(hObject, eventdata, handles)
frameval = get(handles.frame_select_slider,'Value');
frameval = round(frameval);
handles.current_frame_edit.String = num2str(frameval);
handles.go_to_time_edit.String = num2str(frameval*handles.data.SI,'%.2f');    
guidata(handles.frame_select_slider, handles);
update_arena_images(handles);




% --- Executes during object creation, after setting all properties.
function frame_select_slider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in previous_frame_button.
function previous_frame_button_Callback(hObject, eventdata, handles)
this_frame = str2num(handles.current_frame_edit.String);
if this_frame > 1
    prev_frame = this_frame - 1;
    handles.current_frame_edit.String = num2str(prev_frame);
    handles.go_to_time_edit.String = num2str(prev_frame*handles.data.SI,'%.2f');
    handles.frame_select_slider.Value = prev_frame;
    guidata(hObject, handles);
    update_arena_images(handles);
end


% --- Executes on button press in next_frame_button.
function next_frame_button_Callback(hObject, eventdata, handles)
this_frame = str2num(handles.current_frame_edit.String);
if this_frame < handles.Nframes
    next_frame = this_frame + 1;
    handles.current_frame_edit.String = num2str(next_frame);
    handles.go_to_time_edit.String = num2str(next_frame*handles.data.SI,'%.2f');    
    handles.frame_select_slider.Value = next_frame;
    guidata(hObject, handles);
    update_arena_images(handles);
end


function mouse_brighter_radiobutton_Callback(hObject, eventdata, handles)
update_arena_images(handles);


function mouse_darker_radiobutton_Callback(hObject, eventdata, handles)
update_arena_images(handles);


function auto_determine_brighter_radiobutton_Callback(hObject, eventdata, handles)
update_arena_images(handles);

function edit4_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in add_to_batch_button.
function add_to_batch_button_Callback(hObject, eventdata, handles)
calculate_position_button_Callback(hObject, eventdata, handles, 1)

function median_corrected_image_checkbox_Callback(hObject, eventdata, handles)
update_arena_images(handles);

function original_image_checkbox_Callback(hObject, eventdata, handles)
update_arena_images(handles);

function binary_image_checkbox_Callback(hObject, eventdata, handles)
update_arena_images(handles);


% --- Executes on button press in show_background_button.
function show_background_button_Callback(hObject, eventdata, handles)

contents = cellstr(get(handles.arena_folder_listbox,'String'));
arena_folder = [handles.video_dir_text.String filesep 'arenas'];
base_name = contents{get(handles.arena_folder_listbox,'Value')};
info_file   = dir([arena_folder filesep base_name '*_info.mat']);
if isempty(info_file)
    return
end
arena_file_name = [arena_folder filesep info_file(1).name];
aD = load(arena_file_name);


if handles.use_median_as_background_radiobutton.Value
    BackGroundImage = aD.MedianImage;
    backtype = 'median';
elseif handles.user_defined_background_radiobutton.Value
    BackGroundImage = handles.CurrentUserBackGround;
    backtype = 'user defined';
end


fh = figure; 
imagesc(BackGroundImage);
colormap gray
% colorbar
axis equal
axis tight
set(gca,'XTick',[],'YTick',[]);

set(fh,'ToolBar','none')
set(fh,'MenuBar','none')
% set(fh,'name',[ backtype ' background for ' info_file(1).name])
set(fh,'name',['Current background (' backtype ')'])
set(fh,'numbertitle','off')
% set(fh,'Interpreter','none')


function use_median_as_background_radiobutton_Callback(hObject, eventdata, handles)
if hObject.Value
    handles.median_corrected_image_checkbox.Enable = 'on';
    handles.show_background_button.Enable = 'on';
end

update_arena_images(handles);


% --- Executes on button press in user_defined_background_radiobutton.
function user_defined_background_radiobutton_Callback(hObject, eventdata, handles)
if hObject.Value
    handles.median_corrected_image_checkbox.Enable = 'on';
    handles.show_background_button.Enable = 'on';
end
update_arena_images(handles);


% --- Executes on button press in nobackground_ratiobutton.
function nobackground_ratiobutton_Callback(hObject, eventdata, handles)
% disable irrelevant checkboxes if on median is used
if hObject.Value
    handles.original_image_checkbox.Value = 1;
    handles.median_corrected_image_checkbox.Value = 0;
    handles.median_corrected_image_checkbox.Enable = 'off';
    handles.show_background_button.Enable = 'off';
else
    handles.median_corrected_image_checkbox.Enable = 'on';
    handles.show_background_button.Enable = 'on';
end
update_arena_images(handles);



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


% --- Executes on button press in zoom_in_on_mouse.
function zoom_in_on_mouse_Callback(hObject, eventdata, handles)
update_arena_images(handles);



% --- Executes on button press in show_perimeter_checkbox.
function show_perimeter_checkbox_Callback(hObject, eventdata, handles)
update_arena_images(handles);

% --- Executes on selection change in method_listbox.
function method_listbox_Callback(hObject, eventdata, handles)

detection_methods = handles.detection_methods;
if isempty(detection_methods)
    return
end
detection_method_names = {detection_methods.name};

% Get name of selected method
mstrings = handles.method_listbox.String;
mstring  = mstrings{handles.method_listbox.Value};

% find relevant entry - should always be one
rel_ind = strmatch(mstring,detection_method_names,'exact');

% should be same as nm

detection_methods = handles.detection_methods;

% reset all user defined listboxes
for i = 1:5 % maximum number of
    eval(['handles.user_param' num2str(i) '_text.Visible = ''off'';']);
    eval(['handles.user_param' num2str(i) '_edit.Visible = ''off'';']);
end
%handles.user_defined_params_text.Visible = 'off';
%handles.user_defined_method_panel.Visible = 'off';


if isfield(detection_methods,'user_defined_params')
    
    if isempty(handles.user_detection_functions)
        errormsG{1} = ['Selected settings contain a user defined detectionfunction'];
        errormsG{2} = ['but no user defined funcitons definitions have been found'];
        errormsG{3} = ['This should be done in the file:'];
        errormsG{4} = '''user_defined_detection_function_description.m''';
        errordlg(errormsG)
        return
    end
    
    if ~isempty(detection_methods(rel_ind).user_defined_params)
        
        % handles.user_defined_params_text.Visible = 'on';
        % handles.user_defined_method_panel.Visible = 'on';
        
        % entry into list box
        val = detection_methods(rel_ind).algorithm;
        % list box values associated with each entry
        user_detection_functions_vals = cell2mat({handles.user_detection_functions.menuval});
        % find position in list
        fid = find(val == user_detection_functions_vals);
        % and activate those that are relevant for this method
        param_names = handles.user_detection_functions(fid).param_names;
        % These are their saved value
        user_params = detection_methods(rel_ind).user_defined_params;
        
        for i = 1:length(user_params)
            eval(['handles.user_param' num2str(i) '_text.Visible = ''on'';']);
            eval(['handles.user_param' num2str(i) '_edit.Visible = ''on'';']);
            eval(['handles.user_param' num2str(i) '_text.String = param_names{i};']);
            par_str = num2str(user_params(i));
            eval(['handles.user_param' num2str(i) '_edit.String = ' par_str ';']);
        end
    end
end

handles.detection_method_menu.Value = detection_methods(rel_ind).algorithm;
handles.trim_level_menu.Value = detection_methods(rel_ind).trimlevel;
handles.detection_threshold_text.String = detection_methods(rel_ind).threshold;
handles.detection_threshold_slider.Value = str2num(detection_methods(rel_ind).threshold);
handles.use_median_as_background_radiobutton.Value = detection_methods(rel_ind).median_background;
handles.user_defined_background_radiobutton.Value = detection_methods(rel_ind).user_background;
handles.nobackground_ratiobutton.Value = detection_methods(rel_ind).no_background;
handles.mouse_brighter_radiobutton.Value = detection_methods(rel_ind).mouse_brighter;
handles.mouse_darker_radiobutton.Value = detection_methods(rel_ind).mouse_darker;
handles.auto_determine_brighter_radiobutton.Value = detection_methods(rel_ind).auto_determine_color;

if detection_methods(rel_ind).user_background
    handles.CurrentUserBackGround = detection_methods(rel_ind).BackGroundImage;
end

guidata(hObject,handles);

update_arena_images(handles);

return


% --- Executes during object creation, after setting all properties.
function method_listbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in add_method_button.
function add_method_button_Callback(hObject, eventdata, handles)

detection_methods = handles.detection_methods;

val = handles.detection_method_menu.Value;

if ~isempty(handles.user_detection_functions)
    user_detection_functions_vals = cell2mat({handles.user_detection_functions.menuval});
else
    user_detection_functions_vals = [];
end


if ismember(val,user_detection_functions_vals)
    current_method_user_defined = 1;
    fid = find(val == user_detection_functions_vals);
    % and activate those that are relevant for this method
    param_names = handles.user_detection_functions(fid).param_names;
    user_method_name = handles.user_detection_functions(fid).name;
    user_method_runstring = handles.user_detection_functions(fid).runstring;
    
    for i = 1:length(param_names)
        eval(['current_param_vals(' num2str(i) ') = str2num(handles.user_param' num2str(i) '_edit.String);']);
    end
else
    current_method_user_defined = 0;
end

if ~isempty(detection_methods)
    existing_method_names = {detection_methods.name};
    
    if length(existing_method_names) >= 6
        errordlg(['The maximal number of method settings is 6. You can delete a method and replace with another one.'])
        return
    end
    
    
    % Check if there is already an identical method ...
    % and if so, return...
    % each method is checked, once even one setting is different
    for i = 1:length(existing_method_names)
        
        if isfield(detection_methods,'user_method_name')
            if ~isempty(detection_methods(i).user_method_name)
                existing_method_user_defined = 1;
            else
                existing_method_user_defined = 0;
            end
        else
            existing_method_user_defined = 0;
        end
        
        method_exists(i) = 1;
        if detection_methods(i).algorithm ~= handles.detection_method_menu.Value
            method_exists(i) = 0;
        end
        
        if detection_methods(i).trimlevel ~= handles.trim_level_menu.Value
            method_exists(i) = 0;
        end
        if ~strcmp(detection_methods(i).threshold,handles.detection_threshold_text.String)
            method_exists(i) = 0;
        end
        if detection_methods(i).median_background ~= handles.use_median_as_background_radiobutton.Value
            method_exists(i) = 0;
        end
        % This one says,
        if detection_methods(i).user_background ~= handles.user_defined_background_radiobutton.Value
            method_exists(i) = 0;
            % if both methods call for a user defined background
        elseif detection_methods(i).user_background == 1
            % but the background image is different
            if sum(sum(detection_methods(i).BackGroundImage - handles.CurrentUserBackGround))
                method_exists(i) = 0; % then it is also OK
            end
        end
        if detection_methods(i).no_background ~= handles.nobackground_ratiobutton.Value
            method_exists(i) = 0;
        end
        if detection_methods(i).mouse_brighter ~= handles.mouse_brighter_radiobutton.Value
            method_exists(i) = 0;
        end
        if detection_methods(i).mouse_darker ~= handles.mouse_darker_radiobutton.Value
            method_exists(i) = 0;
        end
        if detection_methods(i).auto_determine_color ~= handles.auto_determine_brighter_radiobutton.Value
            method_exists(i) = 0;
        end
        % if it is a user defined method, and the current method is the same, we check
        % the value of all the other parameters
        % continue this error checkling
        if current_method_user_defined && existing_method_user_defined
            if detection_methods(i).algorithm == handles.detection_method_menu.Value
                any_change = sum(current_param_vals ~= detection_methods(i).user_defined_params);
                if any_change
                    method_exists(i) = 0;
                end
            end
        end        
    end
    
    % if even one method already exists
    existing_method_ind = find(method_exists);
    if ~isempty(existing_method_ind)
        errordlg(['Not adding settings since they are the same as ' detection_methods(existing_method_ind).name ])
        return
    end
    
else
    existing_method_names = [];
end

% having checke dthe values themseleves, we now check which method names exist already ...
answer = inputdlg('Enter method name','detection method',[1 40],{''});

if isempty(answer)
    errordlg(['A name must be given for the method'],'Add Method','modal');
    return
end
if isempty(answer{1})
    errordlg(['A name must be given for the method'],'Add Method','modal');
    return
end

% ask the user to input again if this name is occupied
prev_name_ind = strmatch(answer,existing_method_names,'exact');

if ~isempty(prev_name_ind)
    queststr = ['Method name already exists. Overwrite?'];
    ButtonName = questdlg(queststr ,'Add detection method','Cancel','Overwrite','Cancel');
    switch ButtonName,
        case 'Cancel',
            return;
        case 'Overwrite'
            rel_ind = prev_name_ind;
    end
else
    rel_ind = length(detection_methods)+1;
end

hmstring = handles.method_listbox.String;

% should be same as nm
hmstring{rel_ind} = answer{1};
handles.method_listbox.String = hmstring;
handles.method_listbox.Value = rel_ind;

detection_methods(rel_ind).name = answer{1};
detection_methods(rel_ind).algorithm = handles.detection_method_menu.Value;
detection_methods(rel_ind).trimlevel = handles.trim_level_menu.Value;
detection_methods(rel_ind).threshold = handles.detection_threshold_text.String;
detection_methods(rel_ind).median_background = handles.use_median_as_background_radiobutton.Value;
detection_methods(rel_ind).user_background = handles.user_defined_background_radiobutton.Value;
detection_methods(rel_ind).no_background = handles.nobackground_ratiobutton.Value;
detection_methods(rel_ind).mouse_brighter = handles.mouse_brighter_radiobutton.Value;
detection_methods(rel_ind).mouse_darker = handles.mouse_darker_radiobutton.Value;
detection_methods(rel_ind).auto_determine_color = handles.auto_determine_brighter_radiobutton.Value;

if handles.user_defined_background_radiobutton.Value
    detection_methods(rel_ind).BackGroundImage = handles.CurrentUserBackGround;
else
    detection_methods(rel_ind).BackGroundImage = [];
end

if current_method_user_defined
    detection_methods(rel_ind).user_defined_params = current_param_vals;
    detection_methods(rel_ind).user_defined_param_names = param_names;
    detection_methods(rel_ind).user_method_name = user_method_name;
    detection_methods(rel_ind).user_method_runstring = user_method_runstring;
else
    detection_methods(rel_ind).user_defined_params = [];
    detection_methods(rel_ind).user_defined_param_names = [];
    detection_methods(rel_ind).user_method_name = [];
    detection_methods(rel_ind).user_method_runstring = [];
end


if ~isempty(detection_methods)
    handles.calculate_position_button.Enable = 'on';
    handles.add_to_batch_button.Enable = 'on';
    handles.save_method_button.Enable = 'on';
else
    handles.calculate_position_button.Enable = 'off';
    handles.add_to_batch_button.Enable = 'off';
    handles.save_method_button.Enable = 'off';
end

if length(detection_methods) > 1
    handles.set_method_as_default.Enable = 'on';
else
    handles.set_method_as_default.Enable = 'off';
end

% Update the handles structure
handles.detection_methods = detection_methods;

% Update the methods
guidata(hObject, handles);

return



% --- Executes on button press in remove_selected_method.
function remove_selected_method_Callback(hObject, eventdata, handles)

detection_methods = handles.detection_methods;

% Get name of selected method
mstrings = handles.method_listbox.String;

% if there is nothing to delete
if isempty(detection_methods)
    % just make sure that the list is empty
    handles.method_listbox.String = '';
    return
end

detection_method_names = {detection_methods.name};

% if there is nothing to delete
if isempty(mstrings)    
    return
end

mstring  = mstrings{handles.method_listbox.Value};

% find relevant entry - should always be one
rel_ind = strmatch(mstring,detection_method_names,'exact');

% remove string from list
mstrings(rel_ind) = [];
handles.method_listbox.String = mstrings;
% move to the previous value, I think this should work
if handles.method_listbox.Value > 1
    handles.method_listbox.Value = handles.method_listbox.Value - 1;
end

detection_methods(rel_ind) = [];

if ~isempty(detection_methods)
    handles.calculate_position_button.Enable = 'on';
    handles.add_to_batch_button.Enable = 'on';
    handles.save_method_button.Enable = 'on';
else
    handles.calculate_position_button.Enable = 'off';
    handles.add_to_batch_button.Enable = 'off';
    handles.save_method_button.Enable = 'off';
end


if length(detection_methods) > 1
    handles.set_method_as_default.Enable = 'on';
else
    handles.set_method_as_default.Enable = 'off';
end

handles.detection_methods = detection_methods;
guidata(hObject,handles);


% --- Executes on button press in save_method_button.
function save_method_button_Callback(hObject, eventdata, handles)
contents = cellstr(get(handles.arena_folder_listbox,'String'));
% tmp_file_folder = [handles.video_dir_text.String filesep contents{get(handles.arena_folder_listbox,'Value')}];

arena_folder = [handles.video_dir_text.String filesep 'arenas'];
base_name = contents{get(handles.arena_folder_listbox,'Value')};
% info_file   = dir([arena_folder filesep base_name '*_info.mat']);

position_dir = [handles.video_dir_text.String filesep 'positions' ];
% position file
position_file = [position_dir filesep base_name '_positions.mat'];


% Define the detection settings folder (create it if it does not exist)
detection_settings_folder = [handles.video_dir_text.String filesep 'detection_settings'];
if ~exist(detection_settings_folder,'dir')
    mkdir(detection_settings_folder);
end

% Get the current methods
detection_methods = handles.detection_methods;

% Note that this file name is different from the one created when the run
% button is pressed. This one does not contain the file name
detection_methods_file_name = [detection_settings_folder filesep 'detection_settings_' base_name  '.mat'];

[sel_detection_methods_file_name,sel_detection_methods_path] = uiputfile(detection_methods_file_name,'save detection settings');

if sel_detection_methods_file_name
    save([sel_detection_methods_path sel_detection_methods_file_name],'detection_methods');
    msgbox(['methods saved in ' sel_detection_methods_file_name ],'Calculate Positions')
end



% --- Executes on button press in load_method_button.
function load_method_button_Callback(hObject, eventdata, handles)
contents = cellstr(get(handles.arena_folder_listbox,'String'));
arena_folder = [handles.video_dir_text.String filesep 'arenas'];
base_name = contents{get(handles.arena_folder_listbox,'Value')};
position_dir = [handles.video_dir_text.String filesep 'positions' ];
position_file = [position_dir filesep base_name '_positions.mat'];

% Define the detection settings folder (create it if it does not exist)
detection_settings_folder = [handles.video_dir_text.String filesep 'detection_settings'];
if ~exist(detection_settings_folder,'dir')
    mkdir(detection_settings_folder);
end

% Get the deafult file name
detection_methods_file_name = [detection_settings_folder filesep 'detection_settings_' base_name  '.mat'];

if exist(detection_methods_file_name,'file')
    filterspec = detection_methods_file_name;
else
    filterspec = [detection_settings_folder filesep '*detection_settings*.mat'];
end

[detection_file, detection_path, ~] = uigetfile(filterspec, 'select detection settings file');
if ~detection_file
    return
end
fullfilename = [detection_path detection_file];

D = load(fullfilename);

if ~isfield(D,'detection_methods')
    return
else
    % update the listbox
    detection_methods = D.detection_methods;
    handles.detection_methods = detection_methods;
    handles.method_listbox.String = {detection_methods.name};
    handles.method_listbox.Value = 1;
    % Update handles structure
    guidata(hObject, handles);
    % update the displa
    method_listbox_Callback(hObject, eventdata, handles)
    
    handles.remove_selected_method.Enable = 'on';
    handles.calculate_position_button.Enable = 'on';
    handles.add_to_batch_button.Enable = 'on';
    handles.save_method_button.Enable = 'on';
    if length(detection_methods) > 1
        handles.set_method_as_default.Enable = 'on';
    else
        handles.set_method_as_default.Enable = 'off';
    end
end


% --- Executes on button press in set_method_as_default.
function set_method_as_default_Callback(hObject, eventdata, handles)

detection_methods = handles.detection_methods;
mstrings = handles.method_listbox.String;

if length(mstrings) < 2
    return
end

current_value = handles.method_listbox.Value;
if current_value == 1 % it is already the default
    return
end

new_detection_methods = detection_methods;
new_detection_methods(1) = detection_methods(current_value);
new_detection_methods(current_value) = detection_methods(1);

handles.method_listbox.String = {new_detection_methods.name};
handles.method_listbox.Value = 1;

handles.detection_methods = new_detection_methods;
% Update handles structure
guidata(hObject, handles);
% update the displa
method_listbox_Callback(hObject, eventdata, handles)




function user_param1_edit_Callback(hObject, eventdata, handles)
user_param_edit_callback(handles,hObject,1)
update_arena_images(handles);



function user_param1_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function user_param2_edit_Callback(hObject, eventdata, handles)
user_param_edit_callback(handles,hObject,2)
update_arena_images(handles);


% --- Executes during object creation, after setting all properties.
function user_param2_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function user_param3_edit_Callback(hObject, eventdata, handles)
user_param_edit_callback(handles,hObject,3)
update_arena_images(handles);


function user_param3_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function user_param4_edit_Callback(hObject, eventdata, handles)
user_param_edit_callback(handles,hObject,4)
update_arena_images(handles);

function user_param4_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function user_param5_edit_Callback(hObject, eventdata, handles)
user_param_edit_callback(handles,hObject,5)
update_arena_images(handles);

function user_param5_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function user_comment_edit_Callback(hObject, eventdata, handles)



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



% --- Executes on button press in import_image_button.
function import_image_button_Callback(hObject, eventdata, handles)
% AI is arena info
AI = load(handles.full_info_file_name);
make_background_fromvideo(AI);




function go_to_time_edit_Callback(hObject, eventdata, handles)

framestr = get(handles.current_frame_edit,'String');
frametimestr = get(handles.go_to_time_edit,'String');

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
function go_to_time_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to go_to_time_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function calculate_positions_keyPress(src,e,hObject,eventdata,handles)
 
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


if strcmp(e.Modifier,'shift')
    stepsize = round(1/handles.data.SI);
else
    stepsize = 1;
end

switch e.Key
    case 'rightarrow'       
        this_frame = str2num(handles.current_frame_edit.String);
        if this_frame+stepsize <= handles.Nframes
            next_frame = this_frame + stepsize;
            handles.current_frame_edit.String = num2str(next_frame);
            handles.go_to_time_edit.String = num2str(next_frame*handles.data.SI,'%.2f');
            handles.frame_select_slider.Value = next_frame;
            guidata(hObject, handles);
            update_arena_images(handles);
        end
        
    case 'leftarrow'
        this_frame = str2num(handles.current_frame_edit.String);
        if this_frame > stepsize
            prev_frame = this_frame - stepsize;
            handles.current_frame_edit.String = num2str(prev_frame);
            handles.go_to_time_edit.String = num2str(prev_frame*handles.data.SI,'%.2f');
            handles.frame_select_slider.Value = prev_frame;
            guidata(hObject, handles);
            update_arena_images(handles);
        end
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
