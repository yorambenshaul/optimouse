function ok = check_frametime_string(inputstr,minval,maxval)
% like check_framnum_string, but no requirement for being an integer
% YBS 9/16

ok = 0; % guilty unless proven innocent

% check that it is numeric
val = str2num(inputstr);
if ~(length(val) == 1)
    return
end

% check that it is in the right range
if ~(val>=minval && val<=maxval)
    return
end

% if all is ok, then it is 1
ok = 1;