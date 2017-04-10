function user_dir = get_user_dir
% return directory with user definitions - which is parallel to that of the
% main optimouse directory

a = which('optimouse');
if ~isempty(a)
    [P,~,~] =  fileparts(a);
    fileseps = regexp(P,filesep);    
    user_dir = [P(1:fileseps(end)) 'optimouse_user_definitions' filesep];    
else
    user_dir = [];
end




