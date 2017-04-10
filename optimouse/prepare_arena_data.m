function varargout = prepare_arena_data(varargin)
% YBS 9/16
% PREPARE_ARENA_DATA MATLAB code for prepare_arena_data.fig
%      PREPARE_ARENA_DATA, by itself, creates a new PREPARE_ARENA_DATA or raises the existing
%      singleton*.
%
%      H = PREPARE_ARENA_DATA returns the handle to a new PREPARE_ARENA_DATA or the handle to
%      the existing singleton*.
%
%      PREPARE_ARENA_DATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREPARE_ARENA_DATA.M with the given input arguments.
%
%      PREPARE_ARENA_DATA('Property','Value',...) creates a new PREPARE_ARENA_DATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before prepare_arena_data_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to prepare_arena_data_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help prepare_arena_data

% Last Modified by GUIDE v2.5 19-Oct-2016 15:07:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @prepare_arena_data_OpeningFcn, ...
                   'gui_OutputFcn',  @prepare_arena_data_OutputFcn, ...
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


% --- Executes just before prepare_arena_data is made visible.
function prepare_arena_data_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to prepare_arena_data (see VARARGIN)

% save the directory as default for next time
default_path_filename = [get_user_dir 'default_start_dir.mat'];
if exist(default_path_filename) == 2
    D = load(default_path_filename,'folder_name');
    handles.video_dir_text.String = D.folder_name;
end

populate_video_file_list(handles);
video_file_listbox_Callback(handles.video_file_listbox,[], handles)
handles = guidata(hObject);

% generate the arena list
D = dir([handles.video_dir_text.String filesep '*_arena_*.mat']);
arena_files = {D.name};
handles.arena_listbox.String = arena_files;
arena_listbox_Callback(handles.arena_listbox,[], handles)
handles = guidata(hObject);

% Choose default command line output for prepare_arena_data
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes prepare_arena_data wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = prepare_arena_data_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in video_file_listbox.
function video_file_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to video_file_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns video_file_listbox contents as cell array
%  contents{get(hObject,'Value')}       returns selected item from video_file_listbox

if isempty(handles.video_file_listbox.String)
    cla(handles.main_video_axes)
    handles.define_arena_button.Enable = 'off';
    handles.current_frame_info_text.String = '';
    return
else    
    
    contents = cellstr(get(handles.video_file_listbox,'String')); 
    
    % reset info string
    handles.movie_info_text.String = [];
    
    cla(handles.main_video_axes)
    axes(handles.main_video_axes);
    handles.main_video_axes.YDir = 'reverse';
    hold on
    
    vidfilename = [handles.video_dir_text.String filesep contents{get(handles.video_file_listbox,'Value')}];

    VideoObj=VideoReader(vidfilename);
    fn = 1;
    handles.define_arena_button.Enable = 'on';        
    data.VideoWidth = VideoObj.Width;
    data.VideoHeight = VideoObj.Height;
    data.Nframes = VideoObj.NumberOfFrames;
    data.vidfilename = vidfilename;
    data.duration = VideoObj.Duration;
    SR = 1/VideoObj.FrameRate;
    handles.SR = SR;
    handles.data = data;        
    handles.current_frame_slider.Value = 1;
    handles.current_frame_edit.String  = '1';
    handles.current_frame_slider.Max = data.Nframes;
    handles.current_frame_slider.Min = 1;    
    handles.last_frame_edit.String = num2str(data.Nframes);
    handles.first_frame_edit.String = '1';
    
    
    onesecond = (1/data.duration);
    oneminute = (onesecond*60);
    try
        handles.current_frame_slider.SliderStep = [onesecond oneminute];
    catch
    end

    
    
    % update frame time string
    handles.go_to_time_edit.String = num2str(handles.SR * 1, '%.2f') ;
        
    % update videp info string
    video_info_str{1} = ['Duration: ' num2str(VideoObj.Duration) ' s'];
    video_info_str{2} = ['Width: ' num2str(VideoObj.Width) ' pixels'];
    video_info_str{3} = ['Height: ' num2str(VideoObj.Height) ' pixels'];
    video_info_str{4} = ['Frame rate: ' num2str(VideoObj.FrameRate) ' Hz'];
    video_info_str{5} = ['Bits (per pixel): ' num2str(VideoObj.BitsPerPixel)];
    video_info_str{6} = ['Format: ' VideoObj.VideoFormat];
    handles.movie_info_text.String = video_info_str;
    
    update_arena_image(handles.figure1,handles,fn);    
    handles = guidata(handles.figure1);
    arena_listbox_Callback(handles.arena_listbox,[], handles);
    guidata(handles.figure1, handles);
