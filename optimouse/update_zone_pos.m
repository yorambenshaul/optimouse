function update_zone_pos(zone_pos,handles)
% This funciton does the opposite of apply_edit_values_to_zone_position
% it updates the edit boxes with the current zone positions
% YBS 9/16

pixels_per_mm = handles.pixels_per_mm;

% square or circle
if size(zone_pos,2) == 4 % ellipse or rect
   x_center = zone_pos(1) + 0.5 * zone_pos(3);
   y_center = zone_pos(2) + 0.5 * zone_pos(4);
   x_extent = zone_pos(3);
   y_extent = zone_pos(4);
elseif size(zone_pos,2) == 2 % poly or freehand
    zone_rng = range(zone_pos,1);
    zone_cen = mean(zone_pos,1);
    x_extent = zone_rng(1);
    y_extent = zone_rng(2);
    x_center = zone_cen(1);
    y_center = zone_cen(2);
end
x_center = x_center/pixels_per_mm;
y_center = y_center/pixels_per_mm;
x_extent = x_extent/pixels_per_mm;
y_extent = y_extent/pixels_per_mm;


handles.X_pos_edit.String = num2str(x_center);
handles.Y_pos_edit.String = num2str(y_center);
handles.width_edit.String = num2str(x_extent);
handles.height_edit.String = num2str(y_extent);
