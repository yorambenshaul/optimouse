function save_zone_file(handles,zonefilename)
% save zone files, for the zone analysis interface
% YBS 10/16

saved_zones= handles.zones;

if isempty(saved_zones)
    return
end

saved_zones = rmfield(saved_zones,'handle');

contents = cellstr(get(handles.arena_folder_listbox,'String'));
position_file = [handles.video_dir_text.String filesep 'positions' filesep contents{get(handles.arena_folder_listbox,'Value')}];

pD = load(position_file);
arena_data = pD.arena_data;

for i = 1:length(saved_zones)
    saved_zones(i).positions = getPosition(handles.zones(i).handle);
end

zone_dir = [handles.video_dir_text.String filesep 'zones'];
if ~exist(zone_dir,'dir')
    mkdir(zone_dir)
end

% if no file name was supplied - this is when the save zones button is
% called
if ~exist('zonefilename')    
    [~,F,~] = fileparts(position_file);
    tmpind  =  findstr('_positions',F);
    base_name = F(1:tmpind);
    
    fn = 1;
    file_name_ok = 0;
    while ~file_name_ok
        zone_file_name = [zone_dir filesep base_name 'zones_' num2str(fn) '.mat'];
        if ~exist(zone_file_name,'file')
            file_name_ok = 1;
        end
        fn = fn + 1;
    end
    
    [selected_zone_file_name, selected_zone_path] = uiputfile(zone_file_name,'save Zone file');
    if ~selected_zone_file_name
        return
    end
    full_zone_file_name = [selected_zone_path  selected_zone_file_name];
    save(full_zone_file_name,'arena_data','saved_zones');
    % msgbox(['zones saved in ' full_zone_file_name ],'Analyze Behavior')
else % if zonefilename exists - it must be a valid name
    full_zone_file_name = [zone_dir filesep zonefilename '.mat'];
    save(full_zone_file_name,'arena_data','saved_zones');
    msgbox(['zones saved in ' full_zone_file_name ],'Analyze Behavior')
end