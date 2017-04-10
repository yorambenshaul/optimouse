function correct_fast_transitions(handles)
% Correct frames based on fast transients in the angle
% The algorithm is the same as used in
% interpolate_positions_manually(handles)
% with    interpolate_method = 'start and end angles and path';
% YBS 10/16

% get the data - angle change data
y_data = handles.scatter_plot_y_data;


% get the threshold
bad_thresh   = str2num(handles.bad_thresh_edit.String);
good_thresh  = str2num(handles.good_thresh_edit.String);


% build a vector with good and bad frame tags
% good is 2, bad is 1. Neither is zero. 
frame_cat = zeros(size(y_data));
frame_cat(y_data >= bad_thresh)  = 1;
frame_cat(y_data < good_thresh)  = 2;
cat_str = num2str(frame_cat')';

% these are the possible patterns which are searched for in the data
% for example:
% the first pattern looks for 3 good frames, two fast transitions, and
% another 3 good frames. This corresponds to one position flip
pattern(1).name = '22211222';
pattern(2).name = '222121222';
pattern(3).name = '222212212222';
pattern(4).name = '222221222122222';
pattern(5).name = '222222122221222222';

% select the range of patterns to use based on the list
n_patterns = handles.max_transient_length_menu.Value;
pattern = pattern(1:n_patterns);

for pi = 1:length(pattern)
    pattern(pi).seg  = find(pattern(pi).name == '1'); % find the positions which are bad frames
    pattern(pi).inds = regexp(cat_str,pattern(pi).name); 
end

% uncomment the regions below for error checking
% pi is for pattern inds
% si is for segment inds
% % for pi = 1:length(pattern)
% %     for si = 1:length(pattern(pi).inds)
% %         cat_str([pattern(pi).inds(si):pattern(1).inds(si)+length(pattern(pi).name)-1])
% %           y_data([pattern(pi).inds(si):pattern(1).inds(si)+length(pattern(pi).name)-1])
% %     end
% % end
    


% Get position file
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
pD = load(position_file);

% get current position and angle values
interpolated_nose_position = handles.interpolated_nose_position;
interpolated_body_position = handles.interpolated_body_position;
interpolated_mouse_angle   = handles.interpolated_mouse_angle;
frame_class = handles.frame_class;

% initialize variables
all_interpolated_frames = [];
n_interpolated_segment  =  0;


for pi = 1:length(pattern) % over patterns
    for si = 1:length(pattern(pi).inds) % over segments found for each pattern
        
        % temporary positions and angles for this segment
        interp_body_positions = [];
        these_interpolated_body_positions = [];
        these_interpolated_nose_positions = [];
        
        % we need anchors flanking the actual segments
        % to exaplain the -2 and -1:
        % here,'22211222' we want the segment anchors to be in positions 3
        % and 5 (according to: 12345678).        
        % for this pattern seg(1) = 4, so this starts in the third position
        % (x+4-2)
        % seg(2) = 5, so the end position will be
        % x+4, which is the 5th position. 
        seg_start = pattern(pi).inds(si)+pattern(pi).seg(1)-2; % the -2 results in taking one sample before the start of the segment
        seg_end   = pattern(pi).inds(si)+pattern(pi).seg(end)-1;
        
        % uncomment to see that segments make sense
        % y_data([seg_start:seg_end]);
        
        
        % flag will be set to 0 if the anchor points are wrong
        segment_OK = 1;
        
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
            segment_OK = 0;
        end
        if isnan(start_nose_position(1))
            segment_OK = 0;
        end
        
        % get the end position and angle
        end_class = handles.frame_class(seg_end);
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
            segment_OK = 0;
        end
        if isnan(end_nose_position(1))
            segment_OK = 0;
        end
        
        if segment_OK
            % get values for the start and end
            % Start and end angles, unwrap if necessary
            orig_Angles    = [start_angle end_angle];
            R = deg2rad(orig_Angles); % convert to rad
            UR    = unwrap(R);        % unwrap
            Angles    = rad2deg(UR);  % back to degree
            % Lengths
            % start length
            sD = abs([start_nose_position - start_body_position]);
            start_length = sqrt([sD(1).^2 + sD(2).^2]);
            % end length
            eD = abs([end_nose_position - end_body_position]);
            end_length = sqrt([eD(1).^2 + eD(2).^2 ]);
            
            % Get positions for all frames in between
            % We first see if there is a body center with the current method - this is
            % the best.
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
            interp_lengths        = interp_lengths(2:end-1);
            interp_angles         = interp_angles(2:end-1);
            interp_body_positions = interp_body_positions(2:end-1,:);
            
            % interpolate the positions, based on lengths, angles, and body center
            % positions
            %interpolated_length = seg_end - seg_start -1;
            interpolated_frames = rel_inds(2:end-1); % interpolated inds
            for i = 1:length(interpolated_frames)
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
            
            % update values
            interpolated_nose_position(interpolated_frames,:) = these_interpolated_nose_positions;
            interpolated_body_position(interpolated_frames,:) = these_interpolated_body_positions;
            interpolated_mouse_angle(interpolated_frames)     = these_interpolated_mouse_angles;
            frame_class(interpolated_frames) = 12;
            
            all_interpolated_frames = union(all_interpolated_frames,interpolated_frames);
            n_interpolated_segment = n_interpolated_segment + 1;
            
        end % of if segment_OK
    end
end


% provide notice (only if we did not already warn and had the user consent)
n = length(all_interpolated_frames);
queststr{1} = ['Found ' num2str(n_interpolated_segment) ' segments.'];
queststr{2} = ['Total number of frames that will be interpolated:   ' num2str(n)];
queststr{3} = ['Apply interpolation?'];

ButtonName = questdlg(queststr,'Correct detection','Continue', 'Cancel', 'Cancel');
if strcmp(ButtonName,'Cancel')
    return
else
    % apply to handle structure
    handles.interpolated_nose_position = interpolated_nose_position;
    handles.interpolated_body_position = interpolated_body_position;
    handles.interpolated_mouse_angle   = interpolated_mouse_angle;
    handles.frame_class = frame_class;
    % update the image display
    guidata(handles.figure1,handles);
    replay_calculated_positions_mm(handles.figure1,handles,2);
    % update the dot display
    guidata(handles.figure1,handles);
    update_position_histograms_mm(handles);
end

return

