function update_position_histograms_mm(handles)
% based on update_position_histograms but very different since here we plot
% the dots on a 2D plane, rather than as a histogram
% YBS 9/16

% Method colors
method_col = handles.method_col;

% Get position file
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
pD = load(position_file);

FrameInfo = pD.arena_data.FrameInfo;
seconds_per_frame = diff(FrameInfo(1:2,3));


% first checkt he main display menu
contents = cellstr(get(handles.show_menu,'String'));
show_menu_selection = contents{get(handles.show_menu,'Value')};

% this is the default,which we change for particular display options
set(handles.parameter_axes,'YDir','normal');
axis(handles.parameter_axes,'normal');


switch show_menu_selection
    case 'active setting';
        y_data = handles.frame_class;
        n_methods = length(pD.detection_methods);
        % for plotting reasons, change the classes #s
        y_data(y_data == 10) = n_methods + 1; % user defined
        y_data(y_data == 12) = n_methods + 2; % interpolated        
        y_data(y_data == 11) = 0; % excluded
        % for the nan values we need a further complication
        
        % Look which values are nans
        % we do not need to do it for user defined class since they are not
        % Nan by definition. Also, for the excluded class, we do not care
        % if there are NAN values.
        % for each method, we look for the relevant indicies.
        % then we find which of those have a nan value
        % and of those, and then set the value to -1
        for mi = 1:n_methods
            these_inds        = find(handles.frame_class == mi);
            these_inds_nan    = isnan(pD.position_results(mi).nosePOS(these_inds,1));
            y_data(these_inds(these_inds_nan)) = -1;
        end
        
        % x values are frame numbers
        x_data  = 1:length(y_data);
        
    case 'annotated events'                    
        annotated_events = handles.annotations;
        event_names = fieldnames(annotated_events);
        y_data = zeros(1,length(handles.frame_class));                   
        for i = 1:length(event_names)
            eval(['inds{i} = find(annotated_events.' event_names{i} ');']);            
            y_data(inds{i}) = 1;
        end      
        % x values are frame numbers
        x_data  = 1:length(y_data);  
        
    case 'angle change';
        % initiate a vector of body angles. first off,they are all nan
        mouse_angles = nan(1,length(pD.position_results(1).BackGroundMean));
        % find values for each method
        n_methods = length(pD.detection_methods);
        for mi = 1:n_methods
            these_inds = find(handles.frame_class == mi);
            mouse_angles(these_inds) = pD.position_results(mi).mouse_angle(these_inds);
        end
        % find user defined values
        user_defined_inds = find(handles.frame_class == 10);
        mouse_angles(user_defined_inds) = handles.user_defined_mouse_angle(user_defined_inds);
        % find interpolated values
        interpolated_inds = find(handles.frame_class == 12);
        mouse_angles(interpolated_inds) = handles.interpolated_mouse_angle(interpolated_inds);
        
        tmp = abs(diff(mouse_angles));
        tmp = min(tmp,360-tmp);
        y_data =zeros(1,length(mouse_angles));
        y_data(2:end) = mod(tmp,180);
        
        % x values are frame numbers
        x_data  = 1:length(y_data);
    case 'mouse angle';
        % initiate a vector of body angles. first off,they are all nan
        mouse_angles = nan(1,length(pD.position_results(1).BackGroundMean));
        % Find values for each method
        n_methods = length(pD.detection_methods);
        for mi = 1:n_methods
            these_inds = find(handles.frame_class == mi);
            mouse_angles(these_inds) = pD.position_results(mi).mouse_angle(these_inds);
        end
        % Find user defined values
        user_defined_inds = find(handles.frame_class == 10);
        mouse_angles(user_defined_inds) = handles.user_defined_mouse_angle(user_defined_inds);
        % Find interpolated values
        interpolated_inds = find(handles.frame_class == 12);
        mouse_angles(interpolated_inds) = handles.interpolated_mouse_angle(interpolated_inds);        
        y_data =mouse_angles;                
        
        % x values are frame numbers
        x_data  = 1:length(y_data);
    case 'body speed';
        % initiate a vector of body positions
        body_positions = nan(size(pD.position_results(1).mouseCOM));
        
        % now look at the values for each method
        n_methods = length(pD.detection_methods);
        for mi = 1:n_methods
            these_inds = find(handles.frame_class == mi);
            body_positions(these_inds,:) = pD.position_results(mi).mouseCOM(these_inds,:);
        end
        % look at the user defined values
        user_defined_inds = find(handles.frame_class == 10);
        body_positions(user_defined_inds,:) = handles.user_defined_mouseCOM(user_defined_inds,:);
        
        % look at the interpolated values
        interpolated_inds = find(handles.frame_class == 12);
        body_positions(interpolated_inds,:) = handles.interpolated_body_position(interpolated_inds,:);
        
        % Calculate change in mouse center of mass (COM) and nose in each frame
        tmp            = diff(body_positions,1,1);
        y_data         = zeros(1,length(body_positions));
        y_data(2:end)  = sqrt(sum(tmp.^2,2));
        
        % x values are frame numbers
        x_data  = 1:length(y_data);
    case 'nose speed'
        % initiate a vector of body positions
        body_positions = nan(size(pD.position_results(1).mouseCOM));
        nose_positions = nan(size(pD.position_results(1).nosePOS));
        % Find the values for each method        
        n_methods = length(pD.detection_methods);
        for mi = 1:n_methods
            these_inds = find(handles.frame_class == mi);
            body_positions(these_inds,:) = pD.position_results(mi).mouseCOM(these_inds,:);
            nose_positions(these_inds,:) = pD.position_results(mi).nosePOS(these_inds,:);
        end
        % look at the user defined values
        user_defined_inds = find(handles.frame_class == 10);
        body_positions(user_defined_inds,:) = handles.user_defined_mouseCOM(user_defined_inds,:);
        nose_positions(user_defined_inds,:) = handles.user_defined_nosePOS(user_defined_inds,:);
        
        % look at the interpolated values
        interpolated_inds = find(handles.frame_class == 12);
        body_positions(interpolated_inds,:) = handles.interpolated_body_position(interpolated_inds,:);
        nose_positions(interpolated_inds,:) = handles.interpolated_nose_position(interpolated_inds,:);
                
        % Find the position of the nose relative to that of the head
        nose_pos_relative_to_body_pos = [body_positions - nose_positions];
        % this is now the delta x and delta y
        diff_nose_pos_relative_to_body_pos = diff(nose_pos_relative_to_body_pos,1,1);
        % This is the delta distance that the nose did relative to the center in
        % each frame
        diff_nose_to_body_distance = sqrt(sum(diff_nose_pos_relative_to_body_pos.^2,2));
        y_data = zeros(1,length(body_positions));
        y_data(2:end) = diff_nose_to_body_distance;
        % x values are frame numbers
        x_data  = 1:length(y_data);
    case 'nose position'
        % initiate a vector of body positions
        nose_positions = nan(size(pD.position_results(1).nosePOS));
        % now look at the values for each method
        n_methods = length(pD.detection_methods);
        for mi = 1:n_methods
            these_inds = find(handles.frame_class == mi);
            nose_positions(these_inds,:) = pD.position_results(mi).nosePOS(these_inds,:);
        end
        % look at the user defined values
        user_defined_inds = find(handles.frame_class == 10);
        nose_positions(user_defined_inds,:) = handles.user_defined_nosePOS(user_defined_inds,:);
        
        % look at the interpolated values
        interpolated_inds = find(handles.frame_class == 12);
        nose_positions(interpolated_inds,:) = handles.interpolated_nose_position(interpolated_inds,:);
        
        y_data = nose_positions(:,2);
        x_data = nose_positions(:,1);
        set(handles.parameter_axes,'YDir','reverse');       
        axis(handles.parameter_axes,'equal');
    case  'body position'
        % initiate a vector of body positions
        body_positions = nan(size(pD.position_results(1).mouseCOM));
        % now look at the values for each method
        n_methods = length(pD.detection_methods);
        for mi = 1:n_methods
            these_inds = find(handles.frame_class == mi);
            body_positions(these_inds,:) = pD.position_results(mi).mouseCOM(these_inds,:);
        end
        % look at the user defined values
        user_defined_inds = find(handles.frame_class == 10);
        body_positions(user_defined_inds,:) = handles.user_defined_mouseCOM(user_defined_inds,:);
        
        % look at the interpolated values
        interpolated_inds = find(handles.frame_class == 12);
        body_positions(interpolated_inds,:) = handles.interpolated_body_position(interpolated_inds,:);
        
        y_data = body_positions(:,2);
        x_data = body_positions(:,1);
        set(handles.parameter_axes,'YDir','reverse');
        axis(handles.parameter_axes,'equal');
        
    case 'parameter pairs'        
        % get the method to take
        x_method = handles.x_axes_method_menu.Value;
        y_method = handles.y_axes_method_menu.Value;
        
        % Get current parameter from lists
        x_types = cellstr(get(handles.x_axes_parameter_menu,'String')) ;
        x_param  = x_types{get(handles.x_axes_parameter_menu,'Value')};
        
        % Get current parameter from lists
        y_types  = cellstr(get(handles.y_axes_parameter_menu,'String')) ;
        y_param   = y_types{get(handles.y_axes_parameter_menu,'Value')};
        
        switch x_param
            case  'mouse angle';
                x_data = pD.position_results(x_method).mouse_angle;      
            case  'body x';
                x_data = pD.position_results(x_method).mouseCOM(:,1);
            case  'body y';
                x_data = pD.position_results(x_method).mouseCOM(:,2);
            case 'nose x'
                x_data = pD.position_results(x_method).nosePOS(:,1);
            case  'nose y'
                x_data = pD.position_results(x_method).nosePOS(:,2);
            case 'grey threshold'
                x_data = pD.position_results(x_method).GreyThresh;
            case 'trim factor'
                x_data = pD.position_results(x_method).TrimFact;
            case 'mouse area'
                x_data = pD.position_results(x_method).MouseArea;
            case 'mouse length'
                x_data = pD.position_results(x_method).mouse_length;
            case 'mouse perimeter'
                x_data = pD.position_results(x_method).MousePerim;
            case 'thinned mouse perimeter'
                x_data = pD.position_results(x_method).ThinMousePerim;
            case 'perimeter ratio'
                x_data = pD.position_results(x_method).MousePerim./pD.position_results(x_method).ThinMousePerim;
            case  'background intensity (mean)';
                x_data = pD.position_results(x_method).BackGroundMean;
            case 'frame number';
                x_data = 1:length(pD.position_results(x_method).BackGroundMean);
            case 'mouse intensity mean'
                x_data = pD.position_results(x_method).MouseMean;
            case 'mouse intensity var'
                x_data = pD.position_results(x_method).MouseVar;
            case 'mouse intensity range'
                x_data = pD.position_results(x_method).MouseRange;
        end
        
        switch y_param
            case  'mouse angle';
                y_data = pD.position_results(y_method).mouse_angle;                
            case  'body x';
                y_data = pD.position_results(y_method).mouseCOM(:,1);            
            case 'nose x'
                y_data = pD.position_results(y_method).nosePOS(:,1);
            case  'body y';
                y_data = pD.position_results(y_method).mouseCOM(:,2);
                set(handles.parameter_axes,'YDir','reverse');
            case  'nose y'
                y_data = pD.position_results(y_method).nosePOS(:,2);
                set(handles.parameter_axes,'YDir','reverse');
            case 'grey threshold'
                y_data = pD.position_results(y_method).GreyThresh;
            case 'trim factor'
                y_data = pD.position_results(y_method).TrimFact;
            case 'mouse area'
                y_data = pD.position_results(y_method).MouseArea;
            case 'mouse length'
                y_data = pD.position_results(y_method).mouse_length;
            case 'mouse perimeter'
                y_data = pD.position_results(y_method).MousePerim;
            case 'thinned mouse perimeter'
                y_data = pD.position_results(y_method).ThinMousePerim;
            case 'perimeter ratio'
                y_data = pD.position_results(y_method).MousePerim./pD.position_results(y_method).ThinMousePerim;
            case  'background intensity (mean)'
                y_data = pD.position_results(y_method).BackGroundMean;
            case 'frame number'
                y_data = 1:length(pD.position_results(y_method).BackGroundMean);
            case 'mouse intensity mean' 
                y_data = pD.position_results(y_method).MouseMean;
            case 'mouse intensity var'
                y_data = pD.position_results(y_method).MouseVar;
            case 'mouse intensity range'                
                y_data = pD.position_results(y_method).MouseRange;
        end
        
        % If the hide excluded option is selected, make the "excluded"
        % values into nans. That will prevent them from displaying. 
        if handles.hide_excluded_checkbox.Value
            exc_frames = (handles.frame_class == 11);
            x_data(exc_frames) = nan;
            y_data(exc_frames) = nan;
        end
        
        
        % Make axes equal when it makes sense 
        axis(handles.parameter_axes,'normal');
        axis(handles.parameter_axes,'tight');
        if strcmp(x_param,'body x') && strcmp(y_param,'body y')
            axis(handles.parameter_axes,'equal');
        end
        if strcmp(x_param,'nose x') && strcmp(y_param,'nose y')
            axis(handles.parameter_axes,'equal');
        end
        if strcmp(y_param,'body position') || strcmp(y_param,'nose position')
            axis(handles.parameter_axes,'equal');
        end        
