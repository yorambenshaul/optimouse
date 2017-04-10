function interpolate_positions_manually(handles)
% interpolate frames within a defined segment
% inherited from correct_fast_transitions
% YBS 10/16

if handles.interpolate_by_path_checkbox.Value
    interpolate_method = 'start and end angles and path';
elseif handles.interpolate_by_line_checkbox.Value    
    interpolate_method = 'simple linear';
else
    return
end
    

% a question dialogue will ask the user to proceed if the number of frames
% is very large
% set to number of frames in half a second
nuf_to_warn = round(0.5/handles.data.SI);

% Get the segment start and ends
% segment start
seg_start = str2num(handles.segment_start_text.String);
if isempty(seg_start)
    errordlg('segment start must be defined')
    return
end
% segment start
seg_end = str2num(handles.segment_end_text.String);
if isempty(seg_end)
    errordlg('segment end must be defined')
    return
end
% check if valid
if ~(seg_end > seg_start+1)
    errordlg('segment end must be at least two frames larger than segment start')
    return
end
% check if not too long
interpolated_length = seg_end - seg_start -1;
if interpolated_length > nuf_to_warn
    answer = questdlg([num2str(interpolated_length) ' frames will be interpolated (it is a lot). Continue?'],'interpolate frames','cancel','continue','cancel');
    if strcmp(answer,'cancel')
        return
    end
end

% Get position file
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
pD = load(position_file);

