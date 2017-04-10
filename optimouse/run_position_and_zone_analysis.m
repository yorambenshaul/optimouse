function run_position_and_zone_analysis(handles,hObject)
% run all analyses of mouse position data
% if user selects to save, results will be saved in a structure containing
% the following fields:
% cms_travelled: arrray of doubles with the cumulative distance travelled in each frame
% total_cms_travelled: total distance travelled, which is equivalent to the last element in cms_travelled
% experiment_tags: any user entered experiment_tags associated with this file
% good_frames: a logical array, with 1 for every frame that is not excluded, and does not have a NaN entry for position
% nose_zone_visits: cell array, with one element for each zone, where each
% element is an N by 2 array. N is the number of segments within a zone - that is, each row corresponds to one segment.
% The first column is the entry time, the second column is the exit time.
% nose_zone_durations: cell array, with one element for each zone, where each
% element is an N by 1 array of segment times.
% body_zone_visits: like nose_zone_visits, but for body rather than nose
% body_zone_durations: like nose_zone_durations, but for body rather than nose
% event_names: a cell array with event names. Only events which are
% non-empty are included (that is, valid events that are not associated with any frames are not included)
% event_inds: Cell array,  (one element for each event) with each element itself an array of frame indices.
% In the array are the frames associated with each of the events. The
% number of elements for each such events is thus the number of frames
% associated with the event
% N_this_event_in_this_zone: An M x Z array, where M is the number of events, and Z is the number of Zones.
% Each element contains the number of event frames occuring within each of
% the zones.
% fraction_events_in_this_zone: like N_this_event_in_this_zone, but
% normalized for the total number of (non excluded) frames
% ZAcm2: arrray of doubles with area in cm2 of each zone
% ZV: cell array containing vertices defining each zone
% allZPbody: logical ZxN array, with Z being the number of zones, and N being the number of good frames.
%            A value of 1 in element [z,n] indicates that the body position was inside zone z in frame n
% allZPnose: same as allZPbody but with nose rather than body positions
% cumZbody_enrichment: double ZxN array, with the enrichment of the body position in each frame for each zone
% cumZnose_enrichment: same as above, but for nose positions
% cumsumZPbody: double ZxN array, with the cumulative sum of frames spent in each frame for each zone
% cumsumZPnose: same as above but for nose positions
% deltaT: time interval in second between frames
% delta_body_cm_s: body velocity in each frame (cm/s)
% mean_body_speed: mean body speed in cm/s
% median_body_speed: median body speed in cm/s
% pD: structure inherited from the position file.
%     % Note that these fields include data for all frames, prior to exclusion
%     % the fields are:
%     arena_data: [1x1 struct] containing information about the arena
%     detection_methods: [1xn struct], where n is the number of detection
%     settings used in the calculation stage. The fields describe the
%     detection parameters used. Fields within detection methods are:
%     name
%     algorithm
%     trimlevel
%     threshold
%     median_background
%     user_background
%     no_background
%     mouse_brighter
%     mouse_darker
%     auto_determine_color
%     BackGroundImage
%     user_defined_params
%     user_defined_param_names
%     user_method_name
%     user_method_runstring
% position_results: A structure with one element for each detection
%     setting. Includes thje following fields:
%     mouseCOM: An Nx2 array with the X and Y coordinates each of the mouse center of mass as detected by each of the settings
%     nosePOS:  An Nx2 array with the X and Y coordinates each of the nose position as detected by each of the settings
%     GreyThresh: A 1XN array with the grey threshold used for each frame
%     TrimFact: A 1XN array with the trimming factor associated with each frame
%     MouseArea: A 1XN array with the mouse area in each frame
%     MousePerim: A 1XN array with the mouse perimeter in each frame
%     ThinMousePerim: A 1XN array with the mouse perimeter, after peeling, in each frame
%     mouse_angle: A 1XN array with mouse angles in each frame
%     mouse_length: A 1XN array with mouse lengths in each frame
%     MouseMean:  A 1XN array with the mean intensity value of the mouse object in each frame
%     MouseRange: A 1XN array with the range of intensity values of the mouse object in each frame
%     MouseVar: A 1XN array with the variance of intensity values of the mouse object in each frame
%     BackGroundMean: A 1XN array with the mean intensity values of the
%     rectangle containing the mouse object - the mouse pixels are excluded
%
% frame_class: A 1XN array with the active setting for each frame. Values
% between 1-6 denote user defined settings. 10 corresponds to manual set
% values. 11 is for excluded frames. 12 is for interpolated frames.
% user_defined_nosePOS: NX2 array containing the mouse nose
% coordinates for frames with user defined positions.
% user_defined_mouseCOM: % user_defined_nosePOS: NX2 array containing the mouse center of mass
% coordinates for frames with user defined positions.
% user_defined_mouse_angle: NX1 array containing the mouse angle in frames
% with user defined positions.
% the following 3 fields are analogous to the user_defined fields, for
% frames containiong interpolated positions.
% interpolated_body_position
% interpolated_nose_position
% interpolated_mouse_angle
% final_nose_positions: A Nx2 array with final nose positions in each frame
% - the values are determined by the active settings within each
% frame. Excluded frames have nan values.
% final_body_positions: A Nx2 array with final body positions in each frame
% - the values are determined by the active settings within each
% frame. Excluded frames have nan values.
% final_mouse_angles: A 1xN array with final angles in each frame -
% - the values are determined by the active settings within each
% frame. Excluded frames have nan values.
% annotations: a structure array,with one element for each annotation event
% type as defined in the review positions stage. Each element is a sparse array of doubles with one element for each frame.
% elements corresponding to frames associated with the event have a value
% of 1, and 0 otherwise.
% position_file: full name of position file
% smooth_points: number of points used to smooth the velocity trace
% smooth_win_sec: length of smoothing window in seconds
% smoothed_speed: smoothed bosy speed as a function of time [20937x1 double]
% std_body_speed: std of body speed
% frame_times: array of times for each frame (also for excluded frames)

% zone_names: a cell array with zone names
% totalFramesZPnose: ZX1 array with the total frames that nose spent in each zone
% totalFramesZPbody: ZX1 array with the total frames that body spent in each zone
% totalTimeZPnose: ZX1 array with the total time that the nose spent in each zone
% totalTimeZPbody: ZX1 array with the total time that the body spent in each zone
% totalTimeZPnose_CM2: ZX1 array with the total time that the nose spent in each zone per cm2
% totalTimeZPbody_CM2: ZX1 array with the total time that the body spent in each zone per cm2
% fractionTimeZPnose: ZX1 array with the fraction of time that the nose spent in each zone
% fractionTimeZPbody: ZX1 array with the fraction of time that the body spent in each zone
% totalZnose_enrichment: ZX1 array with the total enrichment of the nose in each zone
% totalZbody_enrichment: ZX1 array with the total enrichment of the body in each zone
% pairwise_zone_pref_index_nose %ZxZ matrix, where element i,j is equal to:
% [time spent by nose in zone i – time spent by nose in zone j] / total time spent by nose in both zones.
% It assumes values between -1 and 1. The matrix is antisymmetric around the diagonal
% pairwise_zone_pref_index_nose %  same as above but for body positions.
%
% YBS 9/16


