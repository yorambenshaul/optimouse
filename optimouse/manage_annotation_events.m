function manage_annotation_events(handles,action)

% Get current event
content = handles.annotation_menu.String;
selection = content{handles.annotation_menu.Value};

switch action
    case 'frame+'
        % Check thatthere is a valid segment defined
        valid_segment = 1;
        % check if there is a valid segment to apply class to
        ind1 = str2num(handles.segment_start_text.String);
        if isempty(ind1)
            valid_segment = 0;
        end
        ind2 = str2num(handles.segment_end_text.String);
        if isempty(ind2)
            valid_segment = 0;
        end
        if ~(ind2>ind1)
            valid_segment = 0;
        end
        if valid_segment
            % reset the buttons
            handles.segment_start_text.String = '';
            handles.segment_end_text.String = '';
            fs = ['[' num2str(ind1) ':' num2str(ind2) ']'];
            eval(['handles.annotations.' selection '(' fs ') = 1;' ]);
            
            n = length([ind1:ind2]);
            msgbox(['Event ' selection ' was applied to ' num2str(n) ' frames'],'ANNOTATION')
        else % not a valid segment
            % do nothing if not a valid segment
            fs = handles.current_frame_edit.String; % frame string
            eval(['handles.annotations.' selection '(' fs ') = 1;' ]);            
        end
    case 'frame-'
        % Check thatthere is a valid segment defined
        valid_segment = 1;
        % check if there is a valid segment to apply class to
        ind1 = str2num(handles.segment_start_text.String);
        if isempty(ind1)
            valid_segment = 0;
        end
        ind2 = str2num(handles.segment_end_text.String);
        if isempty(ind2)
            valid_segment = 0;
        end
        if ~(ind2>ind1)
            valid_segment = 0;
        end
        if valid_segment
            % reset the buttons
            handles.segment_start_text.String = '';
            handles.segment_end_text.String = '';
            
            fs = ['[' num2str(ind1) ':' num2str(ind2) ']'];
            eval(['handles.annotations.' selection '(' fs ') = 0;' ]);
            
            n = length([ind1:ind2]);
            msgbox(['Event ' selection ' was removed from ' num2str(n) ' frames'],'ANNOTATION')
        else
            fs = handles.current_frame_edit.String; % frame string
            eval(['handles.annotations.' selection '(' fs ') = 0;' ]);            
        end
end

guidata(handles.figure1,handles);
% This is relevant if we have the annotation field on
update_position_histograms_mm(handles)
handles = guidata(handles.figure1);
replay_calculated_positions_mm(handles.figure1,handles,2);




