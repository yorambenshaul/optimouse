function replay_calculated_positions_mm(hObject,handles,single_frame)
% Replay movie for various functions of the review positions GUI.
% Used for playing a movie as well as single frames
% If single_frame == 0, a movie will be shown.
% If single_frame == 2, the current frame will be refreshed
% YBS 9/16

% see if there is another rect object, and if so, delete it
prev_rect = findobj('tag','zoom_rect');
if ~isempty(prev_rect)
    delete(prev_rect)
end


% Get which frames to stop on (if any)
if handles.stop_playback_checkbox.Value
    stop_frames = find(handles.frame_subset_to_show);
else
    stop_frames = [];
end
    

    

method_col = handles.method_col;


% get current frame classes
frame_class = handles.frame_class;


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
seconds_per_frame = diff(FrameInfo(1:2,3));

pixels_per_mm = arena_data.pixels_per_mm;
pD = load(position_file);

method_names = handles.method_names;


%% Get parameters from GUI
% Get skip factor from GUI
if ~single_frame
    skip_factor = str2num(handles.down_sample_factor_edit.String);
else
    skip_factor = 1;
end

% Get a pause time if such exists
pause_time = str2num(handles.pause_between_frames_edit.String);

% Get playback direction from GUI
play_dir = handles.play_dir;




%% Set image display
psz = length(MedianImage)/50;
psz2 = psz/2;
psz4 = psz/4;
Ylimits = [1-psz size(MedianImage,1)+psz];
Xlimits = [1-psz size(MedianImage,2)+psz];

axes(handles.original_video_axes);
axis tight
colormap gray
axis equal;
hold on
set(gca,'YLim',Ylimits,'XLim',Xlimits);
ylabel('cm')

% Show axes in cm  (convert from pixels)
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


%% Get last frame and next frame to start at
frc =  str2num(handles.current_frame_edit.String);
if frc < 1 || frc > TotalFrames
    return
end

% consider the skip factor and start at the next frame -
% however, if the single_frame parameter is set to 2, there is no
% advance but only replotting of the current frame
if ~(single_frame == 2)
    frc = frc + play_dir*skip_factor;
end

% initilize as a non existing number
loaded_file_number = 0;

n_methods = length(pD.detection_methods);