ignore_excluded    = handles.ignore_excluded_frames_checkbox.Value;

% intialize flags for all tasks
save_as_mat   = 0 ; %
show_nose   = 0;
show_body   = 0;
do_speed = 0;
do_distance = 0;
do_angles = 0;
do_heat_map = 0;
do_tracks = 0;
do_zone_pref_total = 0;
do_zone_pref_cumulative = 0;
do_compare_zones = 0;
do_zone_time_stats = 0;
do_show_results_on_prompt = 0;
do_general_event_stats = 0;
do_events_as_function_of_time = 0;
do_events_as_function_of_position = 0;
do_events_as_function_of_zones = 0;

switch hObject.Tag
    case 'distance_button'
        do_distance = 1;
    case 'show_tracks_button'
        do_tracks = 1;
        show_body = 1;
        show_nose = 1;
    case 'body_angle_button'
        do_angles = 1;
    case 'heat_map_button'
        do_heat_map = 1;
        show_body   = 1;
        show_nose   = 1;
    case 'speed_button'
        do_speed = 1;
    case 'zone_totals_button'
        do_zone_pref_total = 1;
        show_body   = 1;
        show_nose   = 1;
    case 'zone_in_time_button'
        do_zone_pref_cumulative = 1;
        show_body   = 1;
        show_nose   = 1;
    case 'compare_zones_button'
        do_compare_zones = 1;
        show_body   = 1;
        show_nose   = 1;
    case 'zone_visit_stats_button'
        do_zone_time_stats = 1;
        show_body   = 1;
        show_nose   = 1;
    case 'general_event_stats_button'
        do_general_event_stats = 1;
    case 'events_in_time_button'
        do_events_as_function_of_time = 1;
    case 'events_as_position_button'
        do_events_as_function_of_position = 1;
    case 'events_in_zones_button'
        do_events_as_function_of_zones = 1;
    case 'save_to_mat_button'
        save_as_mat   = 1 ; %
    case 'show_result_in_cmd_line_button'
        do_show_results_on_prompt = 1;
    otherwise
        return
end



%% color definitions for zones
% color order for plotting (should be a large enough number as it is)
zone_colors = [1 0 0 ; 0 1 0 ; 0 0 1 ; 1 1 0; 1 0 1; 0 1 1 ; 0 0 0; ...
    0 0.2 0.6 ; 0.9 0.2 0.6 ; 0.5 0.5 0.5 ; 0.2 0.1 0.7 ;  0.2 0.6 0.7 ; 0.8 0.6 0.4 ;...
    1 0.8 0 ; 0 1 0.8];
zone_colors = [zone_colors ; fliplr(zone_colors)];

%% load the position data and calculate scale conversion factors and arena size
contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
[~,pos_file_name,~] = fileparts(position_file);
pD = load(position_file);
% calculate dimensions
pixels_per_mm = pD.arena_data.pixels_per_mm;
pixels_per_cm = pixels_per_mm*10;
cm_per_pixel =  1/pixels_per_cm;
% Arena area - note that this is distinct from the area defined by the image
arena_area_in_pixels = polyarea(pD.arena_data.arena_info.vertices(:,1),pD.arena_data.arena_info.vertices(:,2));

area_in_mm2 = arena_area_in_pixels/(pixels_per_mm^2);
area_in_cm2 = area_in_mm2 / 100;

%% get position information (with referal to bad frames and whether corrected frames are to be used)
if isfield(pD,'final_nose_positions')
    nosePOS = pD.final_nose_positions;
    bodyPOS = pD.final_body_positions;
    mouse_angles = pD.final_mouse_angles;
    % frames which are excluded, or do not have a position, are excluded from analysis
    good_frames = true(size(pD.frame_class));
    good_frames(isnan(mouse_angles))  = false;
    good_frames(pD.frame_class == 11) = false;
else
    nosePOS = pD.position_results(1).nosePOS;
    bodyPOS = pD.position_results(1).mouseCOM;
    mouse_angles = atan2d(bodyPOS(:,2)-nosePOS(:,2),nosePOS(:,1)-bodyPOS(:,1));
    
    if mouse_angles < 0
        mouse_angles = mouse_angles + 360;
    end
    
    good_frames = true(size(mouse_angles));
    good_frames(isnan(mouse_angles)) = false;
end

%% create the information string
info_str = [pos_file_name ' | valid frames: ' num2str(sum(good_frames)) ' of ' num2str(length(good_frames)) ];


%% generate time base
FrameInfo   = pD.arena_data.FrameInfo;
deltaT      = FrameInfo(2,3) - FrameInfo(1,3);
TotalFrames = size(nosePOS,1);
TotalTime   = TotalFrames * deltaT;
frame_times = [1:TotalFrames] * deltaT;

