function calculate_positions_mm(detection_method_file)
% modified from calculate_positions which works for only one method.
% based on update_arena_images, but is faster since it does not query
% all the parameters.
%
% The only input to this function is a filename - which it loads
% to get all the information that was previously passed explicitly.
% This is required because there may be multiple methods.
% YBS 9/16

% Load info
load(detection_method_file);
arena_data = load(arena_file_name);
FrameInfo = arena_data.FrameInfo;
TotalFrames = size(FrameInfo,1);
pixels_per_mm = arena_data.pixels_per_mm;

% run over all detction settings
for dsi = 1:length(detection_methods)
    
    % clean variables for each iteration
    clear mouseCOM nosePOS TrimFact MouseArea MousePerim ThinMousePerim BackGroundMean MouseMean MouseVar MouseRange GreyThresh;    
       
    % The actual algorithm
    head_method = detection_methods(dsi).algorithm;
     
    % for compatability with earlier versions that did not have the field
    if isfield(detection_methods,'user_method_name')
        if ~isempty(detection_methods(dsi).user_method_name)
            user_defined_method = 1;
        else
            user_defined_method = 0;
        end
    else
        user_defined_method = 0;
    end
    
    % Find if this is a user defined method
    if user_defined_method       
        % Error checking was already done
        n_params = length(detection_methods(dsi).user_defined_param_names);
        for i = 1:n_params
            eval([detection_methods(dsi).user_defined_param_names{i} ' = ' num2str(detection_methods(dsi).user_defined_params(i)) ';']);
        end
        cmd_str = detection_methods(dsi).user_method_runstring;
    else
        cmd_str = 'Result = get_mouse_position_mm(ThisFrame,head_method,trim_cycles,GreyThresh_fact);';       
    end
       
    trim_cycles = detection_methods(dsi).trimlevel;
    GreyThresh_fact = str2num(detection_methods(dsi).threshold);
    
    if detection_methods(dsi).median_background
        BackGroundType = 'Median';
        BackGroundImage = arena_data.MedianImage;
    elseif detection_methods(dsi).user_background
        BackGroundType = 'User Defined';
        BackGroundImage = detection_methods(dsi).BackGroundImage;
    elseif detection_methods(dsi).no_background
        BackGroundType = 'None';
        BackGroundImage = uint8(zeros(size(arena_data.MedianImage)));
    else
        disp('no valid value for background setting')
        return
    end
       
    if detection_methods(dsi).mouse_brighter % handles.mouse_brighter_radiobutton.Value
        MedianMethod = 1;
    elseif detection_methods(dsi).mouse_darker % handles.mouse_darker_radiobutton.Value
        MedianMethod = 2;
    elseif detection_methods(dsi).auto_determine_color % handles.auto_determine_brighter_radiobutton.Value
        % get the Median Method from the interface - otherwise take the first file
        % and this is probably a bad idea
        MedianMethod = 3;
    end    
    
    fnums = unique(FrameInfo(:,1));
    frc = 1;    
    
    progbar_h = waitbar(0,['calculating positions in ' num2str(TotalFrames) ' frames. method ' num2str(dsi) ' of ' num2str(length(detection_methods))],'Name','Calculating mouse position');
    
    for filec = 1:length(fnums)
        
        clear ROI_tmp_frames % for being extra safe
        
        this_file = [full_tmp_file_base_name  '_'  num2str(fnums(filec)) '.mat'];       
        
        if ~exist(this_file,'file')
            errordlg(['Cannot detect positions, the file ' this_file ' does not exist']);
            delete(progbar_h);
            return
        end
        
        load(this_file);
        
        % Auto detection
        if MedianMethod == 3
            % get the Median Method from the interface - otherwise take the first file
            % and this is probably a bad idea
            MedianMethod = determine_contrast_method(ROI_tmp_frames(:,:,1));
        end
        
        % This line is reuired if we are not subtracting a background
        % and the mouse is darker
        if strcmp(BackGroundType,'None') && MedianMethod==2
            BackGroundImage = BackGroundImage + 255;
        end
        
        nframes = size(ROI_tmp_frames,3);
        for k = 1:nframes
            if MedianMethod==1
                ThisFrame = ROI_tmp_frames(:,:,k) - BackGroundImage;
            elseif MedianMethod==2
                ThisFrame = BackGroundImage - ROI_tmp_frames(:,:,k);
            end
                                   
            try
                eval(cmd_str);                
                % in case user functions do not return all fields, add them here
                Result = add_fields_to_Result_structure(Result);                
            catch
                Result = add_fields_to_Result_structure([]);
            end            
            
            mouseCOM(frc,:)      =  Result.mouseCOM;
            nosePOS(frc,:)       =  Result.nosePOS;
            GreyThresh(frc)      =  Result.GreyThresh;
            TrimFact(frc)        =  Result.TrimFact;
            MouseArea(frc)       =  Result.MouseArea;
            MousePerim(frc)      =  Result.MousePerim;
            ThinMousePerim(frc)  =  Result.ThinMousePerim;            
            BackGroundMean(frc)  =  Result.BackGroundMean;
            MouseMean(frc)       =  Result.MouseMean;
            MouseRange(frc)      =  Result.MouseRange;
            MouseVar(frc)        =  Result.MouseVar;
            
            frc = frc + 1;
        end
        % update wait bar and return if it was closed by user
        if ishandle(progbar_h)
            waitbar(frc/TotalFrames,progbar_h,['calculating positions in ' num2str(TotalFrames) ' frames. method ' num2str(dsi) ' of ' num2str(length(detection_methods))]);
        else
            msgbox('Position calculation terminated by user','OptiMouse - calculate positions');
            return
        end        
    end
    delete(progbar_h);
    
    mouse_length = sqrt((mouseCOM(:,1)-nosePOS(:,1)).^2 + (mouseCOM(:,2)-nosePOS(:,2)).^2)/pixels_per_mm;
    MouseArea = MouseArea/(pixels_per_mm^2);
    % Note that the y dir is reversed. hence the order of terms
    mouse_angle = atan2d(mouseCOM(:,2)-nosePOS(:,2),nosePOS(:,1)-mouseCOM(:,1));
    mouse_angle(mouse_angle<0) = mouse_angle(mouse_angle<0) + 360;
    
    detection_params(dsi).head_method = head_method;
    detection_params(dsi).trim_cycles = trim_cycles;
    detection_params(dsi).GreyThresh_fact = GreyThresh_fact;
    
    % This parameter might have changed, if it was set to 3
    detection_params(dsi).MedianMethod = MedianMethod;
    detection_params(dsi).BackGroundType = BackGroundType;
    
    if user_defined_method
        detection_params(dsi).user_defined_param_names = detection_methods(dsi).user_defined_param_names;
        detection_params(dsi).user_defined_param_vals = detection_methods(dsi).user_defined_params;
        detection_params(dsi).user_method_name = detection_methods(dsi).user_method_name;
    else
        detection_params(dsi).user_defined_param_names = [];
        detection_params(dsi).user_defined_param_vals = [];
        detection_params(dsi).user_method_name = [];
    end
        
    % Save all the results into a structure
    position_results(dsi).mouseCOM       = mouseCOM;
    position_results(dsi).nosePOS        = nosePOS;
    position_results(dsi).GreyThresh     = GreyThresh;
    position_results(dsi).TrimFact       = TrimFact;
    position_results(dsi).MouseArea      = MouseArea;
    position_results(dsi).MousePerim     = MousePerim;
    position_results(dsi).ThinMousePerim = ThinMousePerim;
    position_results(dsi).mouse_angle    = mouse_angle;
    position_results(dsi).mouse_length   = mouse_length;    
    position_results(dsi).MouseMean      = MouseMean;
    position_results(dsi).MouseRange     = MouseRange;
    position_results(dsi).MouseVar       = MouseVar;                
    position_results(dsi).BackGroundMean = BackGroundMean;
    
end % over all detection methods

save(position_file,'detection_params','arena_data','position_results','detection_methods');


return