end
return

% --- Executes during object creation, after setting all properties.
function video_file_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to video_file_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in arena_listbox.
function arena_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to arena_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns arena_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from arena_listbox

% First update thje list
D1 = dir([handles.video_dir_text.String filesep 'arenas' filesep '*_arenas*.mat']);
all_arena_files = {D1.name};

D2 = dir([handles.video_dir_text.String filesep 'arenas' filesep '*_arenas*_info.mat']);
info_arena_files = {D2.name};
arena_files = setdiff(all_arena_files,info_arena_files);

% Take only relevant files
pattern = handles.arena_definition_file_filter_edit.String;
if ~isempty(pattern)
    pat_match = strfind(arena_files, pattern);
    take_files = [];
    for i = 1:length(pat_match)
        if ~isempty(pat_match{i})
            take_files = [take_files i];
        end
    end
else
    take_files = 1:length(arena_files);
end

arena_files = arena_files(take_files);

if ~isempty(arena_files)
    handles.arena_listbox.String = arena_files;  
else
    handles.arena_listbox.String = '';  
end

handles.process_arenas_button.Enable = 'off';
handles.add_to_batch_button.Enable = 'off';

% Remove previous arena
delete(findobj(handles.figure1,'Tag','ArenaBorder'));
delete(findobj(handles.figure1,'Tag','ArenaText'));


guidata(hObject, handles);

return


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
    populate_video_file_list(handles)
    video_file_listbox_Callback(handles.video_file_listbox,[], handles);    
    % save the directory as default for next time
    default_path_filename = [get_user_dir 'default_start_dir.mat'];
    save(default_path_filename,'folder_name')    
end

% --- Executes on selection change in other_arenas_listbox.
function other_arenas_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to other_arenas_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns other_arenas_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from other_arenas_listbox


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


% --- Executes on button press in process_arenas_button.
function process_arenas_button_Callback(hObject, eventdata, handles,batch_mode)

if nargin == 3
    batch_mode = 0;
end

contents = cellstr(get(handles.video_file_listbox,'String')); 
vidfilename = [handles.video_dir_text.String filesep contents{get(handles.video_file_listbox,'Value')}];
 
contents = cellstr(get(handles.arena_listbox,'String')); 
arenafilename = [handles.video_dir_text.String filesep 'arenas' filesep contents{get(handles.arena_listbox,'Value')}];

ffs  =  handles.first_frame_edit.String;
lfs  =  handles.last_frame_edit.String;
ff  =  str2num(ffs);
lf  = str2num(lfs);
nframes_to_do = lf - ff + 1;

% Play with this to optimize performance - 
% considerations are memory per block, vs. processing time for each block
framesperblock = 100; % data.framesperblock;

% Make sure that the blocks are smaller than the number of frames
if nframes_to_do < framesperblock
    framesperblock = nframes_to_do;
end

raw_user_string = handles.user_comment_edit.String;
user_string = '';
for i = 1:size(raw_user_string,1)
  thisline = strtrim(raw_user_string(i,:));
  user_string = [user_string ' ' thisline];
end
user_string = strtrim(user_string);