%% calculate body speed (don't see need to calculate nose speed)
delta_body = zeros(1,TotalFrames);
tmp        = diff(bodyPOS,1,1);
delta_body(2:end)  = sqrt(sum(tmp.^2,2));
delta_body_cm_s = delta_body / (pixels_per_cm * deltaT);
clear tmp

%% calculate distance travelled
tmp = delta_body;
tmp(isnan(delta_body)) = 0;
pixels_travelled = cumsum(tmp);
cms_travelled = pixels_travelled * cm_per_pixel;



%% get zone vertices and areas
zones = handles.zones;
if ~isempty(zones)
    zones_exist = 1;
    zone_names = {zones.name};
    % Get vertices and area
    for i = 1:length(zones)
        switch zones(i).zone_type
            case {'circle','ellipse'}
                ZV{i} = getVertices(handles.zones(i).handle);
            case {'rectangle','square'}
                pos = getPosition(handles.zones(i).handle);
                ZV{i}(1,:) = [pos(1) pos(2)];
                ZV{i}(2,:) = [pos(1)+pos(3) pos(2)];
                ZV{i}(3,:) = [pos(1)+pos(3) pos(2)+pos(4)];
                ZV{i}(4,:) = [pos(1)        pos(2)+pos(4)];
                ZV{i}(5,:) = [pos(1) pos(2)]; % close the rect
            case {'polygon','freehand'}
                ZV{i} = getPosition(handles.zones(i).handle);
                % close the shape YBS 5/2/2017
                nv =size(ZV{i},1);
                ZV{i}(nv+1,:) = ZV{i}(1,:);
        end
        ZAcm2(i) = polyarea(ZV{i}(:,1),ZV{i}(:,2))/pixels_per_cm^2;
    end
else
    zones_exist = 0;
    zone_names = [];
    ZV = [];
end

%% Get "time" spent in each zone
%% here we need to think carefully about the bad excluded - frames
%% we need to define a new "clean" nosePOS

% it is here that the decision about ignore excluded frames matters
if ignore_excluded
    good_nosePOS = nosePOS(good_frames,:);
    good_bodyPOS = bodyPOS(good_frames,:);
    good_frame_times = frame_times(good_frames);
    total_good_frames = length(good_frame_times);
    TotalZoneTime     = total_good_frames * deltaT;
else
    good_nosePOS = nosePOS;
    good_bodyPOS = bodyPOS;
    good_frame_times  = frame_times;
    total_good_frames = length(good_frame_times);
    TotalZoneTime     = total_good_frames * deltaT;
end

% time is given in samples
% (and it does not matter since we are referring to relative time)
% ZP for zone positions
% This is the cumlative number of frames per area in cm
cumMTPC2 = [1:total_good_frames]./area_in_cm2;
cumMT    = [1:total_good_frames];

if zones_exist
    for i = 1:length(zones)
        % check if mouse was in zone for each frame
        allZPnose(i,:)           = inpolygon(good_nosePOS(:,1),good_nosePOS(:,2),ZV{i}(:,1),ZV{i}(:,2)) ;
        % cumulative sum of time spent
        cumsumZPnose(i,:)        = cumsum(allZPnose(i,:));
        % enrichment - defined as the fraction of frames sepnt in zone, divided
        % by the expected time to be in this zone within the arena
        % expected = under a uniform distribution of positions
        cumZnose_enrichment(i,:) = cumsumZPnose(i,:)./cumMT / (ZAcm2(i)/area_in_cm2);
        
        % same for body positions
        allZPbody(i,:)           = inpolygon(good_bodyPOS(:,1),good_bodyPOS(:,2),ZV{i}(:,1),ZV{i}(:,2)) ;
        cumsumZPbody(i,:)        = cumsum(allZPbody(i,:));
        cumZbody_enrichment(i,:) = cumsumZPbody(i,:)./cumMT / (ZAcm2(i)/area_in_cm2);
        
    end
    
    % total frames in each zone
    totalFramesZPnose = cumsumZPnose(:,end);
    totalFramesZPbody = cumsumZPbody(:,end);
    % multiply to get time in each tzone
    totalTimeZPnose = totalFramesZPnose * deltaT;
    totalTimeZPbody = totalFramesZPbody * deltaT;
    % divide by area (for each zone)
    totalTimeZPnose_CM2 = totalTimeZPnose./ZAcm2';
    totalTimeZPbody_CM2 = totalTimeZPbody./ZAcm2';
    % normalize by the total number of good frames
    fractionTimeZPnose = totalFramesZPnose/total_good_frames;
    fractionTimeZPbody = totalFramesZPbody/total_good_frames;
    % get the enrichment for the zone at the last frame
    totalZnose_enrichment = cumZnose_enrichment(:,end);
    totalZbody_enrichment = cumZbody_enrichment(:,end);
    
    % This is a comparison among different zones
    for i = 1:length(totalFramesZPnose)
        for j = 1:length(totalFramesZPnose)
            % one is an index, one is a ratio
            %pairwise_zone_pref_index_nose(i,j) = (totalTimeZPnose(i) - totalTimeZPnose(j))/(totalTimeZPnose(i) + totalTimeZPnose(j));
            %pairwise_zone_pref_index_body(i,j) = (totalTimeZPbody(i) - totalTimeZPbody(j))/(totalTimeZPbody(i) + totalTimeZPbody(j));
            
            pairwise_zone_pref_index_nose(i,j) = (totalZnose_enrichment(i) - totalZnose_enrichment(j))/(totalZnose_enrichment(i) + totalZnose_enrichment(j));
            pairwise_zone_pref_index_body(i,j) = (totalZbody_enrichment(i) - totalZbody_enrichment(j))/(totalZbody_enrichment(i) + totalZbody_enrichment(j));
            
            
            % This is necessary to override zero divisions which lead to
            % NaNs and mess up the color code
            if i == j
                pairwise_zone_pref_index_nose(i,j) = 0;
                pairwise_zone_pref_index_body(i,j) = 0;
            end
            
            %             pairwise_zone_preference_ratio_nose(i,j) = totalZnose_enrichment(i)/totalZnose_enrichment(j);
            %             pairwise_zone_preference_ratio_body(i,j) = totalZbody_enrichment(i)/totalZbody_enrichment(j);
        end
    end
end % of if zones exist


if zones_exist
    % first do nose ...
    for zi = 1:length(zones)
        zone_visits{zi} = [];
        
        zone_transitions =     diff(allZPnose(zi,:));
        % the one is added because this is a diff operation
        zone_entries     = find(zone_transitions == 1)  + 1;
        zone_exits       = find(zone_transitions == -1) + 1;
        
        vi = 1;
        % make a list of all visits
        if ~isempty(zone_exits) && ~isempty(zone_entries)
            if zone_exits(1) < zone_entries(1)
                zone_visits{zi}(vi,:) = [1 zone_exits(1)] * deltaT;
                zone_exits(1) = [];
                vi = vi + 1;
            end
        elseif ~isempty(zone_exits) && isempty(zone_entries) % if we have only one exit and no entries
            zone_visits{zi}(vi,:) = [1 zone_exits(1)] * deltaT;
            zone_exits(1) = [];
            vi = vi + 1;
        end
        
        if ~isempty(zone_entries)
            for eni = 1:length(zone_entries)
                this_start = zone_entries(eni);
                % we look for the first exit that is larger than this entry
                % by design, there should be not additional entries before this
                % exit
                minind     = min(find(zone_exits > zone_entries(eni)));
                if isempty(minind) % if there is an entry without a subsequent exit
                    this_end = size(allZPnose(zi,:),2);
                else
                    this_end   = zone_exits(minind);
                end
                zone_visits{zi}(vi,:) = [this_start this_end] * deltaT;
                vi = vi + 1;
            end
        end
        zone_durations{zi} = diff(zone_visits{zi},[],2);
    end % end of nose
    nose_zone_visits    = zone_visits;
    nose_zone_durations = zone_durations;
    clear zone_visits zone_durations
    
    % then do body - the difference is only in the first line within the
    % loop
    for zi = 1:length(zones)
        
        zone_visits{zi} = [];
        
        zone_transitions =     diff(allZPbody(zi,:));
        % the one is added because this is a diff operation
        zone_entries     = find(zone_transitions == 1)  + 1;
        zone_exits       = find(zone_transitions == -1) + 1;
        
        vi = 1;
        % make a list of all visits
        if ~isempty(zone_exits) && ~isempty(zone_entries)
            if zone_exits(1) < zone_entries(1)
                zone_visits{zi}(vi,:) = [1 zone_exits(1)] * deltaT;
                zone_exits(1) = [];
                vi = vi + 1;
            end
        elseif ~isempty(zone_exits) && isempty(zone_entries) % if we have only one exit and no entries
            zone_visits{zi}(vi,:) = [1 zone_exits(1)] * deltaT;
            zone_exits(1) = [];
            vi = vi + 1;
        end
        
        if ~isempty(zone_entries)
            for eni = 1:length(zone_entries)
                this_start = zone_entries(eni);
                % we look for the first exit that is larger than this entry
                % by design, there should be not additional entries before this
                % exit
                minind     = min(find(zone_exits > zone_entries(eni)));
                if isempty(minind) % if there is an entry without a subsequent exit
                    this_end = size(allZPnose(zi,:),2);
                else
                    this_end   = zone_exits(minind);
                end
                zone_visits{zi}(vi,:) = [this_start this_end] * deltaT;
                vi = vi + 1;
            end
        end
        zone_durations{zi} = diff(zone_visits{zi},[],2);
    end % end of body
    body_zone_visits    = zone_visits;
    body_zone_durations = zone_durations;
    clear zone_visits zone_durations
end

if do_zone_time_stats && zones_exist
    if length(zones) > size(zone_colors,1)
        disp(['cannot plot results for more than ' num2str(size(zone_colors,1)) ' zones']);
    else
        
        [r,c] = get_best_subpplot_dims(length(zones));
        
        if show_nose
            figure
            set(gcf,'numbertitle','off')
            set(gcf,'name',['zone visit statistics for nose ' info_str]);
            ymax = 0;
            xmax = 0;
            for zi = 1:length(zones)
                sh(zi) = subplot(r,c,zi);
                if ~isempty(nose_zone_durations{zi})
                    bh = bar(sort(nose_zone_durations{zi},1,'descend'));
                    set(bh,'facecolor',zone_colors(zi,:))
                    set(bh,'edgecolor','none')
                    ymax = max([ymax,max(get(gca,'YLim'))]);
                    xmax = max([xmax,max(get(gca,'XLim'))]);
                    ylabel('time (sec)')
                    xlabel('visit # (sorted)')
                else
                    set(gca,'YTick',[],'YTickLabel',[]);
                end
                box on
                titstr = [zone_names{zi} ' # segments: ' num2str(length(nose_zone_durations{zi})) ' mean duration nose: ' num2str(mean(nose_zone_durations{zi}),'%.1f') ' s'];
                title(titstr)
                % axis tight
                set(gca,'XTick',[])                
            end
        end
        
        if show_body
            figure
            set(gcf,'numbertitle','off')
            set(gcf,'name',['zone visit statistics for body ' info_str]);
            ymax = 0;
            xmax = 0;
            for zi = 1:length(zones)
                sh(zi) = subplot(r,c,zi);
                if ~isempty(body_zone_durations{zi})
                    bh = bar(sort(body_zone_durations{zi},1,'descend'));
                    set(bh,'facecolor',zone_colors(zi,:))
                    set(bh,'edgecolor','none')
                    ymax = max([ymax,max(get(gca,'YLim'))]);
                    xmax = max([xmax,max(get(gca,'XLim'))]);
                    ylabel('time (sec)')
                    xlabel('visit # (sorted)')
                else
                    set(gca,'YTick',[],'YTickLabel',[]);
                end                                        
                box on
                titstr = [zone_names{zi} ' # segments: ' num2str(length(body_zone_durations{zi})) ' mean duration body: ' num2str(mean(body_zone_durations{zi}),'%.1f') ' s'];
                title(titstr)
                % axis tight
                set(gca,'XTick',[])               
            end
        end
    end
end


%% calculate speed and plot it if requested
% for smoothing speed profile
smooth_win_sec = str2num(handles.smooth_window_seconds_edit.String);
if isempty(smooth_win_sec)
    smooth_win_sec = 1;
    errordlg(['illegal - smoothing window value. Setting default value of 1'])
end

smooth_points  = floor(smooth_win_sec/deltaT);
smoothed_speed = smooth(delta_body_cm_s,smooth_points,'moving');
% set points that were originally nans to nans
% The smooth function somehow deals with NaN values
smoothed_speed(isnan(delta_body_cm_s)) = nan;

mean_body_speed = nanmean(delta_body_cm_s);
median_body_speed = nanmedian(delta_body_cm_s);
std_body_speed  =  nanstd(delta_body_cm_s);


if do_speed
    % parameters for velocity histogram
    SpeedRes = str2num(handles.speed_histogram_resolution.String);
    if isempty(SpeedRes)
        SpeedRes = 1;
        errordlg(['illegal - speed resolution value. Setting default value of 1'])
    end
    MaxSpeed = str2num(handles.max_speed_edit.String);
    if isempty(MaxSpeed)
        MaxSpeed = 30;
        errordlg(['illegal - MaxSpeed value. Setting default value of 30'])
    end
    
    figure
    set(gcf,'numbertitle','off')
    set(gcf,'name',['body speed ' info_str]);
    axes('position',[0.1 0.1 0.59 0.8])
    plot(frame_times,smoothed_speed)
    set(gca,'ylim',[0 MaxSpeed+5])
    set(gca,'xlim',[0 frame_times(end)])
    xlabel('time - seconds')
    ylabel('cm/second')
    title('smoothed speed as a function of time')
    
    velspeedhistaxes = axes('position',[0.7 0.1 0.28 0.8]);
    %hist(delta_body_cm_s,[0:SpeedRes:MaxSpeed]);
    hist(smoothed_speed,[0:SpeedRes:MaxSpeed]);
    set(gca,'xlim',[0 MaxSpeed+5],'XTick',[])
    title(['body speed, median: ' num2str(median_body_speed) ' cm/s'])
    %xlabel('cm/second')
    ylabel('n frames')
    view(-90, 90) %
    set(gca, 'ydir', 'reverse');
end


%% show distance travelled
if do_distance
    figure
    set(gcf,'numbertitle','off')
    set(gcf,'name',['distance travelled ' info_str]);
    plot(frame_times,cms_travelled)
    set(gca,'ylim',[0 cms_travelled(end)*1.01]);
    set(gca,'xlim',[0 frame_times(end)])
    xlabel('time - seconds')
    ylabel('cm')
    title(['Distance travelled as a function of time. Total: ' num2str(cms_travelled(end),'%.2f') ' cm'])
end


%% plot summary of time spent in each zone
if do_zone_pref_total && zones_exist
    
    if show_nose
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Nose zone preference summary ' info_str]);
        
        subplot(2,1,1)
        for i = 1:length(zone_names)
            bh = bar(i,totalTimeZPnose(i));
            set(bh,'facecolor',zone_colors(i,:))
            hold on
        end
        set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
        ylabel('time (s)');
        title(['Nose time in zone, (of ' num2str(round(TotalZoneTime),'%.1f')  ' s)'])
        
        %         subplot(3,1,2)
        %         for i = 1:length(zone_names)
        %             bh = bar(i,fractionTimeZPnose(i));
        %             set(bh,'facecolor',zone_colors(i,:))
        %             hold on
        %         end
        %         set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
        %         title('Fraction of time of nose in zone')
        
        subplot(2,1,2)
        for i = 1:length(zone_names)
            bh = bar(i,totalZnose_enrichment(i));
            set(bh,'facecolor',zone_colors(i,:))
            hold on
        end
        line([0.5 length(zone_names)+0.5],[1  1],'color','k')
        set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
        ylabel('enrichment score');
        title('Total enrichment time of nose in zone')
    end
    
    if show_body
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Body zone preference summary ' info_str]);
        
        subplot(2,1,1)
        for i = 1:length(zone_names)
            bh = bar(i,totalTimeZPbody(i));
            set(bh,'facecolor',zone_colors(i,:))
            hold on
        end
        set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
        ylabel('time (s)');
        title(['Body time in zone, (of ' num2str(round(TotalZoneTime),'%.1f')  ' s)'])
        
        
        %         subplot(3,1,2)
        %         for i = 1:length(zone_names)
        %             bh = bar(i,fractionTimeZPbody(i));
        %             set(bh,'facecolor',zone_colors(i,:))
        %             hold on
        %         end
        %         set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
        %         title('Fraction of time of body in zone')
        
        subplot(2,1,2)
        for i = 1:length(zone_names)
            bh = bar(i,totalZbody_enrichment(i));
            set(bh,'facecolor',zone_colors(i,:))
            hold on
        end
        line([0.5 length(zone_names)+0.5],[1  1],'color','k')
        set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
        ylabel('enrichment score');
        title('Total enrichment time of body in zone')
    end
end


%% plot zone stats as a function of time
if do_zone_pref_cumulative && zones_exist
    if show_nose
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Zone preference of nose as a function of time ' info_str]);
        
        subplot(3,1,1)
        % run over each event
        for zi = 1:length(zones)
            % construct a vector of nans (all frames, including "bad ones")
            this_zone_times = nan(1,length(allZPnose(1,:)));
            % assign an integer value to frames that include the event
            this_zone_times(allZPnose(zi,:)) = zi;
            % plot then
            ph = plot(good_frame_times,this_zone_times,'.');
            set(ph,'color',zone_colors(zi,:))
            hold on
        end
        set(gca,'Ytick',[1:length(zones)]);
        set(gca,'YtickLabel',zone_names);
        set(gca,'YLim' ,[0 length(zones)+1]);
        set(gca,'xlim',[0 good_frame_times(end)])
        xlabel('time s');
        title('zone occupancy of nose as a function of time')
        
        subplot(3,1,2)
        % This is the expected number - which is the number of frames
        % normalized by the ratio between zone area and total area
        for i = 1:length(zone_names)
            ph = plot(good_frame_times,ZAcm2(i) * cumMTPC2);
            set(ph,'color',zone_colors(i,:))
            hold on
        end
        lh = legend(zone_names);
        set(lh,'Interpreter','none');
        set(gca,'TickLabelInterpreter','none')
        for i = 1:length(zone_names)
            ph = plot(good_frame_times,cumsumZPnose(i,:),'.');
            set(ph,'color',zone_colors(i,:))
        end
        
        axis tight
        set(gca,'XLim',[0 frame_times(end)])
        xlabel('time s');
        ylabel('n frames');
        title('cumulative frames of nose in zone')
        
        subplot(3,1,3)
        set(gca,'TickLabelInterpreter','none')
        for i = 1:length(zone_names)
            ph = plot(good_frame_times,cumZnose_enrichment(i,:),'.');
            set(ph,'color',zone_colors(i,:))
            hold on
        end
        line([0 frame_times(end)],[1 1],'color','k')
        axis tight
        set(gca,'XLim',[0 frame_times(end)])
        xlabel('time s');
        ylabel('enrichment score');
        title('cumulative enrichment of nose in zone')
    end
    
    if show_body
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Zone preference of body as a function of time ' info_str]);
        
        subplot(3,1,1)
        % run over each event
        for zi = 1:length(zones)
            % construct a vector of nans (all frames, including "bad ones")
            this_zone_times = nan(1,length(allZPbody(1,:)));
            % assign an integer value to frames that include the event
            this_zone_times(allZPbody(zi,:)) = zi;
            % plot then
            ph = plot(good_frame_times,this_zone_times,'.');
            set(ph,'color',zone_colors(zi,:))
            hold on
        end
        
        set(gca,'Ytick',[1:length(zones)]);
        set(gca,'YtickLabel',zone_names);
        set(gca,'YLim' ,[0 length(zones)+1]);
        set(gca,'xlim',[0 good_frame_times(end)])
        xlabel('time s');
        title('zone occupancy of body as a function of time')
        
        subplot(3,1,2)
        % This is the expected number - which is the number of frames
        % normalized by the ratio b etween zone area and total area
        for i = 1:length(zone_names)
            ph = plot(good_frame_times,ZAcm2(i) * cumMTPC2);
            set(ph,'color',zone_colors(i,:))
            hold on
        end
        lh = legend(zone_names);
        set(lh,'Interpreter','none');
        set(gca,'TickLabelInterpreter','none')
        for i = 1:length(zone_names)
            ph = plot(good_frame_times,cumsumZPbody(i,:),'.');
            set(ph,'color',zone_colors(i,:))
        end
        axis tight
        set(gca,'XLim',[0 frame_times(end)])
        xlabel('time s');
        ylabel('n frames');
        title('cumulative frames of body in zone')
        
        subplot(3,1,3)
        set(gca,'TickLabelInterpreter','none')
        for i = 1:length(zone_names)
            ph = plot(good_frame_times,cumZbody_enrichment(i,:),'.');
            set(ph,'color',zone_colors(i,:))
            hold on
        end
        line([0 frame_times(end)],[1 1],'color','k')
        
        axis tight
        set(gca,'XLim',[0 frame_times(end)])
        xlabel('time s');
        ylabel('enrichment score');
        title('cumulative enrichment of body in zone')
    end
end







%% plot histogram of head direction
% histograms of head direction - note that these angles have been
% potentially corrected
if do_angles
    good_angles = mouse_angles(good_frames);
    figure;
    set(gcf,'numbertitle','off')
    set(gcf,'name',['Head direction distributions ' info_str]);
    rose(good_angles,180);
    title('body angle histogram');
end

% This is a neat option, but I am not sure what it is good for ...
% figure
% plot3(good_nosePOS(:,1),good_nosePOS(:,2),[1:length(good_nosePOS)],'k.-');
% figure; plot3(good_bodyPOS(:,1),good_bodyPOS(:,2),[1:length(good_nosePOS)],'k.-');


%% plot nose and head positions over arena
if do_tracks
    
    if show_nose
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Mouse nose locations ' info_str]);
        ph = plot(good_nosePOS(:,1),good_nosePOS(:,2),'k.-');
        set(ph,'linewidth',0.1)
        hold on
        set(gca,'Ydir','reverse')
        axis equal
        axis tight
        ylabel('cm');
        xlabel('cm');
        title('nose positions')
        
        % plot nose positions in color
        for i = 1:length(zones)
            ph = plot(good_nosePOS(allZPnose(i,:),1),good_nosePOS(allZPnose(i,:),2),'.');
            set(ph,'color',zone_colors(i,:));
            set(ph,'markersize',2);
        end
        % plot polygons over arena
        for i = 1:length(ZV)
            poly_h = plot(ZV{i}(:,1),ZV{i}(:,2));
            set(poly_h,'color',zone_colors(i,:),'linewidth',2)
        end
        rescale_axes(gca,cm_per_pixel)
    end
    
    if show_body
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Mouse body locations ' info_str]);
        ph = plot(good_bodyPOS(:,1),good_bodyPOS(:,2),'k.-');
        set(ph,'linewidth',0.1)
        hold on
        set(gca,'Ydir','reverse')
        axis equal
        axis tight
        ylabel('cm');
        xlabel('cm');
        % plot body locations in color
        for i = 1:length(zones)
            ph = plot(good_bodyPOS(allZPbody(i,:),1),good_bodyPOS(allZPbody(i,:),2),'.');
            set(ph,'color',zone_colors(i,:));
            set(ph,'markersize',2);
        end
        % plot polygons over arena
        for i = 1:length(ZV)
            poly_h = plot(ZV{i}(:,1),ZV{i}(:,2));
            set(poly_h,'color',zone_colors(i,:),'linewidth',2)
        end
        title('body center positions')
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Mouse path ' pos_file_name])
        rescale_axes(gca,cm_per_pixel)
    end
end

%% plot heatmaps

if do_heat_map
    
    HIST_RES_MM = str2num(handles.heat_map_resolution_edit.String);
    if isempty(HIST_RES_MM)
        HIST_RES_MM = 2.5;
        errordlg(['illegal heat map resolution value. Setting default value of 2.5mm'])
    end
    HIST_RES_CM = HIST_RES_MM/10;
    
    IMAGE_SD_RANGE = str2num(handles.heat_map_std_range_edit.String);
    if isempty(IMAGE_SD_RANGE)
        IMAGE_SD_RANGE = 4;
        errordlg(['illegal heat map range. Setting default value of 4 stds'])
    end
    
    arena_size = size(pD.arena_data.MedianImage);
    
    hist_res_pixels = HIST_RES_CM*pixels_per_cm;
    x_edges = [0:hist_res_pixels:arena_size(2)];
    y_edges = [0:hist_res_pixels:arena_size(1)];
    x_cens = x_edges(1:end-1) + diff(x_edges(1:2));
    y_cens = y_edges(1:end-1) + diff(y_edges(1:2));
    
    
    if show_nose
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Nose position heat map ' info_str]);
        
        h = histogram2(good_nosePOS(:,1),good_nosePOS(:,2),x_edges,y_edges,'FaceColor','flat','DisplayStyle','tile','ShowEmptyBins','on');
        imagedata = flipud(rot90(h.Values));
        
        cla
        
        % clip the data in imagedata
        col_imagedata = imagedata(:);
        MV = mean(col_imagedata);
        SDV = std(col_imagedata);
        MAXVAL = MV + SDV*IMAGE_SD_RANGE;
        clipped_inds = col_imagedata > MAXVAL;
        total_clipped = sum(clipped_inds);
        col_imagedata(clipped_inds) = MAXVAL;
        imagedata = reshape(col_imagedata,size(imagedata));
        
        % spatial filtering is an option - this is a reminder of it
        % filtimagedata = imboxfilt(imagedata,2);
        % filtimagedata = imgaussfilt(imagedata,1);
        filtimagedata = imagedata;
        
        imagesc(filtimagedata,'XData',x_cens,'YData',y_cens);
        axis equal
        axis tight
        colormap hot
        colorbar
        ylabel('cm');
        xlabel('cm');
        title(['nose positions. resolution ' num2str(HIST_RES_MM) ' mm  | ' num2str(total_clipped) ' values > ' num2str(IMAGE_SD_RANGE) ' SDs clipped'])
        hold on
        % plot polygons over arena
        for i = 1:length(ZV)
            poly_h = plot(ZV{i}(:,1),ZV{i}(:,2));
            set(poly_h,'color',zone_colors(i,:),'linewidth',2)
        end
        rescale_axes(gca,cm_per_pixel)
    end
    
    if show_body
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Body position heat map ' info_str]);
        
        h = histogram2(good_bodyPOS(:,1),good_bodyPOS(:,2),x_edges,y_edges,'FaceColor','flat','DisplayStyle','tile','ShowEmptyBins','on');
        imagedata = flipud(rot90(h.Values));
        cla
        
        % clip the data in imagedata
        col_imagedata = imagedata(:);
        MV = mean(col_imagedata);
        SDV = std(col_imagedata);
        MAXVAL = MV + SDV*IMAGE_SD_RANGE;
        clipped_inds = col_imagedata > MAXVAL;
        total_clipped = sum(clipped_inds);
        col_imagedata(clipped_inds) = MAXVAL;
        imagedata = reshape(col_imagedata,size(imagedata));
        
        % spatial filtering is an option - this is a reminder of it
        %filtimagedata = imboxfilt(imagedata,2);
        %filtimagedata = imgaussfilt(imagedata,1);
        filtimagedata = imagedata;
        
        imagesc(filtimagedata,'XData',x_cens,'YData',y_cens);
        axis equal
        axis tight
        colormap hot
        colorbar
        ylabel('cm');
        xlabel('cm');
        title(['body positions. resolution ' num2str(HIST_RES_MM) ' mm  | ' num2str(total_clipped) ' values > ' num2str(IMAGE_SD_RANGE) ' SDs clipped'])
        hold on
        % plot polygons over arena
        for i = 1:length(ZV)
            poly_h = plot(ZV{i}(:,1),ZV{i}(:,2));
            set(poly_h,'color',zone_colors(i,:),'linewidth',2)
        end
        rescale_axes(gca,cm_per_pixel)
    end
    
end

%% compare zones
if do_compare_zones && zones_exist && length(zone_names) > 1
    % create a colormap
    cmap = redgreencmap(32);
    
    if show_nose
        figure;
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Zone comparisons - Nose ' info_str]);
        
        imagesc(pairwise_zone_pref_index_nose)
        set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'YTick',1:length(zone_names),'YTickLabel',zone_names,'XAxisLocation','bottom','TickLabelInterpreter','none','XTickLabelRotation',45)
        colorbar
        axis equal; axis tight
        title('nose preference index')
        colormap(cmap)
    end
    
    if show_body
        
        figure;
        set(gcf,'numbertitle','off')
        set(gcf,'name',['Zone comparisons Body' info_str]);
        
        imagesc(pairwise_zone_pref_index_body)
        set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'YTick',1:length(zone_names),'YTickLabel',zone_names,'XAxisLocation','bottom','TickLabelInterpreter','none','XTickLabelRotation',45)
        colorbar
        axis equal; axis tight
        title('body preference index')
        colormap(cmap)
    end
