function getCurrentFrame(handles)
% get current from from review_positions interface
% YBS 9/16

% get location of selected point
currentPoint = get(gca, 'CurrentPoint');
x_point = currentPoint(1,1);
y_point = currentPoint(1,2);

% get the coordinates of all points
x_data = handles.scatter_plot_x_data;
y_data = handles.scatter_plot_y_data;

x_range = diff(get(gca,'xlim'));
y_range = diff(get(gca,'ylim'));

origaxunits = get(handles.parameter_axes,'units');
set(handles.parameter_axes,'units','centimeters');

axpos = get(handles.parameter_axes,'position');
heightwidthratio = axpos(4)/axpos(3);
set(handles.parameter_axes,'units',origaxunits);
% axis square

% get distances to all points
xd = (x_data - x_point)/x_range;
yd = heightwidthratio * (y_data - y_point)/y_range;
if ~(size(xd,1) == size(yd,1))
    yd = yd';
end

point_dists = sqrt(xd.^2 + yd.^2);

% find closest point
[~,point_ind] = min(point_dists);
handles.current_frame_edit.String = num2str(point_ind);

replay_calculated_positions_mm(handles.figure1,handles,2);

return