% generate command string - which can be appended to batch file or run
% directly
cmdstr = ['prepare_arenas(''' vidfilename ''',''' arenafilename ''',' ffs ',' lfs ',' num2str(framesperblock) ',''' user_string ''')' ];
if ~batch_mode
    %profile on
    tic % added for testing time
    eval(cmdstr);    
    toc % added for testing time
    %profile report
else    
    batch_file = [get_user_dir 'prepare_arena_batch.m'];    
    [~,VF,~] = fileparts(vidfilename);
    [~,AF,~] = fileparts(arenafilename);
    fileID = fopen(batch_file,'a');
    
    cleandmdstr = cmdstr;
    cleandmdstr((findstr('''',cleandmdstr))) = [];
    
    comment_str = ['% batch command from ' datestr(now) ]; 
    fprintf(fileID,'%s\n',comment_str);
    fprintf(fileID,'%s\n',['% video file: ' VF]);
    fprintf(fileID,'%s\n',['% arena file: ' AF]);
    fprintf(fileID,'%s\n',['% frames: ' ffs ' to ' lfs ]);            
    fprintf(fileID,'%s\n',['disp(''now running '  cleandmdstr    ''')' ]);
    fprintf(fileID,'%s\n\n',cmdstr);    
    fclose(fileID);  
end
    


% --- Executes on button press in calculate_mouse_positions_button.
function calculate_mouse_positions_button_Callback(hObject, eventdata, handles)
% hObject    handle to calculate_mouse_positions_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function current_frame_edit_Callback(hObject, eventdata, handles)

editstr = get(handles.current_frame_edit,'String');

ok = check_framenum_string(editstr,1,handles.data.Nframes-5);
if ~ok
    errordlg(['frame number must be an integer between 1 and (5 before) the last movie frame'],'frame range','modal');
    hObject.String = '1';
end

fn = round(str2double(get(handles.current_frame_edit,'String')));

handles.go_to_time_edit.String = num2str(handles.SR * fn, '%.2f');


handles.current_frame_edit.String = num2str(fn);
handles.current_frame_slider.Value = fn;
update_arena_image(handles.current_frame_edit,handles,fn);

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
function current_frame_slider_Callback(hObject, eventdata, handles)

fn = round(get(handles.current_frame_slider,'Value'));

if fn < 1 
    fn = 1;
elseif fn > handles.data.Nframes-5
    fn = handles.data.Nframes-5;
end

handles.current_frame_edit.String = num2str(fn);
% The edit frame callback will update the display
current_frame_edit_Callback(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function current_frame_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to current_frame_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function first_frame_edit_Callback(hObject, eventdata, handles)

editstr = get(hObject,'String');

end_frame = str2num(handles.last_frame_edit.String);

ok = check_framenum_string(editstr,1,end_frame);
if ~ok
    errordlg(['frame number must be an integer between 1 and the ''end frame'' frame'],'frame range','modal');
    hObject.String = '1';
end


% --- Executes during object creation, after setting all properties.
function first_frame_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to first_frame_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function last_frame_edit_Callback(hObject, eventdata, handles)

editstr = get(hObject,'String');
first_frame = str2num(handles.first_frame_edit.String);

ok = check_framenum_string(editstr,first_frame,handles.data.Nframes);
if ~ok
    errordlg(['frame number must be an integer between the ''first frame'' and the last frame in the movie'],'frame range','modal');
    hObject.String = num2str(handles.data.Nframes);
end

% --- Executes during object creation, after setting all properties.
function last_frame_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to last_frame_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in apply_selected_arena_button.
function apply_selected_arena_button_Callback(hObject, eventdata, handles)


contents = cellstr(get(handles.video_file_listbox,'String')); 
vidfilename = [handles.video_dir_text.String filesep contents{get(handles.video_file_listbox,'Value')}];
 
contents = cellstr(get(handles.arena_listbox,'String')); 
if ~isempty(contents{1})
    arenafilename = [handles.video_dir_text.String filesep 'arenas' filesep contents{get(handles.arena_listbox,'Value')}];    
else
    return
end

vD = handles.data;
aD = load(arenafilename);

% check if the current video file and the file on which the ROI was defined
% have the same dimensions:
same_height = vD.VideoHeight == aD.ImageSizeInPixels(1);
same_width  = vD.VideoWidth  == aD.ImageSizeInPixels(2);
if ~(same_height&&same_width)
    msgbox('cannot apply arena: current video file does not have the same dimensions as file used for arena definition');
    return
end
 
% Check if the same file was used to generate them and if not, warn the user
if ~strcmp(vD.vidfilename,aD.vidfilename)
      queststr = ['Arena was not defined on current video file. Apply anyway?'];      
      ButtonName = questdlg(queststr ,'Apply Arena','Apply','Cancel','Cancel');
      switch ButtonName,
          case 'Cancel',
              update_display = 0;              
          case 'Apply'          
              update_display = 1;
      end
else
    update_display = 1;    
end

if ~update_display
    return
end

% If we update, delete all previous (arena and text) objects
delete(findobj(handles.figure1,'Tag','ArenaBorder'));
delete(findobj(handles.figure1,'Tag','ArenaText'));


ROIs= aD.ROIs;
ROI_names = {ROIs.name};

axes(handles.main_video_axes);

% plot polygons over arena - and text with arena name at the center
for i = 1:length(ROIs)
    poly_h = plot(aD.ROIs(i).vertices(:,1),aD.ROIs(i).vertices(:,2));
    set(poly_h,'color','y','linewidth',1,'Tag','ArenaBorder')
    poly_th = text(aD.ROIs(i).center(1),aD.ROIs(i).center(2),aD.ROIs(i).name);
    set(poly_th,'Color','y','Tag','ArenaText','HorizontalAlignment','Center', 'VerticalAlignment','middle','Interpreter','none');
end


handles.process_arenas_button.Enable = 'on';
handles.add_to_batch_button.Enable = 'on';


guidata(hObject, handles);


% --- Executes on button press in add_to_batch_button.
function add_to_batch_button_Callback(hObject, eventdata, handles)
% hObject    handle to add_to_batch_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process_arenas_button_Callback(hObject, eventdata, handles,1);


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in define_new_arena_button.
function define_new_arena_button_Callback(hObject, eventdata, handles)
% hObject    handle to define_new_arena_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
define_arenas(handles);



function file_name_filter_edit_Callback(hObject, eventdata, handles)
populate_video_file_list(handles);
video_file_listbox_Callback(hObject, eventdata, handles);

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



function arena_definition_file_filter_edit_Callback(hObject, eventdata, handles)
% hObject    handle to arena_definition_file_filter_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of arena_definition_file_filter_edit as text
%        str2double(get(hObject,'String')) returns contents of arena_definition_file_filter_edit as a double
arena_listbox_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function arena_definition_file_filter_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to arena_definition_file_filter_edit (see GCBO)
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



function go_to_time_edit_Callback(hObject, eventdata, handles)

framestr = get(handles.current_frame_edit,'String');
frametimestr = get(handles.go_to_time_edit,'String');

ok = check_frametime_string(frametimestr,0,handles.data.duration);
if ~ok
    errordlg(['Time value valid or out of movie range'],'frame range','modal');
    handles.go_to_time_edit.String = num2str(str2num(framestr)*handles.SR,'%.2f');
    return
end

frametime = str2num(frametimestr);

% find the closest time to this frame
all_times = [1:handles.data.Nframes]*handles.SR;
[~,fn] = min(abs(all_times - frametime));

%but make sure it is not the last 5, which make the reader get stuck
fn = min(fn,handles.data.Nframes-5);

handles.current_frame_edit.String = num2str(fn);
handles.current_frame_slider.Value = fn;
update_arena_image(handles.current_frame_edit,handles,fn);




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


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% % ButtonName = questdlg('Really close? Any unsaved settings will be erased. Continue?', ...
% %     'Optimouse', 'Cancel', 'Close', 'Cancel');
% % if strcmp(ButtonName,'Cancel')
% %         return        
% % end
% Hint: delete(hObject) closes the figure
delete(hObject);