switch interpolate_method    
    case 'start and end angles and path'
        % get the starting position and angle
        start_class = handles.frame_class(seg_start);
        n_methods = length(pD.detection_methods);
        if start_class <= n_methods
            start_body_position = pD.position_results(start_class).mouseCOM(seg_start,:);
            start_nose_position = pD.position_results(start_class).nosePOS(seg_start,:);
            start_angle         = pD.position_results(start_class).mouse_angle(seg_start);
        elseif start_class == 10 % user defined
            start_body_position = handles.user_defined_mouseCOM(seg_start,:);
            start_nose_position = handles.user_defined_nosePOS(seg_start,:);
            start_angle         = handles.user_defined_mouse_angle(seg_start);
        elseif start_class == 12 % interpolated
            start_body_position = handles.interpolated_body_position(seg_start,:);
            start_nose_position = handles.interpolated_nose_position(seg_start,:);
            start_angle         = handles.interpolated_mouse_angle(seg_start);
        else
            errordlg('Segment start does not have a valid position')
            return
        end
        if isnan(start_nose_position(1))
            errordlg('Segment start does not have a valid position')
            return
        end
        
        % get the end position and angle
        end_class = handles.frame_class(seg_end);
        n_methods = length(pD.detection_methods);
        if end_class <= n_methods
            end_body_position = pD.position_results(end_class).mouseCOM(seg_end,:);
            end_nose_position = pD.position_results(end_class).nosePOS(seg_end,:);
            end_angle         = pD.position_results(end_class).mouse_angle(seg_end);
        elseif end_class == 10 % user defined
            end_body_position = handles.user_defined_mouseCOM(seg_end,:);
            end_nose_position  = handles.user_defined_nosePOS(seg_end,:);
            end_angle          = handles.user_defined_mouse_angle(seg_end);
        elseif end_class == 12 % interpolated
            end_body_position = handles.interpolated_body_position(seg_end,:);
            end_nose_position  = handles.interpolated_nose_position(seg_end,:);
            end_angle         = handles.interpolated_mouse_angle(seg_end);
        else
            errordlg('Segment end does not have a valid position')
            return
        end
        if isnan(end_nose_position(1))
            errordlg('Segment end does not have a valid position')
            return
        end
        
        % get values for the start and end
        % Start and end angles, unwrap if necessary
        orig_Angles    = [start_angle end_angle];
        R = deg2rad(orig_Angles); % convert to rad
        UR    = unwrap(R); % unwrap
        Angles    = rad2deg(UR); % back to degree
        % Lengths
        % start length
        sD = abs([start_nose_position - start_body_position]);
        start_length = sqrt([sD(1).^2 + sD(2).^2]);
        % end length
        eD = abs([end_nose_position - end_body_position]);
        end_length = sqrt([eD(1).^2 + eD(2).^2 ]);
        
        
        
        % Get positions for all frames in between
        % We first see if there is a body center with the current method - this is
        % the best
        % if not, we look to see if other settings have a center
        % if not, we will have to interpolate
        seg_cen = [seg_start+1:seg_end-1]; % frames between start and end
        % run over each frame
        for i = 1:length(seg_cen)
            % get class of this frame
            this_class = handles.frame_class(seg_cen(i));
            if this_class <= n_methods
                seg_body_position(i,:) = pD.position_results(this_class).mouseCOM(seg_cen(i),:);
            elseif this_class == 10 % user defined
                seg_body_position(i,:) = handles.user_defined_mouseCOM(seg_cen(i),:);
            elseif this_class == 12 % interpolated
                seg_body_position(i,:) = handles.interpolated_body_position(seg_cen(i),:);
            elseif this_class == 11 % excluded
                seg_body_position(i,:) = [NaN NaN];
            end
            % If the position is NAN, and this can only be if the acive method is a
            % NAN, we will check if other methods are not NANS...
            if isnan(seg_body_position(i,1))
                for mi = 1:length(n_methods)
                    if ~isnan(pD.position_results(mi).mouseCOM(seg_cen(i),1) )
                        seg_body_position(i,:) = pD.position_results(mi).mouseCOM(seg_cen(i),:);
                        break
                    end
                end
            end
        end
        
        
        % Interpolate values for angles, lengths, and body centers in the middle of
        % the segments
        %(the latter, only for the case that are not defined)
        rel_inds = [seg_start:seg_end];
        ninds = length(rel_inds);
        % interpolate lengths
        interp_lengths = linspace(start_length,end_length,ninds);
        % interpolate angles - and unwrap them
        interp_angles  = linspace(Angles(1),Angles(2),ninds);
        R = deg2rad(interp_angles); % convert to rad
        UR    = unwrap(R); % unwrap
        interp_angles    = rad2deg(UR); % back to degree
        % interpolate body centers, only if we did not find valid ones
        interp_body_positions(:,1) = linspace(start_body_position(1),end_body_position(1),ninds) ;
        interp_body_positions(:,2) = linspace(start_body_position(2),end_body_position(2),ninds) ;
        % remove the segment beginning and ends from these interpolated positions
        interp_lengths = interp_lengths(2:end-1);
        interp_angles  = interp_angles(2:end-1);
        interp_body_positions = interp_body_positions(2:end-1,:);
        
        
        % interpolate the positions, based on lengths, angles, and body center
        % positions
        interpolated_frames = rel_inds(2:end-1); % interpolated inds
        for i = 1:interpolated_length
            if ~isnan(seg_body_position(i,1))
                these_interpolated_body_positions(i,1) = seg_body_position(i,1) ;
                these_interpolated_body_positions(i,2) = seg_body_position(i,2);
            else % if we did not find a valid body center
                these_interpolated_body_positions(i,1) = interp_body_positions(i,1) ;
                these_interpolated_body_positions(i,2) = interp_body_positions(i,2);
            end
            % get X and Y coordinates
            these_interpolated_nose_positions(i,1) = these_interpolated_body_positions(i,1) + cosd(interp_angles(i)) * interp_lengths(i);
            these_interpolated_nose_positions(i,2) = these_interpolated_body_positions(i,2) - sind(interp_angles(i)) * interp_lengths(i);
        end
        
        % derive the mouse angle (this is redundant, but does not seem, harmful)
        these_interpolated_mouse_angles = atan2d(these_interpolated_body_positions(:,2)-these_interpolated_nose_positions(:,2),these_interpolated_nose_positions(:,1)-these_interpolated_body_positions(:,1));
        these_interpolated_mouse_angles(these_interpolated_mouse_angles<0) = these_interpolated_mouse_angles(these_interpolated_mouse_angles<0) + 360;
        
        
    case 'simple linear'
        
        % interpolate the positions
        start_class = handles.frame_class(seg_start);
        n_methods = length(pD.detection_methods);
        if start_class <= n_methods
            start_body_position = pD.position_results(start_class).mouseCOM(seg_start,:);
            start_nose_position = pD.position_results(start_class).nosePOS(seg_start,:);
        elseif start_class == 10 % user defined
            start_body_position = handles.user_defined_mouseCOM(seg_start,:);
            start_nose_position  = handles.user_defined_nosePOS(seg_start,:);
        elseif start_class == 12 % interpolated
            start_body_position = handles.interpolated_body_position(seg_start,:);
            start_nose_position  = handles.interpolated_nose_position(seg_start,:);
        else
            errordlg('no position defined for segment start')
            return
        end
        if isnan(start_nose_position(1))
            errordlg('no valid position defined for segment start')
            return
        end
        
        
        end_class = handles.frame_class(seg_end);
        n_methods = length(pD.detection_methods);
        if end_class <= n_methods
            end_body_position = pD.position_results(end_class).mouseCOM(seg_end,:);
            end_nose_position = pD.position_results(end_class).nosePOS(seg_end,:);
        elseif end_class == 10 % user defined
            end_body_position = handles.user_defined_mouseCOM(seg_end,:);
            end_nose_position  = handles.user_defined_nosePOS(seg_end,:);
        elseif end_class == 12 % interpolated
            end_body_position = handles.interpolated_body_position(seg_end,:);
            end_nose_position  = handles.interpolated_nose_position(seg_end,:);
        else
            errordlg('no position defined for segment end')
            return
        end
        if isnan(end_nose_position(1))
            errordlg('no valid position defined for segment end')
            return
        end
        
        % interpolate
        rel_inds = [seg_start:seg_end];
        these_interpolated_body_positions(:,1) = linspace(start_body_position(1),end_body_position(1),length(rel_inds)) ;
        these_interpolated_body_positions(:,2) = linspace(start_body_position(2),end_body_position(2),length(rel_inds)) ;
        these_interpolated_nose_positions(:,1) = linspace(start_nose_position(1),end_nose_position(1),length(rel_inds)) ;
        these_interpolated_nose_positions(:,2) = linspace(start_nose_position(2),end_nose_position(2),length(rel_inds)) ;
        
        % we do not need the margins, that is, the anchor frames
        these_interpolated_body_positions = these_interpolated_body_positions(2:end-1,:);
        these_interpolated_nose_positions = these_interpolated_nose_positions(2:end-1,:);
        
        % derive the mouse angle
        these_interpolated_mouse_angles = atan2d(these_interpolated_body_positions(:,2)-these_interpolated_nose_positions(:,2),these_interpolated_nose_positions(:,1)-these_interpolated_body_positions(:,1));
        these_interpolated_mouse_angles(these_interpolated_mouse_angles<0) = these_interpolated_mouse_angles(these_interpolated_mouse_angles<0) + 360;
        
        interpolated_frames = rel_inds(2:end-1);