end


%% plot the results
frame_class = handles.frame_class;
un_classes  = unique(frame_class);
% clear the axes
axes(handles.parameter_axes);
cla
% set axes properties
handles.parameter_axes.XTickMode = 'auto';
handles.parameter_axes.YTickMode = 'auto';
handles.parameter_axes.XTickLabelMode = 'auto';
handles.parameter_axes.YTickLabelMode = 'auto';

% plot frames for each method, consider the show selected option
if ~handles.show_selected_checkbox.Value
    for i = 1:length(un_classes)
        this_class = un_classes(i);
        these_inds = find(frame_class == this_class);
        ph = plot(x_data(these_inds),y_data(these_inds),'.');
        set(ph,'color',method_col(this_class,:));
        hold on
    end
else
    for i = 1:length(un_classes)
        this_class = un_classes(i);
        these_inds = find(frame_class == this_class);
        included_inds = these_inds(ismember(these_inds,find(handles.frame_subset_to_show)));
        excluded_inds = setdiff(these_inds,included_inds);
        ph = plot(x_data(excluded_inds),y_data(excluded_inds),'.');
        set(ph,'color',method_col(this_class,:));
        set(ph,'MarkerSize',1)
        hold on
        ph = plot(x_data(included_inds),y_data(included_inds),'.');
        set(ph,'color',method_col(this_class,:));
        set(ph,'MarkerSize',10)
    end
