function set_frame_as_class(handles,class)
% set a given frame or a range of frames to a given class
% If there is a valid range in the review position GUI it will be used
% otherwise - it will apply to the given frame
% YBS 9/16

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
end

if valid_segment
    frc = [ind1:ind2];
else
    frc =  str2num(handles.current_frame_edit.String);
end

frame_class = handles.frame_class;
frame_class(frc) = class;
handles.frame_class = frame_class;
guidata(handles.figure1,handles);
update_position_histograms_mm(handles)
handles = guidata(handles.figure1);
replay_calculated_positions_mm(handles.figure1,handles,2);

if valid_segment
    msgbox(['Settings were applied to ' num2str(length(frc)) ' frames'],'SET SEGMENT')
end


return