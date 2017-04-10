function [r,c] = get_best_subpplot_dims(N)
% YBS - written a long time ago...

switch N
    case 1
        r = 1;
        c = 1;
    case 2
        r = 2;
        c = 1;
    case 3
        r = 3;
        c = 1;
    case 4
        r = 2;
        c = 2;
    case {5,6}
        r = 2;
        c = 3;
    case {7,8}
        r = 2;
        c = 4;
    case 9
        r = 3;
        c = 3;
    case {10,11,12}
        r = 3;
        c = 4;
    case {13,14,15}
        r = 3;
        c = 5;
    case {16,17,18,19,20}
        r = 4;
        c = 5;
    case {21,22,23,24,25}
        r = 5;
        c = 5;
    case {26,27,28,29,30}
        r = 5;
        c = 6;
    case {31,32,33,34,35,36}        
        r = 6;
        c = 6;
    case {37,38,39,40,41,42}        
        r = 6;
        c = 7;        
    case {43,44,45,46,47,48,49}        
        r = 7;
        c = 7;
    case {50,51,52,53,54,55,56}        
        r = 7;
        c = 8;
    case {57,58,59,60,61,62,63,64} 
        r = 8;
        c = 8;        
    case {65,66,67,68,69,70} 
        r = 7;
        c = 10;
    case {71,72,73,74,75,76,77,78,79,80}
        r = 8;
        c = 10;
    case {81,82,83,84,85,86,87,88,89,90}
        r = 9;
        c = 10;
    otherwise
        r = 10;
        c = 10;
end


      