function populate_video_file_list(handles)
% Executed when the string filter is used
% populate the list of video files in the define arenas interface
% More supported types can be added here as additional entries (i.e. D5 = ...)
% YBS 9/16

D1 = dir([handles.video_dir_text.String filesep '*.mp4']);
D2 = dir([handles.video_dir_text.String filesep '*.wmv']);
D3 = dir([handles.video_dir_text.String filesep '*.mpg']);
D4 = dir([handles.video_dir_text.String filesep '*.avi']);
D = [D1;D2;D3;D4];
video_files = {D.name};

if isempty(video_files)
    handles.video_file_listbox.Value = 1;
    handles.video_file_listbox.String = [];
    % handles.video_dir_text.Value = 1;  
    return
end

pattern = handles.file_name_filter_edit.String;

if ~isempty(pattern)
    pat_match = strfind(video_files, pattern);
    take_files = [];
    for i = 1:length(pat_match)
        if ~isempty(pat_match{i})
            take_files = [take_files i];
        end
    end
else
    take_files = 1:length(video_files);
end

video_files = video_files(take_files);
handles.video_file_listbox.Value = 1;
handles.video_file_listbox.String = video_files;