end

%% analyze events
%% plot nose and head positions over arena
if isfield(pD,'annotations')
    event_names = fieldnames(pD.annotations);
    % number of different events
    number_of_events = length(event_names);
    for ei = 1:length(event_names)
        eval(['event_inds{ei} = find(pD.annotations.' event_names{ei} ');']);
        % total number of event frames of each type
        n_event_frames(ei) = length(event_inds{ei});
        % a logical indicator - for some displays we ignore events that did not
        % occur
        take_event(ei) = ~isempty(event_inds{ei});
        % construct the label string
        label_string{ei} = [event_names{ei}  ' (' num2str(n_event_frames(ei)) ')'];
    end
    
    
    if do_general_event_stats
        % General event stats
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',[' event frequencies : ' info_str]);
        % show how many frames with each event
        bar(n_event_frames);
        set(gca,'Xtick',[1:number_of_events]);
        set(gca,'XtickLabel',label_string);
        set(gca,'XTickLabelRotation' ,45);
    end
    
    if do_events_as_function_of_time
        % plot events (and speed) as a function of time
        figure
        set(gcf,'numbertitle','off')
        set(gcf,'name',[' events as a function of time  : ' info_str]);
        ah1 = axes('position',[0.1300 0.5 0.7750 0.4]);
        % run over each event
        for ei = 1:number_of_events
            % construct a vector of nans (all frames, including "bad ones")
            this_event_times = nan(1,length(frame_times));
            % assign an integer value to frames that include the event
            this_event_times(event_inds{ei}) = ei;
            % plot then
            plot(frame_times,this_event_times,'.');
            hold on
        end
        set(gca,'Ytick',[1:number_of_events]);
        set(gca,'YtickLabel',label_string);
        set(gca,'XtickLabel','');
        set(gca,'YLim' ,[0 number_of_events+1]);
        set(gca,'xlim',[0 frame_times(end)])
        ylabel('EVENTS')
        title('EVENTS AND SPEED AS A FUNCTION OF TIME')
        % plot the speed as a function of time
        % We take the speed here again, because it may be that the user did not
        % select the speed analysis (and then we won't have checked the MaxSpeed)
        MaxSpeed = str2num(handles.max_speed_edit.String);
        if isempty(MaxSpeed)
            MaxSpeed = 30;
        end
        ah2 = axes('position',[0.13 0.15 0.7750 0.3]);
        plot(frame_times,smoothed_speed)
        set(gca,'ylim',[0 MaxSpeed+5])
        set(gca,'xlim',[0 frame_times(end)])
        xlabel('time - seconds')
        ylabel('speed (cm/second)')
    end
    
    % For the next analyses we only consider non-empty events
    event_inds = event_inds(take_event);
    event_names = event_names(take_event);
    
    % if we have zones and events
    % calculate frames in each zone - number and fraction
    if ~isempty(zone_names) && ~isempty(event_names)
        % events stats (of body) in zone
        % we ignore "empty" events
        for ei = 1:length(event_names)
            % for this analysis we only consider "good frames". That is, frames
            % with a non-NAN position, which means "good_frames"
            this_event_frames{ei} = intersect(event_inds{ei},find(good_frames));
            % plot nose positions in color
            for i = 1:length(zones)
                % the number of frames that are both in the zone and with the event
                N_this_event_in_this_zone(ei,i) = length(intersect(find(allZPbody(i,:)),this_event_frames{ei}));
                % the fraction of the total number of frames within the zone
                fraction_events_in_this_zone(ei,i) = N_this_event_in_this_zone(ei,i)/sum(allZPbody(i,:));
            end
        end
    end
    
    if do_events_as_function_of_zones && isempty(zone_names)
        warndlg('This analysis requires valid zones and non-empty events', 'EVENTS IN ZONES', 'modal');
    elseif do_events_as_function_of_zones && isempty(event_names)
        warndlg('This analysis requires valid zones and non-empty events', 'EVENTS IN ZONES', 'modal');
    elseif do_events_as_function_of_zones && ~isempty(zone_names)
        % events stats (of body) in zone
        % we ignore "empty" events
        for ei = 1:length(event_names)
            figure
            set(gcf,'numbertitle','off')
            set(gcf,'name',[event_names{ei} ' in zones ' info_str]);
            sh(1) = subplot(1,2,1);
            
            for i = 1:length(ZV)
                bh = bar(i,N_this_event_in_this_zone(ei,i));
                hold on
                set(bh,'facecolor',zone_colors(i,:));
            end
            
            set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
            title([event_names{ei} ' number of frames with body in zone'])
            sh(1) = subplot(1,2,2);
            for i = 1:length(ZV)
                bh = bar(i,fraction_events_in_this_zone(ei,i));
                hold on
                set(bh,'facecolor',zone_colors(i,:));
            end
            set(gca,'XTick',1:length(zone_names),'XTickLabel',zone_names,'TickLabelInterpreter','none','XTickLabelRotation',45,'XLim',[0 length(zone_names)+1])
            title([event_names{ei} ' fraction of frames with body in zone'])
        end
    end
    
    if do_events_as_function_of_position && isempty(event_names)
        warndlg('This analysis requires non-empty events', 'EVENTS IN POSITION', 'modal');
    elseif do_events_as_function_of_position
        % plot events as a function of position in arena
        % here too, we ignore "empty" events
        % Note that we are using thew nosePOS rather than the goodnosePOS
        % because the event_inds{ei} are defined for all frames
        % the same is true for the bodyPOS of course
        for ei = 1:length(event_names)
            figure
            set(gcf,'numbertitle','off')
            set(gcf,'name',[event_names{ei} ' events: ' info_str]);
            sh(1) = subplot(1,2,1);
            ph = plot(nosePOS(:,1),nosePOS(:,2),'k.');
            set(ph,'linewidth',0.1)
            hold on
            ph = plot(nosePOS(event_inds{ei},1),nosePOS(event_inds{ei},2),'r*');
            set(gca,'Ydir','reverse')
            axis equal
            axis tight
            ylabel('cm');
            xlabel('cm');
            title([event_names{ei} ' nose positions'])
            
            sh(2) = subplot(1,2,2);
            ph = plot(bodyPOS(:,1),bodyPOS(:,2),'k.');
            set(ph,'linewidth',0.1)
            hold on
            ph = plot(bodyPOS(event_inds{ei},1),bodyPOS(event_inds{ei},2),'r*');
            set(gca,'Ydir','reverse')
            axis equal
            axis tight
            ylabel('cm');
            xlabel('cm');
            
            sh(2).XLim = sh(1).XLim;
            sh(2).YLim = sh(1).YLim;
            title([event_names{ei} ' body center positions'])
            
            rescale_axes(sh(1),cm_per_pixel)
            rescale_axes(sh(2),cm_per_pixel)
        end
    end
else % of if there is an annotation field
    event_names = [];
end


%% get tags for current experiment
these_tags = [];
exp_tags = strsplit(handles.experiment_tags_edit.String);

% no need checking further if the edit box is empty
if ~isempty(exp_tags)
    user_dir = get_user_dir;
    
    % create a tag (keyword) file if it does not exist
    tag_file = [user_dir 'optimouse_experiment_tags.txt'];
    
    % read the tags in the text file
    fileID = fopen(tag_file,'r');
    C = textscan(fileID,'%s');
    fclose(fileID);
    valid_tags = C{1};
    
    % check which edit box tags are in the tag file
    % and if they are, add them to the list
    k = 1;
    for i = 1:length(exp_tags)
        if ismember(exp_tags{i},valid_tags)
            these_tags{k} = exp_tags{i};
            k = k + 1;
        end
    end
end


%% save the result in a MAT file
if save_as_mat
    % if also required to save zones
    if handles.save_zones_checkbox.Value
        % for saving zones
        contents = cellstr(get(handles.arena_folder_listbox,'String'));
        position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];
        [~,pos_file_name,~] = fileparts(position_file);
        zonefilename = [pos_file_name '_zones'];
        save_zone_file(handles,zonefilename);
    end
    
    Res.cms_travelled = cms_travelled;
    Res.total_cms_travelled = cms_travelled(end);
    Res.experiment_tags = these_tags;
    Res.deltaT                = deltaT;
    Res.delta_body_cm_s        = delta_body_cm_s;
    Res.good_frames            = good_frames;
    Res.mean_body_speed        = mean_body_speed ;
    Res.median_body_speed      = median_body_speed;
    Res.pD                     = pD;
    Res.position_file          = position_file;
    Res.smooth_points          = smooth_points;
    Res.smooth_win_sec         = smooth_win_sec;
    Res.smoothed_speed         = smoothed_speed;
    Res.std_body_speed         = std_body_speed;
    Res.frame_times            = frame_times ;
    Res.good_frame_times       = good_frame_times;
    
    if ~isempty(event_names)
        Res.event_names = event_names;
        Res.event_inds     = event_inds; % Indices of frames associated withe ach event
    end
    
    if ~isempty(event_names) && zones_exist
        % number of frames for each event (first dimension), in each zone (second dimension)
        Res.N_this_event_in_this_zone = N_this_event_in_this_zone;
        % fraction of frames for each event (first dimension), in each zone (second dimension)
        Res.fraction_events_in_this_zone = fraction_events_in_this_zone;
    end
    
    if zones_exist
        Res.nose_zone_visits     = nose_zone_visits;
        Res.nose_zone_durations  = nose_zone_durations;
        Res.body_zone_visits     = body_zone_visits;
        Res.body_zone_durations  = body_zone_durations;
        Res.ZAcm2 = ZAcm2;
        Res.ZV  = ZV;
        Res.allZPbody = allZPbody;
        Res.allZPnose = allZPnose;
        Res.cumZbody_enrichment = cumZbody_enrichment;
        Res.cumZnose_enrichment = cumZnose_enrichment;
        Res.cumsumZPbody         = cumsumZPbody;
        Res.cumsumZPnose          = cumsumZPnose;
        Res.zone_names           = zone_names;
        Res.totalFramesZPnose = totalFramesZPnose;
        Res.totalFramesZPbody = totalFramesZPbody;
        Res.totalTimeZPnose = totalTimeZPnose;
        Res.totalTimeZPbody = totalTimeZPbody;
        Res.totalTimeZPnose_CM2 = totalTimeZPnose_CM2;
        Res.totalTimeZPbody_CM2 = totalTimeZPbody_CM2;
        Res.fractionTimeZPnose = fractionTimeZPnose;
        Res.fractionTimeZPbody = fractionTimeZPbody;
        Res.totalZnose_enrichment = totalZnose_enrichment;
        Res.totalZbody_enrichment = totalZbody_enrichment;
        Res.pairwise_zone_pref_index_nose = pairwise_zone_pref_index_nose;
        Res.pairwise_zone_pref_index_body = pairwise_zone_pref_index_body;
    end
    
    result_dir = [handles.video_dir_text.String filesep 'results'];
    if ~exist(result_dir,'dir')
        mkdir(result_dir)
    end
    [~,F,~] = fileparts(position_file);
    tmpind  =  findstr('_positions',F);
    base_name = F(1:tmpind);
    
    fn = 1;
    file_name_ok = 0;
    while ~file_name_ok
        result_file_name = [result_dir filesep base_name 'result_' num2str(fn) '.mat'];
        if ~exist(result_file_name,'file')
            file_name_ok = 1;
        end
        fn = fn + 1;
    end
    
    [FileName,PathName,~] = uiputfile('*.mat','select file to save results',result_file_name);
    if FileName
        save([PathName FileName],'Res');
    end
