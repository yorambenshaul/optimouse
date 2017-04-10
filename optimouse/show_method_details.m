function show_method_details(handles)
% show  details of user defined methods in the review positions GUI
% results are shown in a new figure
% YBS 9/16

% Getting the list twice is a bit of a waste, but the waste is negligible
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
pD = load(position_file);

% Get all applied classes
rel_class = unique(handles.frame_class);

% method colors
method_col = handles.method_col;

% get method names
n_methods = length(pD.detection_methods);
method_names = {pD.detection_methods.name};

% positions for each of the axes
ui_positions{1} = [0.05 0.6 0.3 0.3];
ui_positions{2} = [0.36 0.6 0.3 0.3];
ui_positions{3} = [0.67 0.6 0.3 0.3];
ui_positions{4} = [0.05 0.1 0.3 0.3];
ui_positions{5} = [0.36 0.1 0.3 0.3];
ui_positions{6} = [0.67 0.1 0.3 0.3];


fh = figure;
set(fh,'name','user defined detection params','numbertitle','off')

for i = 1:length(method_names)    
    method_p_h(i) = uicontrol('style','text');
    method_p_h(i).Units = 'normalized';
    method_p_h(i).Position = ui_positions{i};
    method_p_h(i).BackgroundColor = [1 1 1];
    
    
    if pD.detection_methods(i).mouse_brighter
        bright_str = 'bright mouse';
    elseif pD.detection_methods(i).mouse_darker
        bright_str = 'dark mouse';
    elseif pD.detection_methods(i).auto_determine_color
        bright_str = 'auto determined';
    end
    
    
    method_string{i}{1} = [method_names{i}];
    method_string{i}{2} = ['algorithm: ' num2str(pD.detection_params(i).head_method)];
    method_string{i}{3} = ['peeling steps: ' num2str(pD.detection_params(i).trim_cycles)];
    method_string{i}{4} = ['grey threshold fact: ' num2str(pD.detection_params(i).GreyThresh_fact)];
    method_string{i}{5} = ['background type: ' num2str(pD.detection_params(i).BackGroundType)];
    method_string{i}{6} = [bright_str];   
    
    if isfield(pD,'user_method_name')
        if ~isempty(pD.detection_methods(i).user_method_name)
            method_string{i}{8} = 'user defined function';
            method_string{i}{9} = ['''' pD.detection_methods(i).user_method_name ''''];
            for pi = 1:length(pD.detection_methods(i).user_defined_param_names)
                method_string{i}{9+pi} = [pD.detection_methods(i).user_defined_param_names{pi} ' = ' num2str(pD.detection_methods(i).user_defined_params(pi))];
            end
        end
    end
    
    method_p_h(i).String = method_string{i};
    method_p_h(i).FontSize = 10;
    method_p_h(i).ForegroundColor = method_col(i,:);
    method_p_h(i).HorizontalAlignment = 'left';
end
        
return

