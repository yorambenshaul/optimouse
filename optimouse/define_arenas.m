function varargout = define_arenas(varargin)
% YBS 9/16
% DEFINE_ARENAS MATLAB code for define_arenas.fig
%      DEFINE_ARENAS, by itself, creates a new DEFINE_ARENAS or raises the existing
%      singleton*.
%
%      H = DEFINE_ARENAS returns the handle to a new DEFINE_ARENAS or the handle to
%      the existing singleton*.
%
%      DEFINE_ARENAS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DEFINE_ARENAS.M with the given input arguments.
%
%      DEFINE_ARENAS('Property','Value',...) creates a new DEFINE_ARENAS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before define_arenas_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to define_arenas_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help define_arenas

% Last Modified by GUIDE v2.5 29-Sep-2016 17:37:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @define_arenas_OpeningFcn, ...
                   'gui_OutputFcn',  @define_arenas_OutputFcn, ...
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


% --- Executes just before define_arenas is made visible.
function define_arenas_OpeningFcn(hObject, eventdata, handles, varargin)
calling_fig_handles = varargin{end}; % which is the main arena figure
contents = cellstr(get(calling_fig_handles.video_file_listbox,'String')); 
vidfilename = [calling_fig_handles.video_dir_text.String filesep contents{get(calling_fig_handles.video_file_listbox,'Value')}];

start_frame = 1;
axes(handles.original_video_axes);
box on
set(gca,'Ydir','reverse')
hold on

VideoObj=VideoReader(vidfilename);
Frame = read(VideoObj,start_frame);
current_image_h = imagesc(Frame); 
UD.nframes = VideoObj.NumberOfFrames;
UD.SR = 1/VideoObj.FrameRate;
UD.Duration = VideoObj.Duration;

curtime = UD.SR;
totaltime = UD.Duration;
info_str{1} = ['Frame: ' num2str(start_frame) ' of ' num2str(UD.nframes) ];
info_str{2} = [num2str(curtime,'%.2f') ' secs of ' num2str(totaltime,'%.2f')];
handles.define_arena_fig_text.String = info_str;
handles.current_time_edit.String = num2str(curtime,'%.2f');

% Define axis and colormap properties
axis equal; % axis off; 
axis tight
xlabel('pixels')
ylabel('pixels')

UD.colors = [1 0 0; 0 1 0; 0 0 1 ; 1 1 0 ; 1 0 1; 0 1 1 ;  0 1 0.5];
UD.vobj = VideoObj;
UD.ImageSizeInPixels = [size(Frame,1) size(Frame,2)];
UD.current_image_h = current_image_h;
UD.vidfilename = vidfilename;

handles.UD = UD;

% initialize slider
handles.current_frame_slider.Min = 1;
handles.current_frame_slider.Max = UD.nframes-5;
handles.current_frame_slider.Value = 1;

onesecond = (1/UD.Duration);
oneminute = (onesecond*60);
try
    handles.current_frame_slider.SliderStep = [onesecond oneminute];
catch
end

% Initialize the zones structure
handles.zones = [];

% Update handles structure
guidata(hObject, handles);

% Choose default command line output for calculate_positions_in_arena
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = define_arenas_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function current_frame_edit_Callback(hObject, eventdata, handles)
update_frame_for_arena_definition(hObject,handles);


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
update_frame_for_arena_definition(hObject,handles);



% --- Executes during object creation, after setting all properties.
function current_frame_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to current_frame_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in new_zone_button.
function new_zone_button_Callback(hObject, eventdata, handles,duplicate)
% hObject    handle to new_zone_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
    case 'ellipse'
        if duplicate
            start_pos = orig_pos;
        else
            start_pos = [IW/2-IW/10, IH/2-IH/10, IW/5, IH/5];
        end
        zone_h = imellipse(handles.original_video_axes,start_pos);
        fixedRatio = 0;
    case 'rectangle'
        if duplicate
            start_pos = orig_pos;
        else
            start_pos = [IW/2-IW/10, IH/2-IH/10, IW/5, IH/5];
        end
        zone_h = imrect(handles.original_video_axes,start_pos);
        fixedRatio = 0;
    case 'square'
        if duplicate
            start_pos = orig_pos;
        else
            start_pos = [W/2-W/10, W/2-W/10, W/5, W/5];
        end
        zone_h = imrect(handles.original_video_axes,start_pos);
        fixedRatio = 1;
        setFixedAspectRatioMode(zone_h,fixedRatio);
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
end
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
        proposed_name= ['arena ' num2str(zind+gnc)];
        if ~ismember(proposed_name,zone_names)
            good_name = 1;
        end
        gnc = gnc + 1;
    end    
else
    proposed_name = ['arena ' num2str(zind)];   
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
% hObject    handle to zone_type_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns zone_type_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from zone_type_menu


% --- Executes during object creation, after setting all properties.
function zone_type_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zone_type_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on selection change in zone_listbox.
function zone_listbox_Callback(hObject, eventdata, handles)

if isempty(handles.zone_listbox.String)
    return
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