end



%% display results in command prompt
if do_show_results_on_prompt
    disp('analysis results for file: ')
    disp(position_file)
    disp('---')
    disp(['total time: ' num2str(TotalTime) ' secs'])
    disp(['number of original frames: ' num2str(TotalFrames)])
    disp(['number of valid frames: ' num2str(sum(good_frames))])
    disp(['average speed: ' num2str(mean_body_speed) ' cm/s'])
    disp(['median speed: ' num2str(median_body_speed) ' cm/s'])
    disp(['distance travelled: ' num2str(cms_travelled(end)) ' cm'])
    
    if zones_exist
        disp(['number of zones: ' num2str(length(zone_names))])
        for i = 1:length(zone_names)
            disp('---')
            disp(['zone ' num2str(i) ' name: ' zone_names{i}])
            disp(['zone ' num2str(i) ' area: ' num2str(ZAcm2(i)) ' cm2'])
            disp(['nose: total time in zone: ' num2str(totalTimeZPnose(i))])
            disp(['nose: fraction of time in zone: ' num2str(fractionTimeZPnose(i))])
            disp(['nose: enrichment time in zone: '  num2str(totalZnose_enrichment(i))])
            disp(['body: total time in zone: ' num2str(totalTimeZPbody(i))])
            disp(['body: fraction of time in zone: ' num2str(fractionTimeZPbody(i))])
            disp(['body: enrichment time in zone: '  num2str(totalZbody_enrichment(i))])
        end
        disp('---')
        disp('pairwise zone preference index for nose:')
        disp(pairwise_zone_pref_index_nose)
        disp('pairwise zone preference index for body:')
        disp(pairwise_zone_pref_index_body)
    end
end
