function Result = user_defined_detect_func_2(imageIn,trim_cycles,GreyThresh_fact,P1,P2,P3)
% example of a user defined detection function with 3 custom parameters
% imposing a shift on detected positions
% user_detection_functions(2).runstring = 'Result = user_defined_detect_func_2(MedianRemovedImage,trim_cycles,GreyThresh_fact,P1,P2,P3);';
head_method = 5;


% based on get_mouse_position
Result.mouseCOM = [nan nan];
Result.nosePOS  = [nan nan];
Result.GreyThresh = 0;
Result.TrimFact =  nan;
Result.BB =         [];
Result.MouseArea = nan;
Result.MousePerim = nan;
Result.ThinMousePerim = nan;
Result.PerimInds = [];
Result.tailCOM = [nan nan];
Result.thinmouseCOM = [nan nan];
Result.tailbasePOS = [nan nan];
Result.tailendPOS = [nan nan];
Result.BackGroundMedian = nan;
Result.BackGroundMean = nan;
Result.ErrorMsg = [];

% Generate a binary (BW) image after determining threshold and thresholding
GreyThresh = min(graythresh(imageIn) * GreyThresh_fact,1);
BW = im2bw(imageIn, GreyThresh);

% Find connected components within BW image and get some stats
CC = bwconncomp(BW) ;

STATS=regionprops(CC,'Area','BoundingBox','Centroid','PixelList','Perimeter');

% If no objects are identified then return
if isempty(STATS)    
    Result.ErrorMsg = 'not even one object was found';
    return
end

% Find the largest object - this is the mouse.
areas = [STATS.Area];
[~,largest_object_ind] = max(areas);

% Get properties of the largest object
BB = STATS(largest_object_ind).BoundingBox;

% If detected object is the entire frame - which can occur without a
% background in some bad cases.
if prod(BB(3:4)) == numel(imageIn)
    Result.ErrorMsg = 'detected object is the entire image';
    return
end

% mouse center of mass (relative to the entire image)
mouseCOM=[STATS(largest_object_ind).Centroid];

% clip the region containing the mouse from the entire image
mousepxls   =[STATS(largest_object_ind).PixelList];
MouseArea  = STATS(largest_object_ind).Area;
MousePerim = STATS(largest_object_ind).Perimeter;

% Get the values of the box around the mouse
% indices of the mouse in original image
% Added 28.8.16
mouselinearindex = sub2ind(size(imageIn), mousepxls(:,2), mousepxls(:,1));
% turn it into a double so we can use NaNs and then make all mouse pixels
% into NANS
tempimage = double(imageIn);
tempimage(mouselinearindex) = nan; 
% Select the box containing the mouse
clipped_region = tempimage([round(BB(2)):round(BB(2))+floor(BB(4))-1],[round(BB(1)):round(BB(1))+floor(BB(3))-1]);
% calcualte the median and mean, of the background
Result.BackGroundMedian = nanmedian(tempimage(:));
Result.BackGroundMean = nanmean(tempimage(:));
% If you want to see the nan pixels, just for checking
% figure; imagesc(isnan(clipped_region));
% colormap gray
% axis equal

%MouseArea = size(mousepxls,1);
rel_mousepxls(:,1) = mousepxls(:,1) - floor(BB(1));
rel_mousepxls(:,2) = mousepxls(:,2) - floor(BB(2));
mouse = zeros(BB(4),BB(3));
linearindex = sub2ind(size(mouse), rel_mousepxls(:,2), rel_mousepxls(:,1));
mouse(linearindex) = 1;

% Until here, the only things that mattered were the properties of the image
% But now the trim cycles play a role
% -------------------------

% Here we distinguish the tail from the rest of the mouse
% The assumption is that the tail is the thinnest part of the mouse
orig_mouse = mouse;
% Repeatedly "peel" the mouse until only the body remains
for i = 1:trim_cycles
    thin_mouse = trim_object_periphery(mouse);
    mouse = thin_mouse;
end

% boundary will contain pixels that define the boundary of the original mouse
[B,~] = bwboundaries(orig_mouse,8,'noholes');
orig_boundary = B{1};

% Get thinned (tailless) mouse properties
thinmouseCC = bwconncomp(thin_mouse) ;
% If a thin mouse not found
if ~thinmouseCC.NumObjects    
    Result.ErrorMsg = 'no thinned objects found';
    return
