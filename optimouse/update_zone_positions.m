function update_zone_positions(zone_h,pos,zone_id)
% update zone position dimensions when it is moved by user
% YBS 9/16

% was mycb(handle,pos,num)
handles = guidata(gcf);
zone_ids   = [handles.zones.unique_id];
zone_names = {handles.zones.name};
% find the relevant ind
this_ind  = find(zone_id == zone_ids);
zone_name = zone_names{this_ind};

zone_names_in_list = handles.zone_listbox.String;
rel_value_in_list = strmatch(zone_name,zone_names_in_list,'exact');
handles.zone_listbox.Value = rel_value_in_list;
guidata(gcf,handles);

% analyze_behavior('zone_listbox_Callback',gcf, [], handles);
if isempty(handles.zone_listbox.String)
    return
end
current_zone = handles.zone_listbox.String{handles.zone_listbox.Value};
zone_names = {handles.zones.name};
rel_ind = strcmp(current_zone,zone_names);
setColor(handles.zones(rel_ind).handle,'r');

% update the position of the selected zone
zone_pos = getPosition(handles.zones(rel_ind).handle);

% Enter values in box
update_zone_pos(zone_pos,handles);

% Enable edit boxes if this is a rect or a circle
% disable otherwise
if size(zone_pos,2) == 4 % ellipse or rect
   enable_edits = 'on';
elseif size(zone_pos,2) == 2 % poly or freehand
   enable_edits = 'off';
end
handles.X_pos_edit.Enable = enable_edits;
handles.Y_pos_edit.Enable = enable_edits;
handles.width_edit.Enable = enable_edits;
handles.height_edit.Enable = enable_edits;

other_inds = find(~rel_ind);
for i = 1:length(other_inds)
    setColor(handles.zones(other_inds(i)).handle,'b'); 
end

guidata(gcf, handles);

return