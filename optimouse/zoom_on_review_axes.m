function zoom_on_review_axes(ZoomAxis)
% does just what it says it does
% YBS 9/16

% see if there is another rect object, and if so, delete it
prev_rect = findobj('tag','zoom_rect');
if ~isempty(prev_rect)
    delete(prev_rect)
end

% define a polygon and get its location
h = imrect(ZoomAxis);
set(h,'tag','zoom_rect');

if isempty(h)
    return
end

p = wait(h);
delete(h);
if isempty(p)
    return
end
% if the width or the height zero
if ~prod(p([3:4]))
    return
end

set(ZoomAxis,'XLim',[p(1) p(1)+p(3)],'YLim',[p(2) p(2)+p(4)]);
ZoomAxis.XTickLabel = [];
ZoomAxis.YTickLabel = [];
