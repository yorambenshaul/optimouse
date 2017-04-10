function toggle_pixels_mm_during_arena_definition(handles)
% Toggle display between mm and pixels
% This only applies to the axes of the main image in the define arenas
% interface, not to the individual edit boxes which will remain in mm.
% YBS 9/16


% get conversion factor
UD = handles.UD;
pixels_per_mm = UD.pixels_per_mm ;

if handles.mm_radiobutton.Value  
        CF =  1/pixels_per_mm;
        rescale_axes(handles.original_video_axes,CF);
        xlabel('mm')
        ylabel('mm')
elseif handles.pixels_radiobutton.Value              
        rescale_axes(handles.original_video_axes,1)        
        xlabel('pixels')
        ylabel('pixels')
end

