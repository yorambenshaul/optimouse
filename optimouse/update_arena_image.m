function update_arena_image(hObject,handles,fn)
% update image from arena definition interface
% YBS 9/16

contents = cellstr(get(handles.video_file_listbox,'String')); 
vidfilename = [handles.video_dir_text.String filesep contents{get(handles.video_file_listbox,'Value')}];

VideoObj=VideoReader(vidfilename);
axes(handles.main_video_axes);

Frame = read(VideoObj,fn);
% Clear previous image
prev_image = findobj(gca,'type','Image');
if ~isempty(prev_image)
    delete(prev_image)
end

arena_image_h = imagesc(Frame);
axis equal;
axis tight
uistack(arena_image_h,'bottom')

SR =  handles.SR;
data =   handles.data;
frame_time = SR*fn;     
info_str{1} = ['Frame ' num2str(fn) ' of ' num2str(data.Nframes)];
info_str{2} = [num2str(frame_time,'%.2f') ' of ' num2str(data.duration,'%.2f') ' seconds'];

handles.current_frame_info_text.String = info_str;
guidata(hObject, handles);