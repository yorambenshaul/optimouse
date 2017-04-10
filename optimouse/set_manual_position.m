function set_manual_position(handles)
% Set a manual position to a frame in review positions GUI
% YBS 9/16

% if there is no manual position defined
if ~sum(handles.frame_class == 10)
    msgstr{1} = 'Note: ';
    msgstr{2} = 'The first endpoint defines the body center (shown as a square after definition)';
    msgstr{3} = 'The second endpoint defines the nose (shown as a circle after definition)';    
    msgbox(msgstr,'Define Manual Position','Modal')    
end

% get current frame
frc = str2num(handles.current_frame_edit.String);
% get its current class
frc_class = handles.frame_class(frc);
% See if it has a valid manual position
has_manual = ~isnan(handles.user_defined_mouseCOM(frc,1));
% if it does have a prvious menual position, but it is not active, then
% active it, and thta's all.
if has_manual && ~(frc_class == 10)    
    set_frame_as_class(handles,10)
    return
end

% Otherwise,if it does not have a manual position, or if it is already
% active, define a new one...

LinE =findobj('Tag','userline');
if ~isempty(LinE)
    delete(LinE)
end

% because there can easily be errors with ROI definitions, I use a
% try-catch
try
    % define a line and get its location
    h = imline(handles.original_video_axes);
    set(h,'Tag','userline')

    
    setColor(h,[1 0.843 0]);
    position = wait(h);
    delete(h);
    
    user_defined_mouseCOM = handles.user_defined_mouseCOM;
    user_defined_nosePOS  = handles.user_defined_nosePOS;
    frame_class = handles.frame_class;
    
    
    user_defined_nosePOS(frc,:)  = position(2,:);
    user_defined_mouseCOM(frc,:) = position(1,:);
    
    mouse_angle = atan2d(user_defined_mouseCOM(frc,2)-user_defined_nosePOS(frc,2),user_defined_nosePOS(frc,1)-user_defined_mouseCOM(frc,1));
    if mouse_angle < 0
        mouse_angle = mouse_angle + 360;
    end
    
    handles.user_defined_mouse_angle(frc)  = mouse_angle;
    handles.user_defined_nosePOS  = user_defined_nosePOS;
    handles.user_defined_mouseCOM = user_defined_mouseCOM;
    
    
    % 10 is reserved for user defined frame
    frame_class(frc) = 10;
    
    handles.frame_class = frame_class;
    % we don't draw it here, we only set it and then call the replay function
    replay_calculated_positions_mm(handles.figure1,handles,2);
    update_position_histograms_mm(handles)
catch    
    LinE =findobj('Tag','userline');
    if ~isempty(LinE)
        delete(LinE)
    end
end

return