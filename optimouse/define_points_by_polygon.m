function define_points_by_polygon(handles,class)
% Define poinbts of denoting frames using a polygon
% Called from the review_positions interface
% YBS 9/16


PolY =findobj('Tag','userpoly');
if ~isempty(PolY)
    delete(PolY)
end

% because ROI definitions are prone to error, I use a try catch

try
    
    method_col = handles.method_col;
    
    % define a polygon and get its location
    h = impoly(handles.parameter_axes);
    
    if isempty(h)
        return
    end
    
    set(h,'Tag','userpoly')
        
    setClosed(h,'true')
    if class < size(method_col,1)
        setColor(h,method_col(class,:));
    end
    position = wait(h);
    delete(h);
    
    if isempty(position)
        return
    end
    
    
    % get current points
    xq = handles.scatter_plot_x_data;
    yq = handles.scatter_plot_y_data;
    
    xv = [position(:,1) ; position(1,1)];
    yv = [position(:,2) ; position(1,2)];
    
    % determine which points are inside it
    in = inpolygon(xq,yq,xv,yv);
    
    % if not for defining highlighted frames 
    if ~(class == 2807)
        frame_class = handles.frame_class;
        frame_class(in) = class;
        handles.frame_class = frame_class;
        if ~(class == 11)
            disp([num2str(sum(in)) ' frames assigned to class ' num2str(class)]);
        else
            disp([num2str(sum(in)) ' frames excluded ']);
        end
    % if defining highlighted frames 
    else
        % This if for showing only specific frames in a display
        frame_subset_to_show = false(size(handles.frame_class));
        frame_subset_to_show(in) = 1;
        if sum(in) > 0
            handles.show_selected_checkbox.Enable = 'on';
            handles.stop_playback_checkbox.Enable = 'on';
            handles.previous_abovethresh_button.Enable = 'on';
            handles.next_abovethresh_button.Enable = 'on';
            handles.show_selected_checkbox.Value = 1;
            if sum(in) > 1
                percent_string = num2str(100* sum(in)/handles.data.nframes,'%.1f');
                handles.n_selected_text.String = [num2str(sum(in)) ' frames marked (' percent_string '%)'];
            else
                handles.n_selected_text.String = [num2str(sum(in)) ' frame marked'];
            end
        else
            handles.show_selected_checkbox.Enable = 'off';
            handles.stop_playback_checkbox.Enable = 'off';
            handles.previous_abovethresh_button.Enable = 'off';
            handles.next_abovethresh_button.Enable = 'off';
            handles.show_selected_checkbox.Value = 0;
            handles.stop_playback_checkbox.Value = 0;
            handles.n_selected_text.String = ['0 frames marked'];
        end            
        handles.frame_subset_to_show = frame_subset_to_show;
    end
    
    
    guidata(handles.figure1,handles);
    update_position_histograms_mm(handles)
    handles = guidata(handles.figure1);
    replay_calculated_positions_mm(handles.figure1,handles,2);
    
catch
    PolY =findobj('Tag','userpoly');
    if ~isempty(PolY)
        delete(PolY)
    end
end

return