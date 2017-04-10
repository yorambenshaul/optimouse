function Result = user_defined_detect_func_4(ThisFrame)
% example of a user defined detection function without custom parameters
% and with random position detection
% Returns a random mouse position, and nothing else

[Ydim Xdim] = size(ThisFrame);

% based on get_mouse_position
Result.mouseCOM = [unidrnd(Xdim) unidrnd(Ydim)];
Result.nosePOS  = [unidrnd(Xdim) unidrnd(Ydim)];
