function update_frame_for_arena_definition(hObject,handles)
% Used by the define arenas GUI to update frame 
% YBS 9/16

UD = handles.UD;

switch hObject.Tag
    case {'current_frame_edit','current_time_edit'                }
        frame_num = str2num(handles.current_frame_edit.String);
    case 'current_frame_slider'        
        frame_num = hObject.Value;        
end

if isempty(frame_num)
    frame_num = 1;    
end
if rem(frame_num,1)
    frame_num = round(frame_num);
end
if frame_num < 1
    frame_num = 1;
end
% This is because the read function does not work for the last 1 or 2
% frames and here I took some extra precaution
if frame_num > UD.nframes-5;    
    frame_num = UD.nframes-5;
end

frame_str = num2str(frame_num);

handles.current_frame_edit.String = frame_str;            
handles.current_frame_slider.Value = frame_num;

axes(handles.original_video_axes);
delete(UD.current_image_h);
new_image_h = image(read(UD.vobj,frame_num));
uistack(new_image_h,'bottom')
UD.current_image_h = new_image_h;

curtime = frame_num * UD.SR;
totaltime = UD.Duration;

info_str{1} = ['Frame: ' num2str(frame_num) ' of ' num2str(UD.nframes) ];
info_str{2} = [num2str(curtime,'%.2f') ' secs of ' num2str(totaltime,'%.2f')];

handles.define_arena_fig_text.String = info_str; 

% we can assume that the frame value is valid now
handles.current_time_edit.String =  num2str(curtime,'%.2f');



handles.UD = UD;
guidata(hObject,handles);

return

