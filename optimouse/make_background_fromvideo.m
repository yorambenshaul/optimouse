function varargout = make_background_fromvideo(varargin)
% YBS 9/16
% MAKE_BACKGROUND_FROMVIDEO MATLAB code for make_background_fromvideo.fig
%      MAKE_BACKGROUND_FROMVIDEO, by itself, creates a new MAKE_BACKGROUND_FROMVIDEO or raises the existing
%      singleton*.
%
%      H = MAKE_BACKGROUND_FROMVIDEO returns the handle to a new MAKE_BACKGROUND_FROMVIDEO or the handle to
%      the existing singleton*.
%
%      MAKE_BACKGROUND_FROMVIDEO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAKE_BACKGROUND_FROMVIDEO.M with the given input arguments.
%
%      MAKE_BACKGROUND_FROMVIDEO('Property','Value',...) creates a new MAKE_BACKGROUND_FROMVIDEO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before make_background_fromvideo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to make_background_fromvideo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help make_background_fromvideo

% Last Modified by GUIDE v2.5 05-Oct-2016 15:31:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @make_background_fromvideo_OpeningFcn, ...
                   'gui_OutputFcn',  @make_background_fromvideo_OutputFcn, ...
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


% --- Executes just before make_background_fromvideo is made visible.
function make_background_fromvideo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to make_background_fromvideo (see VARARGIN)

AI = varargin{end}; % which is the main arena figure
handles.origvideofilename = AI.videofilename;
handles.OriginalImageSizeInPixels = AI.OriginalImageSizeInPixels;
handles.roi_position_in_pixels = AI.arena_info.roi_position_in_pixels;
handles.vertices = AI.arena_info.vertices;     

% save the directory as default for next time
default_path_filename = [get_user_dir 'default_start_dir.mat'];
if exist(default_path_filename) == 2
    D = load(default_path_filename,'folder_name');
    handles.video_dir_text.String = D.folder_name;
end

populate_video_file_list(handles);

% find the original file name in the list and make it selected
video_files = handles.video_file_listbox.String;
[P F E] = fileparts(handles.origvideofilename);
orig_video_file = [F E];
vid_ind = strmatch(orig_video_file,video_files, 'exact');
handles.video_file_listbox.Value = vid_ind;


video_file_listbox_Callback(handles.video_file_listbox,[], handles)
handles = guidata(hObject);

% % % generate the arena list
% % D = dir([handles.video_dir_text.String filesep '*_arena_*.mat']);
% % arena_files = {D.name};
% % handles.arena_listbox.String = arena_files;
% % arena_listbox_Callback(handles.arena_listbox,[], handles)
% % handles = guidata(hObject);

% Choose default command line output for make_background_fromvideo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes make_background_fromvideo wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = make_background_fromvideo_OutputFcn(hObject, eventdata, handles) 
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
    % handles.define_arena_button.Enable = 'off';
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
    
    data.VideoObj = VideoObj;
    
    % handles.define_arena_button.Enable = 'on';        
    data.VideoWidth = VideoObj.Width;
    data.VideoHeight = VideoObj.Height;
    data.Nframes = VideoObj.NumberOfFrames;
    data.vidfilename = vidfilename;
    data.duration = VideoObj.Duration;
    SR = 1/VideoObj.FrameRate;
    
    % check if the selected image has the right dimensions
    good_vid = 1;
    if handles.OriginalImageSizeInPixels(1) ~= data.VideoHeight
        good_vid = 0;
    end
    if handles.OriginalImageSizeInPixels(2) ~= data.VideoWidth
        good_vid = 0;
    end
    if ~good_vid
        [~, F, E] = fileparts(handles.origvideofilename);
        orig_video_file = [F E];
        msgstr{1} = 'Incompatible Dimensions';
        msgstr{2} = ['Selected video cannot be used as background for: ' orig_video_file ];
        msgbox(msgstr,'define background image');
        return
    end
    
    
    
    fn = 1;
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
    
    vertices = handles.vertices;
    
    