end

% get original values
interpolated_nose_position = handles.interpolated_nose_position;
interpolated_body_position = handles.interpolated_body_position;
interpolated_mouse_angle   = handles.interpolated_mouse_angle;
frame_class = handles.frame_class;

% update values
interpolated_nose_position(interpolated_frames,:) = these_interpolated_nose_positions;
interpolated_body_position(interpolated_frames,:) = these_interpolated_body_positions;
interpolated_mouse_angle(interpolated_frames) = these_interpolated_mouse_angles;
frame_class(interpolated_frames) = 12;

% apply to handle structure
handles.interpolated_nose_position = interpolated_nose_position;
handles.interpolated_body_position = interpolated_body_position;
handles.interpolated_mouse_angle   = interpolated_mouse_angle;
handles.frame_class = frame_class;

% reset the segment start and end edits
handles.segment_start_text.String = '';
handles.segment_end_text.String = '';

% update the image display
guidata(handles.figure1,handles);
replay_calculated_positions_mm(handles.figure1,handles,2);
% updadte the dot display
guidata(handles.figure1,handles);
update_position_histograms_mm(handles);


% provide notice (only if we did not already warn and had the user consent)
n = length(interpolated_frames);
if n < nuf_to_warn
    if n == 1
        msgbox('Position interpolated for 1 frame','FRAME INTERPOLATION')
    else
        msgbox(['Position interpolated for ' num2str(n) ' frames'],'FRAME INTERPOLATION')
    end
end
