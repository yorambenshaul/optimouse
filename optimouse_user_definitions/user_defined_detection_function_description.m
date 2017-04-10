function user_detection_functions = user_defined_detection_function_description
% all functions listed here are intended for demonstrating the concept of
% user defined functions.

% a funciton with definition of user defined functions for detection
user_detection_functions = [];
% 

% based on get_mouse_position_mm, with two parameters to modify positions.
user_detection_functions(1).runstring = 'Result = user_defined_detect_func_1(ThisFrame,trim_cycles,GreyThresh_fact,shift1,shift2);';
user_detection_functions(1).name = 'user_func 1';
user_detection_functions(1).param_names{1} = 'shift1';
user_detection_functions(1).param_range{1} = [-10 10];
user_detection_functions(1).param_names{2} = 'shift2';
user_detection_functions(1).param_range{2} = [-10 10];

% based on get_mouse_position_mm, with three parameters to modify positions.
user_detection_functions(2).runstring = 'Result = user_defined_detect_func_2(ThisFrame,trim_cycles,GreyThresh_fact,shift1,shift2,shift3);';
user_detection_functions(2).name = 'user func 2';
user_detection_functions(2).param_names{1} = 'shift1';
user_detection_functions(2).param_range{1} = [-10 10];
user_detection_functions(2).param_names{2} = 'shift2';
user_detection_functions(2).param_range{2} = [-10 10];
user_detection_functions(2).param_names{3} = 'shift3';
user_detection_functions(2).param_range{3} = [0 20];

% based on get_mouse_position_mm, with 5 parameters to modify positions.
user_detection_functions(3).runstring = 'Result = user_defined_detect_func_3(ThisFrame,trim_cycles,GreyThresh_fact,shift1,shift2,param3,myparam4,P5);';
user_detection_functions(3).name = 'silly algorithm';
user_detection_functions(3).param_names{1} = 'shift1';
user_detection_functions(3).param_range{1} = [0 10];
user_detection_functions(3).param_names{2} = 'shift2';
user_detection_functions(3).param_range{2} = [10 50];
user_detection_functions(3).param_names{3} = 'param3';
user_detection_functions(3).param_range{3} = [-10 10];
user_detection_functions(3).param_names{4} = 'myparam4';
user_detection_functions(3).param_range{4} = [13 10];
user_detection_functions(3).param_names{5} = 'P5';
user_detection_functions(3).param_range{5} = [-10 14];

% This function returns a random position, it demonstrates the minimal
% required output and completely nonsensical detection
user_detection_functions(4).runstring = 'Result = user_defined_detect_func_4(ThisFrame);';
user_detection_functions(4).name = 'random position';