end
% Thin mouse center of mass - including the thin mouse boundaing box and
% center of mass
thinmouseSTATS=[regionprops(thinmouseCC,'Centroid','BoundingBox','Perimeter')];
thinmouseCOM=[thinmouseSTATS.Centroid];
thinBB = thinmouseSTATS.BoundingBox;
ThinMousePerim = thinmouseSTATS.Perimeter;

% Trim factor is the ratio of the extent of the original mouse
% to the tailless mouse. It is a measure of the effectiveness of trimming
% first we claculate the length, and then we measure the ratio to the
% distance along the same dimension after trimming
[eb,ei] = max(BB(3:4));
ea = thinBB(ei+2); % The indexing ensures that the same dimensions are used for both before and ftaer
TrimFact = eb/ea;
%TrimFact = max(BB(3:4))/max(thinBB(3:4));

% derive "tail" which is the difference between the original mouse and the
% thin mouse. Note that this is not only the tail, but everything that was
% thinned. Nevertheless, its center of mass is influenced by the tail.
tail = orig_mouse - thin_mouse;

% get tail stats
tailCC = bwconncomp(tail) ;
% make sure a single object is found ...  otherwise, trouble will ensue
if ~(tailCC.NumObjects == 1)
    if tailCC.NumObjects > 1
        Result.ErrorMsg = 'multiple objects found in tail';
    elseif tailCC.NumObjects < 1
        Result.ErrorMsg = 'no objects found in tail';
    end
    return
end
tailSTATS=[regionprops(tailCC,'Centroid')];
tailCOM=[tailSTATS.Centroid];

% find distance of all boundary points from tail
x_distfromtail = orig_boundary(:,2) - tailCOM(1);
y_distfromtail = orig_boundary(:,1) - tailCOM(2);
distfromtail   = sqrt(x_distfromtail.^2 + y_distfromtail.^2 );

% find distance of all boundary points from tailless mouse
x_distfrommouse = orig_boundary(:,2) - thinmouseCOM(1);
y_distfrommouse = orig_boundary(:,1) - thinmouseCOM(2);
distfrommouse   = sqrt(x_distfrommouse.^2 + y_distfrommouse.^2 );

% find the relative distance of each point from the center of mouse of the
% tail to that of the entire mouse. This distance can already be used to
% derive the head
tailheaddist = distfromtail - distfrommouse;


% now we get into the third stage, which determines the various head
% methods

if head_method == 1
    % point which shows the greatest difference between head center of mass
    % and tail center of mass
    [~,nose_ind] = max(tailheaddist);
elseif head_method == 2
    % point which shows the greatest difference between head and tail
    % but is also on the bounding box
    perim_points = orig_boundary(:,1) == 1 | orig_boundary(:,1) == size(orig_mouse,1) | orig_boundary(:,2) == 1 | orig_boundary(:,2) == size(orig_mouse,2);
    tailheaddist(~perim_points) = 0;
    [~,nose_ind] = max(tailheaddist);
elseif head_method == 3
    % This will choose the farthest point from the tail that is on the the
    % perimeter, and is also further from the tail than from head
    perim_points = orig_boundary(:,1) == 1 | orig_boundary(:,1) == size(orig_mouse,1) | orig_boundary(:,2) == 1 | orig_boundary(:,2) == size(orig_mouse,2);
    distfromtail(~perim_points)  = 0;
    distfromtail(tailheaddist<0) = 0;
    [~,nose_ind] = max(distfromtail);
elseif head_method == 4
    % Furthest point from tail end, which is also on perimeter, and is also
    % further from tail center of mass than body center of mass
    
    % Detect end of the tail - this is the furthest point from tail center
    % of mass, which is closer to tail center of mass than to head center of mass and is on the perimeter
    perim_points = orig_boundary(:,1) == 1 | orig_boundary(:,1) == size(orig_mouse,1) | orig_boundary(:,2) == 1 | orig_boundary(:,2) == size(orig_mouse,2);
    distfromtail(~perim_points)  = 0;
    distfromtail(tailheaddist>0) = 0;
    [~,tail_ind] = max(distfromtail);
    tailendPOS = [orig_boundary(tail_ind,2),orig_boundary(tail_ind,1)];
    
    % calculate the furthest distance from end of tail
    x_distfromend   = orig_boundary(:,2) - tailendPOS(1);
    y_distfromend   = orig_boundary(:,1) - tailendPOS(2);
    distfromend     = sqrt(x_distfromend.^2 + y_distfromend.^2 );
    
    % must be further from tail COM than from body COM
    distfromend(tailheaddist<0)     = 0;
    % must be on perimeter of original mouse
    distfromtail(~perim_points)  = 0;
    [~,nose_ind] = max(distfromend);
    