end

% update X and Y data
handles.scatter_plot_x_data = single(x_data);
handles.scatter_plot_y_data = single(y_data);

axis tight
% Set axes limits (Add margins)
margfact = 0.05;
xlims = get(gca,'xlim');
xmarg = diff(xlims)*margfact;
set(gca,'xlim',[xlims(1)-xmarg,xlims(2)+xmarg]);
ylims = get(gca,'ylim');
ymarg = diff(ylims)*margfact;
set(gca,'ylim',[ylims(1)-ymarg,ylims(2)+ymarg]);


% axes labelling (which depends on the parmaters shown)
switch show_menu_selection
    case 'active setting'
        x_ax_h = xlabel('frame number');
        y_ax_h = ylabel('active setting');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
        set(handles.parameter_axes,'YTick',[-1:n_methods+2]);
        set(handles.parameter_axes,'YLim',[-2 n_methods+3]);
        yticklabel{1} = ['NaN (' num2str(sum(y_data == -1)) ')'];
        yticklabel{2} = ['X (' num2str(sum(y_data == 0)) ')'];
        for i = 1:n_methods
            yticklabel{i+2} = [num2str(i) '(' num2str(sum(y_data == i)) ')'];
        end
        yticklabel{i+3} = ['UD (' num2str(sum(y_data == i+1)) ')'];
        yticklabel{i+4} = ['INT (' num2str(sum(y_data == i+2)) ')'];
        set(handles.parameter_axes,'YTickLabel',yticklabel);
        set(handles.parameter_axes,'YTickLabelRotation',90)
    case 'annotated events'
        x_ax_h = xlabel('frame number');
        y_ax_h = ylabel('annotation');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
        set(handles.parameter_axes,'YTick',[0 1]);
        set(handles.parameter_axes,'YLim',[-0.5 1.5]);
        yticklabel{1} = 'no user events';
        yticklabel{2} = ['user events (' num2str(sum(y_data == 1)) ')'];
        set(handles.parameter_axes,'YTickLabel',yticklabel);
        set(handles.parameter_axes,'YTickLabelRotation',90)
    case 'angle change'
        x_ax_h = xlabel('frame number');
        y_ax_h = ylabel('delta body angle');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
    case 'mouse angle'
        x_ax_h = xlabel('frame number');
        y_ax_h = ylabel('mouse angle');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
    case 'nose speed'
        x_ax_h = xlabel('frame number');
        y_ax_h = ylabel('nose speed (relative to body)');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
    case 'body speed'
        x_ax_h = xlabel('frame number');
        y_ax_h = ylabel('body speed');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
    case 'body position'
        x_ax_h = xlabel('body position');
        y_ax_h = ylabel('body position');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
    case 'nose position'
        x_ax_h = xlabel('nose position');
        y_ax_h = ylabel('nose position');
        set(x_ax_h,'color','k','fontsize',10);
        set(y_ax_h,'color','k','fontsize',10);
    otherwise        
        x_ax_h = xlabel(x_param);
        y_ax_h = ylabel(y_param);
        set(x_ax_h,'color',method_col(x_method,:),'fontsize',10);
        set(y_ax_h,'color',method_col(y_method,:),'fontsize',10);