%setResizable(handles.zones(rel_ind).handle,1);
other_inds = find(~rel_ind);
for i = 1:length(other_inds)
    setColor(handles.zones(other_inds(i)).handle,'b'); 
end

guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function zone_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zone_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in edit_zone_position_button.
function edit_zone_position_button_Callback(hObject, eventdata, handles)
% hObject    handle to edit_zone_position_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in delete_zone_button.
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


% --- Executes on button press in rename_zone_button.
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
    errordlg(['A name must be given for the Arena'],'Rename Arena','modal');
    return
end

new_name = answer{1};

% return if name not changed
if strcmp(new_name,current_zone_name)    
    return
end
% return if name exists
if ismember(new_name,zone_names)    
    errordlg(['The name ' current_zone_name ' is already taken'])
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



function save_zone_button_Callback(hObject, eventdata, handles)

% to be saved in arena files
pixels_per_mm = handles.pixels_per_mm;
ImageSizeInPixels = handles.UD.ImageSizeInPixels;

% although the zone interface was used, here these regions are
% called ROIS
ROIs = handles.zones;

if isempty(ROIs)
    uiwait(msgbox('No Arenas were defined','Arena Definition','modal'));
    return
end

% Handles cannot be saved
ROIs = rmfield(ROIs,'handle');

% Find the path and file name to save the arena file
vidfilename = handles.UD.vidfilename;
[P, base_name , ~] = fileparts(vidfilename);
arena_dir = [P filesep 'arenas'];
if ~exist(arena_dir,'dir')
    mkdir(arena_dir)
end

% Find an available file name. To keep name consistenct, users are not
% allowed to name files. 
fn = 1;
file_name_ok = 0;
while ~file_name_ok
    arena_file_name = [arena_dir filesep base_name '_arenas_' num2str(fn) '.mat'];
    if ~exist(arena_file_name,'file')
        file_name_ok = 1;
    end
    fn = fn + 1;
end


% Get ROI positions
for i = 1:length(ROIs)
    ROIs(i).roi_position_in_pixels = getPosition(handles.zones(i).handle);
end

% Since for each type of IMROI the getPosition returns a different type of 
% output, we need specific analysis for each type to extract their
% vertices. 
for i = 1:length(ROIs)
    switch ROIs(i).zone_type
        case {'circle','ellipse'}
            AV{i} = getVertices(handles.zones(i).handle);
        case {'rectangle','square'}
            pos = getPosition(handles.zones(i).handle);
            AV{i}(1,:) = [pos(1) pos(2)];
            AV{i}(2,:) = [pos(1)+pos(3) pos(2)];
            AV{i}(3,:) = [pos(1)+pos(3) pos(2)+pos(4)];
            AV{i}(4,:) = [pos(1)        pos(2)+pos(4)];
            AV{i}(5,:) = [pos(1) pos(2)]; % close the rect
        case {'polygon','freehand'}            
            AV{i} = getPosition(handles.zones(i).handle);
            % close the shape if it is not closed - I think it never will
            % be even if a right mouse click is used
            if ~(AV{i}(size(AV{i},1),1) == AV{i}(1,1) && AV{i}(size(AV{i},1),2) == AV{i}(1,2))            
                AV{i}(size(AV{i},1)+1,:) = AV{i}(1,:);            
            end
    end
    % Find their center positions - this is only required for the
    % text strings describing their location in the arena interface
    ROIs(i).vertices = AV{i};
    min_x = min(AV{i}(:,1));
    max_x = max(AV{i}(:,1));
    cen_x = mean([min_x max_x]);
    min_y = min(AV{i}(:,2));
    max_y = max(AV{i}(:,2));
    cen_y = mean([min_y max_y]);    
    ROIs(i).center = [cen_x cen_y];
end

% Save the arena file and close the figure
save(arena_file_name,'ImageSizeInPixels','pixels_per_mm','vidfilename','ROIs');
msgbox(['arenas saved in ' arena_file_name ],'Define Arenas') 

% Figure of the define arenas 
% add the file to the list in the calling interface, make the current file
% active, and apply the current file
fh = findobj('name','optimouse - prepare sessions');
if ishandle(fh)
    calling_figure_handles = guidata(fh);
    prepare_arena_data('arena_listbox_Callback',fh,eventdata,guidata(fh))
    [~,F,E] = fileparts(arena_file_name);
    short_arena_name = [F E];
    arena_file_ind = strmatch(short_arena_name,calling_figure_handles.arena_listbox.String,'exact');
    if ~isempty(arena_file_ind)
        calling_figure_handles.arena_listbox.Value = arena_file_ind;
        prepare_arena_data('apply_selected_arena_button_Callback',fh,eventdata,calling_figure_handles)
    end
end
drawnow

% close the figure
delete(handles.figure1);