% Find rectnagular regions that contain each of the ROIs
% for i = 1:n_rois
    % NOte that the X and Y indices are different for the image and the vertex
    % definitions
    minX = floor(min(vertices(:,1)));
    maxX = ceil(max(vertices(:,1)));
    minY = floor(min(vertices(:,2)));
    maxY = ceil(max(vertices(:,2)));
    R1 = [minX:maxX];
    R2 = [minY:maxY];

    poly_h = plot(vertices(:,1),vertices(:,2));
    set(poly_h,'color','y','linewidth',1,'Tag','ArenaBorder')
    rect_arena_borders(1,:) = [minX minY];
    rect_arena_borders(2,:) = [minX maxY];
    rect_arena_borders(3,:) = [maxX maxY];
    rect_arena_borders(4,:) = [maxX minY];
    rect_arena_borders(5,:) = [minX minY];
    poly_h = plot(rect_arena_borders(:,1),rect_arena_borders(:,2));
    set(poly_h,'color','g','linewidth',1,'Tag','RectArenaBorder')

    
    axes(handles.background_image_axes);
    cla;
    handles.background_image_info_text.String = ['Background image not yet defined'];
    handles.apply_background_buttton.Enable = 'off';

    
    % ASSIGN THE MASK HERE
    
    % Create mask for this arena - the result is masked_frames
    
        
%     Frame = read(VideoObj,fn);        
%     masked_frame = rgb2gray(Frame);
%     c = vertices(:,1);
%     r = vertices(:,2);
%     m = handles.OriginalImageSizeInPixels(1);
%     n = handles.OriginalImageSizeInPixels(2);       
%     arena_mask = poly2mask(c,r,m,n);
%     masked_frame(~arena_mask) =  median(Frame(:));               
%         
%     arena_image = masked_frame(R2,R1); 
%     
%     axes(handles.background_image_axes);    
%     arena_image_h = imagesc(arena_image);
%     colormap gray
%     set(handles.background_image_axes,'XTick',[],'YTick',[])
%     axis equal;
%     axis tight
%     uistack(arena_image_h,'bottom')



    
    
    
   
%         % Create mask for this arena - the result is masked_frames
%         m = aD.ImageSizeInPixels(1);
%         n = aD.ImageSizeInPixels(2);        
%         masked_frames = fulltmpframes;
%         c = aD.ROIs(roi_ind).vertices(:,1);
%         r = aD.ROIs(roi_ind).vertices(:,2);
%         arena_mask_2D = poly2mask(c,r,m,n);
%         arena_mask_3D = repmat(arena_mask_2D,1,1,size(fulltmpframes,3));        
%         
%         masked_frames(~arena_mask_3D) =  median(fulltmpframes(:));               
%         
%         % extract the relevant rectangular region from the (masked) image
%         % saving it until the index k should cae of the last segment which 
%         % typically is smaller (unless the entire number of frames is exactly
%         % a multiple of framesperblock)
%         ROI_tmp_frames = masked_frames(R2{roi_ind},R1{roi_ind},1:k); 
% 
% % plot polygons over arena - and text with arena name at the center
% for i = 1:length(ROIs)
%     poly_h = plot(aD.ROIs(i).vertices(:,1),aD.ROIs(i).vertices(:,2));
%     set(poly_h,'color','y','linewidth',1,'Tag','ArenaBorder')
%     poly_th = text(aD.ROIs(i).center(1),aD.ROIs(i).center(2),aD.ROIs(i).name);
%     set(poly_th,'Color','y','Tag','ArenaText','HorizontalAlignment','Center', 'VerticalAlignment','middle');
% end
 
    
    
    handles = guidata(handles.figure1);
  %   arena_listbox_Callback(handles.arena_listbox,[], handles);
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
    default_path_filename = [get_user_dir 'default_start_dir.mat'] ;   
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
if ~isempty(contents)
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