elseif head_method == 5
    % maximum distance from tail base - not tail end.
    % This works better when the tail is at an angle
    
    % Get the boundary of the thinned mouse
    [thinB,~] = bwboundaries(thin_mouse,8,'noholes');
    thinboundary = thinB{1};
    
    % Detect the the end of the tail (as in method 4)
    perim_points = orig_boundary(:,1) == 1 | orig_boundary(:,1) == size(orig_mouse,1) | orig_boundary(:,2) == 1 | orig_boundary(:,2) == size(orig_mouse,2);
    distfromtail(~perim_points)  = 0;
    distfromtail(tailheaddist>0) = 0;
    [~,tail_ind] = max(distfromtail);
    tailendPOS = [orig_boundary(tail_ind,2),orig_boundary(tail_ind,1)];
    
    % find the point on the thin boundary - that is, of the tailless mouse, which is closest to the tail end
    x_distfromend   = thinboundary(:,2) - tailendPOS(1);
    y_distfromend   = thinboundary(:,1) - tailendPOS(2);
    distfromend     = sqrt(x_distfromend.^2 + y_distfromend.^2 );
    
    % the tail base is the closest point to the tail end which is also on
    % the thin (tailless) boundary
    % Only points on thin mouse border can qualify as tail base
    % note that we have to use the actual thin mouse image, not the
    % boundaries which include the original mouse
    thin_perim_points = thinboundary(:,1) == find(sum(thin_mouse,2), 1 ) | thinboundary(:,1) == find(sum(thin_mouse,2), 1, 'last' ) | thinboundary(:,2) == find(sum(thin_mouse,1), 1 ) | thinboundary(:,2) == find(sum(thin_mouse,1), 1, 'last' );
    distfromend(~thin_perim_points) = inf;
    [~,tail_base_ind] = min(distfromend);
    tailbasePOS = [thinboundary(tail_base_ind,2),thinboundary(tail_base_ind,1)];
    
    % distance from tail base of original mouse
    x_distfromtailbase = orig_boundary(:,2) - tailbasePOS(1);
    y_distfromtailbase = orig_boundary(:,1) - tailbasePOS(2);
    distfromtailbase   = sqrt( x_distfromtailbase.^2 + y_distfromtailbase.^2 );
    
    % The nose must still be closer to the center of mass than to tail base
    tailbaseheaddist = distfromtailbase - distfrommouse;
    distfromtailbase(tailbaseheaddist<0)     = 0;
    [~,nose_ind] = max(distfromtailbase);
    