function X_pos_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function X_pos_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to X_pos_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Y_pos_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function Y_pos_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Y_pos_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function width_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function width_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to width_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function height_edit_Callback(hObject, eventdata, handles)
apply_edit_values_to_zone_position(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function height_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to height_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in define_scale_button.
function define_scale_button_Callback(hObject, eventdata, handles)

UD = handles.UD;

% disable the value after calling it
handles.define_scale_button.Enable = 'off';

% Reset - 
% Set scale factor to 1
rescale_axes(handles.original_video_axes,1);
handles.enter_scale_edit.String = '';
% enable the units radio buttons
%handles.pixels_radiobutton.Value = 1;
%handles.mm_radiobutton.Value = 0;

handles.enter_scale_edit.Enable = 'on'; 
handles.apply_sf_button.Enable = 'on';

IH = UD.ImageSizeInPixels(1);
IW = UD.ImageSizeInPixels(2);
SE = (IH+IW)/4; % square edge

start_pos = [IW/2-SE/2, IH/2-SE/2, SE, SE];

calibration_square_h=imrect(handles.original_video_axes,start_pos); %       
setFixedAspectRatioMode(calibration_square_h,1);

calibration_square_h.Deletable = false;
setColor(calibration_square_h,'y');

msg_str{1} = ['Adjust the size of the yellow square.'];
msg_str{2} = ['Then, enter the actual length it represents in the yellow box in MILIMETERS!'];
msg_str{3} = '';
msg_str{4} = ['Click the ''APPLY'' button when done'];

uiwait(msgbox(msg_str,'arena size calibration','modal'));

UD.calibration_square_h = calibration_square_h;
handles.UD = UD;
guidata(hObject,handles);


% --- Executes on button press in pixels_mm_toggle.
function pixels_mm_toggle_Callback(hObject, eventdata, handles)



function enter_scale_edit_Callback(hObject, eventdata, handles)
% hObject    handle to enter_scale_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of enter_scale_edit as text
%        str2double(get(hObject,'String')) returns contents of enter_scale_edit as a double


% --- Executes during object creation, after setting all properties.
function enter_scale_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to enter_scale_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in apply_sf_button.
function apply_sf_button_Callback(hObject, eventdata, handles)

UD = handles.UD;

% Get the value the user entered
length_in_mm = str2num(handles.enter_scale_edit.String);

if isempty(length_in_mm)
    handles.enter_scale_edit.String = '';
    % should also deal with other 
    return
end

% Get the size of the rectangle
pos = getPosition(UD.calibration_square_h);
length_in_pixels = pos(3); % also equal to pos 4

% Calcualte the ratio
pixels_per_mm = length_in_pixels/length_in_mm;

% Enter the value in the relevant box
handles.scale_Factor_text.String = [num2str(pixels_per_mm, '%.2f') ' PIXELS PER mm'];
handles.scale_Factor_text.ForegroundColor = 'r';

% Close the ROI
delete(UD.calibration_square_h)

% Lock the scale factor edit and also the define box
handles.enter_scale_edit.Enable = 'off'; 
handles.apply_sf_button.Enable = 'off';

% enable the units raio buttons
handles.mm_radiobutton.Enable = 'on';
handles.pixels_radiobutton.Enable = 'on';


% and most important of all
UD.pixels_per_mm = pixels_per_mm;
% Required for compatibility with the zone definition function
handles.pixels_per_mm = pixels_per_mm;
handles.UD = UD;

% enable all the relevant controls
handles.define_scale_button.Enable = 'on';

handles.save_zone_button.Enable = 'on';
handles.duplicate_zone_button.Enable = 'on';
handles.rename_zone_button.Enable = 'on';
handles.delete_zone_button.Enable = 'on';
handles.zone_listbox.Enable = 'on';
handles.zone_type_menu.Enable = 'on';
handles.new_zone_button.Enable = 'on';
     
% Set the display to mm
handles.mm_radiobutton.Value = 1;
toggle_pixels_mm_during_arena_definition(handles)




guidata(hObject,handles);
toggle_pixels_mm_during_arena_definition(handles);
% required to update units after new scale factor definition
zone_listbox_Callback(hObject, eventdata, handles); 

return


% --- Executes on button press in pixels_radiobutton.
function pixels_radiobutton_Callback(hObject, eventdata, handles)
toggle_pixels_mm_during_arena_definition(handles)

function mm_radiobutton_Callback(hObject, eventdata, handles)
toggle_pixels_mm_during_arena_definition(handles)


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



function current_time_edit_Callback(hObject, eventdata, handles)

framestr = get(handles.current_frame_edit,'String');
frametimestr = get(handles.current_time_edit,'String');

ok = check_frametime_string(frametimestr,0,handles.UD.Duration);
if ~ok
    errordlg(['Time value valid or out of movie range'],'frame range','modal');
    handles.current_time_edit.String = num2str(str2num(framestr)*handles.UD.SR,'%.2f');
    return
end

frametime = str2num(frametimestr);

% find the closest time to this frame
all_times = [1:handles.UD.nframes]*handles.UD.SR;
[~,fn] = min(abs(all_times - frametime));

%but make sure it is not the last 5, which make the reader get stuck
fn = min(fn,handles.UD.nframes-5);
handles.current_frame_edit.String = num2str(fn);

% update the image
update_frame_for_arena_definition(hObject,handles);




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