% plot polygons over arena - and text with arena name at the center
for i = 1:length(ROIs)
    poly_h = plot(aD.ROIs(i).vertices(:,1),aD.ROIs(i).vertices(:,2));
    set(poly_h,'color','y','linewidth',1,'Tag','ArenaBorder')
    poly_th = text(aD.ROIs(i).center(1),aD.ROIs(i).center(2),aD.ROIs(i).name);
    set(poly_th,'Color','y','Tag','ArenaText','HorizontalAlignment','Center', 'VerticalAlignment','middle');
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
    hObject.String = num2str(str2num(framestr)/handles.SR, '%.2f');
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




function user_defined_background_frames_text_Callback(hObject, eventdata, handles)

% calculate frames for background
framestr = handles.user_defined_background_frames_text.String;


if ~isempty(framestr)
    try
        eval(['FramesForBackground = [' framestr '];']);
    catch
        errordlg('invalid frame input');
        handles.user_defined_background_frames_text.String = '';
        return
    end
else
    return
end


if isempty(FramesForBackground)
    errordlg('invalid frame input');
    handles.user_defined_background_frames_text.String = '';
    return
end

if ~isa(FramesForBackground,'numeric')
    errordlg('invalid frame input');
    handles.user_defined_background_frames_text.String = '';
    return
end

% Check that all frames are integer numbers
if sum(rem(FramesForBackground,1))
    errordlg('frame numbers must be integers');
    handles.user_defined_background_frames_text.String = '';
    return
end

if max(FramesForBackground) > handles.data.Nframes
    errordlg('Selected frames are outside of frame range');
    handles.user_defined_background_frames_text.String = '';
    return
end

if min(FramesForBackground) < 1
    errordlg('Selected frames are outside of frame range');
    handles.user_defined_background_frames_text.String = '';
    return
end


% --- Executes during object creation, after setting all properties.
function user_defined_background_frames_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to user_defined_background_frames_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in create_background_button.
function create_background_button_Callback(hObject, eventdata, handles)

% Error checking for framestr already implemented in its own callback
framestr = handles.user_defined_background_frames_text.String;

if ~isempty(framestr)
    try
        eval(['FramesForBackground = [' framestr '];']);
    catch
        errordlg('invalid frame input');
        handles.user_defined_background_frames_text.String = '';
        return
    end
else
    return
end

FramesForBackground = sort(FramesForBackground);

NF = length(FramesForBackground);

% Check that not too many frames were selected
if NF > 1000
    answer = questdlg([num2str(NF) ' frames were selected for background. This might take some time. Continue?'],'Create Background Image','Continue','Cancel','Continue');
    if strcmp(answer,'Cancel')
        return
    end   
end

BackGroundImage = [];

% initialize structure for images
MedianFrames = zeros(handles.OriginalImageSizeInPixels(1),handles.OriginalImageSizeInPixels(2),length(FramesForBackground));

progbar_h = waitbar(0,['calculating background images from ' num2str(length(FramesForBackground)) ' frames'],'Name','Calculating background image');

% Start running over all frames, as long as we are not beyond first or last frame
k = 1;
for frc = FramesForBackground
    MedianFrames(:,:,k) = rgb2gray(read(handles.data.VideoObj,frc));            
    % counter of total frames
    k = k + 1;      
    
    % update wait bar and return if it was closed by user
    if ishandle(progbar_h)
        waitbar(k/length(FramesForBackground),progbar_h,['calculating background images from ' num2str(length(FramesForBackground)) ' frames']);
    else
        msgbox('Background image calculation terminated by user','OptiMouse - Custom Image');
        return
    end
end

% done
delete(progbar_h); 


% vertices define the arena
vertices = handles.vertices;

% Create the mask
c = vertices(:,1);
r = vertices(:,2);
m = handles.OriginalImageSizeInPixels(1);
n = handles.OriginalImageSizeInPixels(2);
arena_mask_2D = poly2mask(c,r,m,n);
arena_mask_3D = repmat(arena_mask_2D,1,1,length(FramesForBackground));

% Get the rectangle containing the frame
minX = floor(min(vertices(:,1)));
maxX = ceil(max(vertices(:,1)));
minY = floor(min(vertices(:,2)));
maxY = ceil(max(vertices(:,2)));
% make sure that clipped area does not exceed image boundaries
if minX < 1
    minX = 1;
