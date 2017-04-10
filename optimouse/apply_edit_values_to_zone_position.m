function apply_edit_values_to_zone_position(hObject, ~, handles)
% This function does the opposite of update_zone_pos
% and not vice versa - namely it applies edit box values to zone positions
% This optoin is available only for rect and ellipsoid  
% YBS 9/16

if isempty(handles.zone_listbox.String)
    return
end

pixels_per_mm = handles.pixels_per_mm;

% Get the values that have to be applied
new_x_center = str2num(handles.X_pos_edit.String);
new_y_center = str2num(handles.Y_pos_edit.String);
new_x_extent = str2num(handles.width_edit.String);
new_y_extent = str2num(handles.height_edit.String);

x_min = new_x_center - new_x_extent/2;
y_min = new_y_center - new_y_extent/2;

new_pos(1) = x_min * pixels_per_mm; 
new_pos(2) = y_min * pixels_per_mm;
new_pos(3) = new_x_extent *  pixels_per_mm;
new_pos(4) = new_y_extent *  pixels_per_mm;

current_zone = handles.zone_listbox.String{handles.zone_listbox.Value};
zone_names = {handles.zones.name};
rel_ind = strcmp(current_zone,zone_names);

% Is this a fixed ratio shape - namely square or circles
% Then the width and the height have to remain identical
if handles.zones(rel_ind).fixedRatio;
    % If so, we have to know which value was changed, X or Y
    if strcmp(hObject.Tag,'width_edit')
        % if the width was changed, we apply the value also to the height
        new_pos(4) = new_pos(3);        
        handles.height_edit.String = handles.width_edit.String;
    elseif strcmp(hObject.Tag,'height_edit')
        % if the height was changed, we apply the value also to the width
        new_pos(3) = new_pos(4);
        handles.width_edit.String = handles.height_edit.String;
    end
end

% update the position of the selected zone
setPosition(handles.zones(rel_ind).handle,new_pos);


guidata(hObject, handles);



