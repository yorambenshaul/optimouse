function new_obj = trim_object_periphery(orig_obj)
% remove the periphery of all objects in BW image
% This version will make sure that only one object is returned
% (otherwise it could be split into two)
% YBS April 2016


new_obj = logical(orig_obj - bwperim(orig_obj,8));

CC = bwconncomp(new_obj);

if CC.NumObjects >1
    
    new_obj(:) = 0;
    
    % Get the one with the largest area
    STATS=regionprops(CC,'Area','PixelIdxList');
    
    areas = [STATS.Area];
    [~,largest_object_ind] = max(areas);
    
    new_obj(STATS(largest_object_ind).PixelIdxList) = 1;
end