end
if maxX > n
    maxX = n;
end
if minY < 1
    minY = 1;
end   
if maxY > m
    maxY = m;
end
R1 = [minX:maxX];
R2 = [minY:maxY];


             
% Apply the mask - which ammounts to setting all non-masked pixels to the 
% median value
MedianFrames(~arena_mask_3D) =  median(MedianFrames(:));
        
% Take only the part within the rectangle containing the arena
arena_background_frames = MedianFrames(R2,R1,:);  
% Make it into a uin8, and that is the finalr esult
BackGroundImage = uint8(median(arena_background_frames,3));

% update the display
axes(handles.background_image_axes);
arena_image_h = imagesc(BackGroundImage);
colormap gray
set(handles.background_image_axes,'XTick',[],'YTick',[])
axis equal;
axis tight
if NF == 1
    handles.background_image_info_text.String = ['Background image calculated with frame # ' num2str(FramesForBackground) ];
else
    handles.background_image_info_text.String = ['Background image (calculated with ' num2str(NF) ' frames)'];
end

% enable the apply button
handles.apply_background_buttton.Enable = 'on';

% save resuls in current figure's data
handles.CurrentUserBackGround = BackGroundImage;
guidata(hObject,handles);






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


figure; imagesc(BackGroundImage);
colormap gray
colorbar
axis equal
axis tight
set(gca,'XTick',[],'YTick',[]);
th = title([ backtype ' background for ' info_file(1).name]);
set(th,'Interpreter','none')





function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_background_button.
function save_background_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_background_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% ButtonName = questdlg('Really close? Any unsaved settings will be erased. Continue?', ...
%     'Optimouse', 'Cancel', 'Close', 'Cancel');
% if strcmp(ButtonName,'Cancel')
%         return        
% end
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in load_background_image.
function load_background_image_Callback(hObject, eventdata, handles)
% hObject    handle to load_background_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in set_current_frame_as_background_button.
function set_current_frame_as_background_button_Callback(hObject, eventdata, handles)
% Error checking for framestr already implemented in its own callback
handles.user_defined_background_frames_text.String = handles.current_frame_edit.String;
create_background_button_Callback(hObject, eventdata, handles)


% --- Executes on button press in previous_frame_button.
function previous_frame_button_Callback(hObject, eventdata, handles)
this_frame = str2num(handles.current_frame_edit.String);
if this_frame > 1
    prev_frame = this_frame - 1;
    handles.current_frame_edit.String = num2str(prev_frame);   
end
current_frame_edit_Callback(hObject, eventdata, handles)

% --- Executes on button press in next_frame_button.
function next_frame_button_Callback(hObject, eventdata, handles)
this_frame = str2num(handles.current_frame_edit.String);
if this_frame < handles.data.Nframes-6
    next_frame = this_frame + 1;
    handles.current_frame_edit.String = num2str(next_frame);   
end
current_frame_edit_Callback(hObject, eventdata, handles)


% --- Executes on button press in apply_background_buttton.
function apply_background_buttton_Callback(hObject, eventdata, handles)

% save resuls in current figure's data
BackGroundImage = handles.CurrentUserBackGround;
guidata(hObject,handles);


% save the result as background image in the calculate_positions_interface
ofh = findobj('name','optimouse - calculate positions');

% if there is no detect GUI, we cannot apply the definition
if isempty(ofh)   
    errordlg('Cannot apply background image because the DETECT POSITIONS interface is closed','OptiMOuse custom background')
    return
end

orig_fig_handles   = guidata(ofh);
orig_fig_handles.CurrentUserBackGround = BackGroundImage;

guidata(ofh,orig_fig_handles);

% enable the radio button in the calculate interface
orig_fig_handles.user_defined_background_radiobutton.Enable = 'on';        

% If this option is selected, then apply it
if orig_fig_handles.user_defined_background_radiobutton.Value    
    calculate_positions_in_arena_mm('user_defined_background_radiobutton_Callback', ...
        orig_fig_handles.user_defined_background_radiobutton, [],orig_fig_handles);
end
