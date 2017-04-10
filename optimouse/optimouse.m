function varargout = optimouse(varargin)
% YBS 9/16
% optimouse MATLAB code for optimouse.fig
%      optimouse, by itself, creates a new optimouse or raises the existing
%      singleton*.
%
%      H = optimouse returns the handle to a new optimouse or the handle to
%      the existing singleton*.
%
%      optimouse('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in optimouse.M with the given input arguments.
%
%      optimouse('Property','Value',...) creates a new optimouse or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before optimouse_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to optimouse_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help optimouse

% Last Modified by GUIDE v2.5 11-Oct-2016 10:27:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @optimouse_OpeningFcn, ...
                   'gui_OutputFcn',  @optimouse_OutputFcn, ...
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


% --- Executes just before optimouse is made visible.
function optimouse_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to optimouse (see VARARGIN)

% show the logo
D = load('logo');
axes(handles.logo_axes);
image(flipud(D.logo)); axis equal; axis tight
handles.logo_axes.XTick = [];
handles.logo_axes.YTick = [];

% handles.figure1.Name = 'optimouse';

% Choose default command line output for optimouse
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes optimouse wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = optimouse_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in define_arenas_button.
function define_arenas_button_Callback(hObject, eventdata, handles)
% hObject    handle to define_arenas_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
prepare_arena_data;

% --- Executes on button press in Define_detection_params_button.
function Define_detection_params_button_Callback(hObject, eventdata, handles)
% hObject    handle to Define_detection_params_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
calculate_positions_in_arena_mm

% --- Executes on button press in exclude_bad_frames_button.
function exclude_bad_frames_button_Callback(hObject, eventdata, handles)
% hObject    handle to exclude_bad_frames_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
review_positions_in_arena_mm

% --- Executes on button press in analyze_behavior_button.
function analyze_behavior_button_Callback(hObject, eventdata, handles)
% hObject    handle to analyze_behavior_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
analyze_behavior_mm


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in optimouse_manual_button.
function optimouse_manual_button_Callback(hObject, eventdata, handles)
% hObject    handle to optimouse_manual_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[PATH,~,~] = fileparts(mfilename);
winopen([PATH filesep 'optimouse manual.pdf'])


% --- Executes on button press in close_all_GUIS_button.
function close_all_GUIS_button_Callback(hObject, eventdata, handles)
% hObject    handle to close_all_GUIS_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