%% Start running over all frames, as long as we are not beyond first or last frame
while frc <= TotalFrames &&  frc >= 1
    
    % Get the inforamtion about the tmp mat file containing this frame
    rel_file_num = FrameInfo(frc,1);
    % if file not loaded, then load it
    if ~(rel_file_num == loaded_file_number)
        load([handles.video_dir_text.String filesep base_name filesep base_name '_' num2str(rel_file_num) '.mat']);
        loaded_file_number = rel_file_num;
    end
    rel_frame_in_file = FrameInfo(frc,2);
        
    % Show the frame
    cla(handles.original_video_axes);
    imagesc(ROI_tmp_frames(:,:,rel_frame_in_file));
        
    % if we show all methods
    if  handles.show_selected_methods_radiobutton.Value % This is a bad name left over, but it means showing all methods
        for dmi = 1:n_methods
            if ~isnan(pD.position_results(dmi).nosePOS(frc,1))
                % Highlight the current method
                if frame_class(frc) == dmi
                    rectangle('Curvature', [1 1], 'Position', [pD.position_results(dmi).nosePOS(frc,1)-psz2, pD.position_results(dmi).nosePOS(frc,2)-psz2 psz psz],'edgecolor',method_col(dmi,:),'facecolor',method_col(dmi,:));
                    % and draw a line
                    lh = line([pD.position_results(dmi).mouseCOM(frc,1) pD.position_results(dmi).nosePOS(frc,1)],[pD.position_results(dmi).mouseCOM(frc,2) pD.position_results(dmi).nosePOS(frc,2)],'color',method_col(dmi,:));
                else
                    rectangle('Curvature', [1 1], 'Position', [pD.position_results(dmi).nosePOS(frc,1)-psz4, pD.position_results(dmi).nosePOS(frc,2)-psz4 psz2 psz2],'edgecolor',method_col(dmi,:),'facecolor',method_col(dmi,:));
                end
            end
            if frame_class(frc) == dmi
                if ~isnan(pD.position_results(dmi).mouseCOM(frc,1))
                    % Show the body center from the current method
                    rectangle('Curvature', [0 0], 'Position', [pD.position_results(dmi).mouseCOM(frc,1)-psz2, pD.position_results(dmi).mouseCOM(frc,2)-psz2 psz psz],'edgecolor',method_col(dmi,:),'facecolor',method_col(dmi,:));
                end
            end
            if ~isnan(handles.user_defined_nosePOS(frc,1))
                if frame_class(frc) == 10 % if this is a user defined class
                    rectangle('Curvature', [1 1], 'Position', [handles.user_defined_nosePOS(frc,1)-psz2, handles.user_defined_nosePOS(frc,2)-psz2 psz psz],'edgecolor',method_col(10,:),'facecolor',method_col(10,:));
                    rectangle('Curvature', [0 0], 'Position', [handles.user_defined_mouseCOM(frc,1)-psz2, handles.user_defined_mouseCOM(frc,2)-psz2 psz psz],'edgecolor',method_col(10,:),'facecolor',method_col(10,:));
                    % and draw a line
                    lh = line([handles.user_defined_mouseCOM(frc,1) handles.user_defined_nosePOS(frc,1)],[handles.user_defined_mouseCOM(frc,2) handles.user_defined_nosePOS(frc,2)],'color',method_col(10,:));
                else
                    rectangle('Curvature', [1 1], 'Position', [handles.user_defined_nosePOS(frc,1)-psz4, handles.user_defined_nosePOS(frc,2)-psz4 psz2 psz2],'edgecolor',method_col(10,:),'facecolor',method_col(10,:));
                end
            end
            if ~isnan(handles.interpolated_body_position(frc,1))
                if frame_class(frc) == 12 % if this is a user defined class
                    rectangle('Curvature', [1 1], 'Position', [handles.interpolated_nose_position(frc,1)-psz2, handles.interpolated_nose_position(frc,2)-psz2 psz psz],'edgecolor',method_col(12,:),'facecolor',method_col(12,:));
                    rectangle('Curvature', [0 0], 'Position', [handles.interpolated_body_position(frc,1)-psz2, handles.interpolated_body_position(frc,2)-psz2 psz psz],'edgecolor',method_col(12,:),'facecolor',method_col(12,:));
                    % and draw a line
                    lh = line([handles.interpolated_body_position(frc,1) handles.interpolated_nose_position(frc,1)],[handles.interpolated_body_position(frc,2) handles.interpolated_nose_position(frc,2)],'color',method_col(12,:));
                else
                    rectangle('Curvature', [1 1], 'Position', [handles.interpolated_nose_position(frc,1)-psz4, handles.interpolated_nose_position(frc,2)-psz4 psz2 psz2],'edgecolor',method_col(12,:),'facecolor',method_col(12,:));
                end
            end
        end
        % Show only the currently selected method
    elseif  handles.show_applied_method_radiobutton.Value
        for dmi = 1:n_methods
            if frame_class(frc) == dmi
                if ~isnan(pD.position_results(dmi).nosePOS(frc,1))
                    % Highlight the current method
                    rectangle('Curvature', [1 1], 'Position', [pD.position_results(dmi).nosePOS(frc,1)-psz2, pD.position_results(dmi).nosePOS(frc,2)-psz2 psz psz],'edgecolor',method_col(dmi,:),'facecolor',method_col(dmi,:));
                end
                if ~isnan(pD.position_results(dmi).mouseCOM(frc,1))
                    % Show the body center from the current method
                    rectangle('Curvature', [0 0], 'Position', [pD.position_results(dmi).mouseCOM(frc,1)-psz2, pD.position_results(dmi).mouseCOM(frc,2)-psz2 psz psz],'edgecolor',method_col(dmi,:),'facecolor',method_col(dmi,:));
                    % and draw a line
                    lh = line([pD.position_results(dmi).mouseCOM(frc,1) pD.position_results(dmi).nosePOS(frc,1)],[pD.position_results(dmi).mouseCOM(frc,2) pD.position_results(dmi).nosePOS(frc,2)],'color',method_col(dmi,:));
                end
            end
            if frame_class(frc) == 10 % if this is a user defined class
                rectangle('Curvature', [1 1], 'Position', [handles.user_defined_nosePOS(frc,1)-psz2, handles.user_defined_nosePOS(frc,2)-psz2 psz psz],'edgecolor',method_col(10,:),'facecolor',method_col(10,:));
                rectangle('Curvature', [0 0], 'Position', [handles.user_defined_mouseCOM(frc,1)-psz2, handles.user_defined_mouseCOM(frc,2)-psz2 psz psz],'edgecolor',method_col(10,:),'facecolor',method_col(10,:));
                % and draw a line
                lh = line([handles.user_defined_mouseCOM(frc,1) handles.user_defined_nosePOS(frc,1)],[handles.user_defined_mouseCOM(frc,2) handles.user_defined_nosePOS(frc,2)],'color',method_col(10,:));
            end
            if frame_class(frc) == 12 % if this is the interoplated class
                rectangle('Curvature', [1 1], 'Position', [handles.interpolated_nose_position(frc,1)-psz2, handles.interpolated_nose_position(frc,2)-psz2 psz psz],'edgecolor',method_col(12,:),'facecolor',method_col(12,:));
                rectangle('Curvature', [0 0], 'Position', [handles.interpolated_body_position(frc,1)-psz2, handles.interpolated_body_position(frc,2)-psz2 psz psz],'edgecolor',method_col(12,:),'facecolor',method_col(12,:));
                % and draw a line
                lh = line([handles.interpolated_body_position(frc,1) handles.interpolated_nose_position(frc,1)],[handles.interpolated_body_position(frc,2) handles.interpolated_nose_position(frc,2)],'color',method_col(12,:));
            end
        end
    end
    
    if ~isnan(handles.interpolated_nose_position(frc,1))
        handles.setframeas_interpolated_button.Enable = 'on';
        handles.setframeas_interpolated_button.Visible = 'on';
    else
        handles.setframeas_interpolated_button.Enable = 'off';
        handles.setframeas_interpolated_button.Visible = 'off';
    end
    
    % This should be a handle, but rarely, probably if there are too many
    % graphic deamdsn, it can get stuck here, so I check the condition
    if ishandle(handles.highlighted_frame)
        set(handles.highlighted_frame,'XData',handles.scatter_plot_x_data(frc), 'YData',handles.scatter_plot_y_data(frc));
    else
        handles.highlighted_frame = plot(handles.scatter_plot_x_data(frc),handles.scatter_plot_y_data(frc),'kd','linewidth',2,'markersize',6);
    end
        
    % This is important:
    drawnow
    
    % update the title string
    info_str{1} = ['Frame ' num2str(frc) ' of ' num2str(size(FrameInfo,1))];
    info_str{2} = [num2str(FrameInfo(frc,3),'%.2f') ' s of '  num2str(FrameInfo(end,3),'%.2f')];
    handles.arena_files_info_text.String = info_str;
    %handles.arena_files_info_text.BackgroundColor = method_col(frame_class(frc),:);
    handles.method_color_indicator_text.BackgroundColor = method_col(frame_class(frc),:);
    % update annotation box
    annotated_events = handles.annotations;
    if ~isempty(annotated_events)
        event_names = fieldnames(annotated_events);
        if ~isempty(event_names)
            for aei = 1:length(event_names)
                %eval(
                eval(['is_event(aei) = annotated_events.' event_names{aei} '(frc);']);
            end
            frame_annotation = event_names(logical(is_event));
            if isempty(frame_annotation)
                frame_annotation{1} = 'no user events';
            else
                frame_annotation = [num2str(length(frame_annotation)) ' user defined events:' ; frame_annotation];
            end
        else
            frame_annotation{1} = 'no user defined events';
        end
        handles.annotation_text.String = frame_annotation;
        if length(frame_annotation) > 1
            handles.annotation_text.ForegroundColor = 'r';
        else
            handles.annotation_text.ForegroundColor = 'k';
        end
    end
    
    % Also stop if we are in a single frame mode
    if single_frame
        handles.current_frame_edit.String = num2str(frc);
        frc = frc + play_dir;
        guidata(hObject,handles);
        break
    end
    
    % If the play/quit button was pressed
    %if play_dir == 1
    handles = guidata(hObject);
    if ~handles.do_play
    % if ~handles.play_pause_toggle.Value
        % upate current position slider and text
        handles.frame_select_slider.Value = frc;
        handles.current_frame_edit.String = num2str(frc);
        handles.current_time_edit.String = num2str(frc*handles.data.SI,'%.2f');    
        
        guidata(hObject,handles);
        return
    end
          
    % get the next ...
    if ismember(frc,stop_frames)
        % if  handles.scatter_plot_y_data(frc) > stop_thresh
        handles.frame_select_slider.Value = frc;
        handles.current_frame_edit.String = num2str(frc);
        handles.current_time_edit.String = num2str(frc*handles.data.SI,'%.2f');
        handles.play_pause_toggle.String = 'PLAY';
        handles.PLAYBACK_BUTTON.String = 'YALP';
        handles.play_pause_toggle.Enable = 'on';
        handles.PLAYBACK_BUTTON.Enable = 'on';
        guidata(hObject,handles);
        return
    end
    
    % Pause if the pause time is larger than zero
    % (The GUI does not allow setting a value larger than 1)
    if pause_time > 0 
        pause(pause_time);
    end
    
    % update the counter to the next frame (considering the step size)
    frc = frc + play_dir*skip_factor;
    
end

% If we finished showing the whole video, reset the play/quit button to
% play
if frc >= TotalFrames ||  frc <= 1
    handles.play_pause_toggle.String = 'PLAY';   
    handles.PLAYBACK_BUTTON.String = 'YALP';
    handles.play_pause_toggle.Enable = 'on';
    handles.PLAYBACK_BUTTON.Enable = 'on';   
    
    % These guys also have to be enabled
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
    
    
    % handles.play_pause_toggle.Value  = 1 - handles.play_pause_toggle.Value;
end



    

% Ignore the last step increment
frc = frc - play_dir*skip_factor;

% update frame edit box.
handles.current_frame_edit.String = num2str(frc);
handles.frame_select_slider.Value = frc;
handles.current_time_edit.String = num2str(frc*handles.data.SI,'%.2f');    


% I actually don't think this is required, but how many things in life
% really are?
guidata(hObject,handles);

return


