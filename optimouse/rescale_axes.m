function rescale_axes(axis_handle,CF)
% rescale xticklabels - from say pixels to mm, whatever is in CF
% YBS 9/16

for xi = 1:length(axis_handle.XTick)
    newXticklabels{xi} = num2str(round(axis_handle.XTick(xi)*CF));
end

for yi = 1:length(axis_handle.YTick)
    newYticklabels{yi} = num2str(round(axis_handle.YTick(yi)*CF));
end

axis_handle.XTickLabel = newXticklabels;
axis_handle.YTickLabel = newYticklabels;
