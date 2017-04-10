function Method = determine_contrast_method(Image)
% Based on ANkur's original function, but heavily modified
% This approach is based ont he mean rather than on the range
% The method i determined by noting whether the mean is closer to the min
% (in which case the mouse is white) or the mean is closer to the
% max in which case the mouse is dark
% YBS 9/16
minv = min(Image(:));
maxv = max(Image(:));
medv = median(Image(:));
[~,Method] = min([medv-minv,maxv-medv]);
