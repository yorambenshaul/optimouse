function user_param_edit_callback(handles,hObject,paramnum)
% Check values in user defined parameter edit box, based on user defined
% range limits for the functions
% YBS 9/16

% Find the current user defined function
val = handles.detection_method_menu.Value;
user_detection_functions_vals = cell2mat({handles.user_detection_functions.menuval});
fid = find(val == user_detection_functions_vals);
% find the param range
param_range = handles.user_detection_functions(fid).param_range{paramnum};
% check that the current value is valid and within the range
cur_val = str2num(hObject.String);
if isempty(cur_val)
    hObject.String = num2str(param_range(1));   
end
if cur_val > param_range(2)
    hObject.String = num2str(param_range(2));    
end
if cur_val < param_range(1)
    hObject.String = num2str(param_range(1));    
end