elseif head_method == 6
    % maximum distance from tail base, determined as geodesic distance from
    % tail end - works even better when the tail is at an angle, whicg
    % might otherwise confound tail base detection
    
    % Get the boundary of the thinned mouse
    [thinB,~] = bwboundaries(thin_mouse,8,'noholes');
    thinboundary = thinB{1};
    
    % Detect the the end of the tail (as in method 4)
    perim_points = orig_boundary(:,1) == 1 | orig_boundary(:,1) == size(orig_mouse,1) | orig_boundary(:,2) == 1 | orig_boundary(:,2) == size(orig_mouse,2);
    distfromtail(~perim_points)  = 0;
    distfromtail(tailheaddist>0) = 0;
    [~,tail_ind] = max(distfromtail);
    tailendPOS = [orig_boundary(tail_ind,2),orig_boundary(tail_ind,1)];
    
    % find the point on the thin boundary - that is, of the tailless mouse, which is closest to the tail end
    x_distfromend   = thinboundary(:,2) - tailendPOS(1);
    y_distfromend   = thinboundary(:,1) - tailendPOS(2);
    distfromend     = sqrt(x_distfromend.^2 + y_distfromend.^2 );
    
    % Calculate geodesic distance from tail end
    % origBW is true for all pixels on original mouse boundary
    origBW = false(size(orig_mouse));
    LineaBorderIndex = sub2ind(size(orig_mouse), orig_boundary(:,1), orig_boundary(:,2));
    origBW(LineaBorderIndex) = 1;
    
    % This is a mask, which essentially is only 1 on the tail end
    % and is also on the boundary
    endMASK = false(size(orig_mouse));
    endMASK(orig_boundary(tail_ind,1),orig_boundary(tail_ind,2)) = 1;
    
    
    % The matrix D contrains all distance from each border pixel of the original mouse and the endMASK
    D = bwdistgeodesic(origBW,endMASK) ;
    % figure; imagesc(D); axis equal; colormap hot ; colorbar        
    
    % but we must ignore pixels which are not part of the thin (tailless moouse) mouse
    % BM = box margin, which defines the scope of where the tal base could be.
    % we need to add the trimming value, since the thin BB does not contain
    % the periphery which is where the tail could be
    
    
    BM = trim_cycles;    
    inds_in_thinBB = orig_boundary(:,2) >= (round(thinBB(1))-BM) & orig_boundary(:,2) <= (round(thinBB(1)) + thinBB(3) +BM) & orig_boundary(:,1) >= (round(thinBB(2))-BM) & orig_boundary(:,1) <= (round(thinBB(2)) + thinBB(4) +BM) ;        
    
    
    %inds_in_thinBB = ismember(orig_boundary(:,2),thinboundary(:,2)) & ismember(orig_boundary(:,1),thinboundary(:,1));
    
    %inds_in_thinBB = orig_boundary(:,2) >= round(thinBB(1)) & orig_boundary(:,2) <= round(thinBB(1)) + thinBB(3) & orig_boundary(:,1) >= round(thinBB(2)) & orig_boundary(:,1) <= round(thinBB(2)) + thinBB(4) ;
    LinearIndsInThinBB = sub2ind(size(orig_mouse), orig_boundary(inds_in_thinBB,1), orig_boundary(inds_in_thinBB,2));
    % And we set all those pixels which are not on withint he box to a
    % distance greater than all other pixels
    D(setdiff([1:numel(D)],LinearIndsInThinBB)) = max(max(D))+1;
    %    figure; imagesc(D); axis equal; colormap hot ; colorbar
    
    % now we find the closest pixel to the end = this will be the tail base
    [~,minDind] = min(D(:));
    % GEt the coordinates in row-column format
    [Rind,Cind] = ind2sub(size(D),minDind);
    tailbasePOS = [Cind,Rind];
    
    % And now that we have the tail base, we calculate the nose as we did
    % in the previous method (5)
    % distance from tail base of original mouse
    x_distfromtailbase = orig_boundary(:,2) - tailbasePOS(1);
    y_distfromtailbase = orig_boundary(:,1) - tailbasePOS(2);
    distfromtailbase   = sqrt( x_distfromtailbase.^2 + y_distfromtailbase.^2 );
    
    % The nose must still be closer to the center of mass than to tail base
    tailbaseheaddist = distfromtailbase - distfrommouse;
    distfromtailbase(tailbaseheaddist<0)     = 0;
    [~,nose_ind] = max(distfromtailbase);
    
elseif head_method == 7        
    % This method is appropriate when the mouse "has no tail" (or when it cna be thresholded out of the image)
    % 
    % Detect end of the tail - this is the furthest point from tail center
    % of mass, which is closer to tail center of mass than to head center of mass and is on the perimeter
    % This works without a tail, because the head is the thinnest part and
    % stripping will make the head, rather thant he tail dissappear. 
    perim_points = orig_boundary(:,1) == 1 | orig_boundary(:,1) == size(orig_mouse,1) | orig_boundary(:,2) == 1 | orig_boundary(:,2) == size(orig_mouse,2);
    distfromtail(~perim_points)  = 0;
    distfromtail(tailheaddist>0) = 0;
    [~,tail_ind] = max(distfromtail);    
    nose_ind = tail_ind;    
end

nosePOS = [orig_boundary(nose_ind,2),orig_boundary(nose_ind,1)]  + BB(1:2);

% This is just a mock test
Result.mouseCOM = mouseCOM+[P1 P2] + P3;
Result.nosePOS  = nosePOS+ [P1 P2] + P3;
Result.GreyThresh = GreyThresh;
Result.TrimFact =  TrimFact;
Result.BB = BB;
Result.MouseArea = MouseArea;
Result.MousePerim = MousePerim;
Result.ThinMousePerim = ThinMousePerim;

[I, J ] = ind2sub(size(orig_mouse),find(orig_mouse+thin_mouse == 1));

Result.PerimInds = {I,J};
Result.tailCOM = tailCOM + BB(1:2);
Result.thinmouseCOM = thinmouseCOM + BB(1:2);
if exist('tailbasePOS')
    Result.tailbasePOS = tailbasePOS +  BB(1:2);
end
if exist('tailendPOS')
    Result.tailendPOS = tailendPOS +  BB(1:2);
end