end

% when the angle change or nose speed options are selected, enable the
% relevant items
% This section is commented until we improve the correct fast transitions
% procedure
% if ismember(show_menu_selection,{'angle change','nose speed'})
%     handles.correct_fast_transitions_button.Enable = 'on';
%     handles.minimal_transition_edit.Enable         = 'on';
%     handles.minimal_transition_text.Enable         = 'on';
%     handles.maximal_corrected_segment_text.Enable  = 'on';
%     handles.bad_segment_length_edit.Enable         = 'on';
%     fast_transition_thresh = prctile(y_data,99);
%     handles.minimal_transition_edit.String = num2str(fast_transition_thresh);
%     handles.thresh_line_h    = line(get(gca,'XLim'),[fast_transition_thresh fast_transition_thresh],'color','k');
% else
%     handles.correct_fast_transitions_button.Enable = 'off';
%     handles.minimal_transition_edit.Enable         = 'off';
%     handles.minimal_transition_text.Enable         = 'off';
%     handles.maximal_corrected_segment_text.Enable  = 'off';
%     handles.bad_segment_length_edit.Enable         = 'off';
% end



% But instead we have the stop on particular frames
if strcmp(show_menu_selection,'angle change')   
    handles.correct_panel.Visible = 'on';
    % bad_thresh = min(90,prctile(y_data,95));
    bad_thresh = prctile(y_data,95);
    bad_thresh = max(60,bad_thresh);
    handles.bad_thresh_edit.String  = num2str(bad_thresh);    
    handles.bad_thresh_line_h    = line(get(gca,'XLim'),[bad_thresh bad_thresh],'color','r','linewidth',1,'tag','bad_thresh_line');            
    
    good_thresh = min(30,prctile(y_data,80));      
    handles.good_thresh_edit.String  = num2str(good_thresh);
    handles.good_thresh_line_h       = line(get(gca,'XLim'),[good_thresh good_thresh],'color','g','linewidth',1,'tag','good_thresh_line');            
else
    handles.correct_panel.Visible = 'off';
end
    

% But instead we have the stop on particular frames
if ismember(show_menu_selection,{'angle change','nose speed','body speed'})
           
    handles.stop_if_above_edit.Enable = 'on';
    % handles.stop_if_above_checkbox.Enable         = 'on';
    % handles.previous_abovethresh_button.Enable = 'on';
    % handles.next_abovethresh_button.Enable = 'on';
    
    
    % update the line handles and the frame subsets to show
    if ~isfield(handles,'suppress_line_update') || ~handles.suppress_line_update
        fast_transition_thresh = prctile(y_data,99);
        %frame_subset_to_show = false(size(handles.frame_class));
        %in = y_data > fast_transition_thresh;
        %frame_subset_to_show(in) = 1;
        %handles.frame_subset_to_show = frame_subset_to_show;        
        %           handles.show_selected_checkbox.Enable = 'on';
        %     handles.stop_playback_checkbox.Enable = 'on';
        %     handles.previous_abovethresh_button.Enable = 'on';
        %     handles.next_abovethresh_button.Enable = 'on';
        %     handles.show_selected_checkbox.Value = 1;
        %     if sum(in) > 1
        %         handles.n_selected_text.String = [num2str(sum(in)) ' frames marked'];
        %     else
        %         handles.n_selected_text.String = [num2str(sum(in)) ' frame marked'];
        %     end
        
    else
        fast_transition_thresh = str2num(handles.stop_if_above_edit.String);
    end    

        
    handles.stop_if_above_edit.String = num2str(fast_transition_thresh,'%.2f');
    handles.thresh_line_h    = line(get(gca,'XLim'),[fast_transition_thresh fast_transition_thresh],'color','k','linewidth',2);        
        
else   
   handles.stop_if_above_edit.Enable             = 'off';
   % handles.stop_if_above_checkbox.Enable         = 'off';
   % handles.previous_abovethresh_button.Enable    = 'off';
   % handles.next_abovethresh_button.Enable        = 'off';
end


% update the current frame indicator diamond
frc =  str2num(handles.current_frame_edit.String);
axes(handles.parameter_axes);
hold on
handles.highlighted_frame = plot(x_data(frc),y_data(frc),'kd','linewidth',2,'markersize',6);

if handles.hold_dotdisplay_zoom
    set(gca,'xlim',handles.hold_xlims);
    set(gca,'ylim',handles.hold_ylims);
end


guidata(handles.figure1, handles);

return


