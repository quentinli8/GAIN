
% This is an amended version of newcreategraph7. Changed so that after ring
% removal, neurites are extended to tuj bodies.

function G = newcreategraph7(neuriteMask, cellBodyMask, cellNumberGrid, numCellBodies) %, tujImage)
fprintf('newcreategraph2\n');
G = [];


% Skeletonize mask
S = bwmorph(neuriteMask, 'skel', Inf) & ~cellBodyMask;


% Remove pocket pixels from skeletonization
S2 = double(S);
% Once was not enough, so do it twice
for i = 1:2
    h = [1 1 0; 1 1 -1; 1 1 0];
    for r = 1:4
        Sf = imfilter(S2, h);
        S2 = S2 - (Sf == 6);
        h = rot90(h);
    end
end
% Reskeltonize
S = bwmorph(S2 == 1, 'skel', Inf);

% Sometimes branchpoints outside of S are found take conjunction with S
branchPoints = bwmorph(S, 'branchpoints') & S;

% Remove rings
% Do not remove rings one at a time because a neurite segment may be shared
% by two rings.  First, identify all rings and then remove them.
%imwrite(S, 'ringremoval2.tif', 'Compression', 'none');
S0 = S;
% Mask to remove all rings (less branch ppoints) at once
removalMask = false(size(S));
branchExtensions = false(size(S));
% Associate branchpoint vertices in removed rings with cell bodies
ringVertices = zeros(size(S));
extensions = false(size(S));
sqrt2 = sqrt(2);
%figure, imshow(S);
for b = 1:numCellBodies
    M = cellNumberGrid == b;
    
    cellBodyArea = sum(double(M(:)));
    % Find a cell body pixel to use as an imfill starting point 
    ind = find(M, 1);
    % Isolate filled region
    F = imfill(S, ind) & ~S;
%    figure, imshow(double(cat(3, F, S, M)));
%    figure, imshow(tujImage);
%    figure, imshow(double(cat(3, M, S, F))), title('Before ring removal');
    fillArea = sum(double(F(:)));
%    fprintf('%d: cell=%f  fill=%f  cell/fill=%f\n', b, cellBodyArea, fillArea, (cellBodyArea/fillArea));
    if (cellBodyArea / fillArea) >= 0.4
        ring = imdilate(F, true(3)) & S;
        % Find branch points on ring
        ringBP = ring & branchPoints;
        removalMask = removalMask | (ring & ~ringBP);
        % Extend branch points into the cell body
        [bpRow, bpCol] = find(ringBP);
        for k = 1:numel(bpRow)
%            fprintf('[newcreategraph7] cell body: %d   branch point: %d\n', b, k);

            


            % 1. Backtrack from branch point along non-ring path creating
            % an extension template
            S2 = S & ~(ring  & ~ringBP);
            maxBacktrackLen = 7;
            backtrackR = zeros(round(maxBacktrackLen), 1);
            backtrackC = zeros(round(maxBacktrackLen), 1);
            btIndex = 0;
            backtrackLen = 0;
            r = bpRow(k);           
            c = bpCol(k);
            % Find row and column of pixel in M that is closest to branch
            % point
            [row, col] = find(M);
            dist = arrayfun(@(r2, c2)(r - r2)^2 + (c - c2)^2, row, col);
            minInd = find(dist == min(dist));
            % Use first pixel that is closest.
            minR = row(minInd(1));
            minC = col(minInd(1));
            deltaR = minR - r;
            deltaC = minC - c;
            if abs(deltaR) >= abs(deltaC)
                dcdr = deltaC / deltaR;
                sgn = sign(deltaR);
                for d = sgn:sgn:(sgn*(abs(deltaR)-1))
                    r1 = r + d;
                    c1 = round(c + (d * dcdr));
                    branchExtensions(r1, c1) = true;
                end
            else
                drdc = deltaR / deltaC;
                sgn = sign(deltaC);
                for d = sgn:sgn:(sgn*(abs(deltaC) - 1))
                    c1 = c + d;
                    r1 = round(r + (d * drdc));
                    branchExtensions(r1, c1) = true;
                end
            end

        end
        
        
    end
end

S = (S & ~removalMask) | branchExtensions;

% Remove unrecognized branch points
S2 = double(S);
h = [1 1 -1; 1 1 -1; 1 -1 -1];
for r = 1:4
    Sf = imfilter(S2, h);
    S2 = S2 - (Sf == 5);
    h = rot90(h);
end
h = [-1 1 1; -1 1 1; -1 -1 1];
for r = 1:4
    Sf = imfilter(S2, h);
    S2 = S2 - (Sf == 5);
    h = rot90(h);
end
% Reskeltonize
S = bwmorph(S2 == 1, 'skel', Inf);



% Remove pocket points
% perhaps a generalization of the above
S2 = double(S);
h = [0 1 0; 1 1 -1; 0 1 0];
for r = 1:4
    Sf = imfilter(S2, h);
    S2 = S2 - (Sf == 4);
    h = rot90(h);
end
% Reskeltonize
S = bwmorph(S2 == 1, 'skel', Inf);
%figure, imshow(S((749-3):(749+3), (435-3):(435+3)), 'InitialMagnification', 'fit'), title('r=749 c=435');


mask = S;


% The mask argument is a neurite skeleton, and the cellBodyMask argument is
% a mask of cell bodies.  In order to find where the neurite skeleton ends
% at a cell body, dilate the cell body mask.



mh = MaskHandle(double(mask));


mask = bwmorph(mask, 'skel', Inf);
skeleton = mask;
endPoints = bwmorph(mask, 'endpoints') & mask;
branchPoints = bwmorph(mask, 'branchpoints') & mask;

% De-recognize unnecessary branch points
h = [-1 -1 -1; -1 10 -1; -1 10 10];
h2 = [1 1 1; -1 10 -1; 0 0 0];
for i = 1:4
    unnecessaryBranch = (imfilter(double(branchPoints), h) == 30) & (imfilter(double(mask), h2) == 11);
    branchPoints = branchPoints & ~unnecessaryBranch;
    h = rot90(h);
    h2 = rot90(h2);
end
h = [-1 -1 -1; -1 10 -1; 10 10 -1];
h2 = [1 1 1; -1 10 -1; 0 0 0];
for i = 1:4
    unnecessaryBranch = (imfilter(double(branchPoints), h) == 30) & (imfilter(double(mask), h2) == 11);
    branchPoints = branchPoints & ~unnecessaryBranch;
    h = rot90(h);
    h2 = rot90(h2);
end


common = endPoints & branchPoints;
assert(~any(common(:)), 'Overlapping end points and branch points');
epIdx = find(endPoints);
bpIdx = find(branchPoints);
% vIdx maps vertex numbers to linear indices to locate vertices
vIdx = [epIdx; bpIdx];

%red = imdilate(skeleton, true);
%green = red;
%blue = red;
%v = false(size(red));
%v(vIdx) = true;
%v = imdilate(v, true(3));
%red(v) = false;
%green(v) = true;
%blue(v) = false;
%figure, imshow(double(cat(3,red,green,blue))), title('Final Skeleton');

bp = branchPoints & mask;
lim = 14;
contact = imfilter(double(bp), [1 1 1; 1 10 1; 1 1 1]) >= lim;
[R, C] = find(contact);
fprintf('%d branch points with %d or more branch point neighbors\n', numel(R), lim-10);

if size(R, 1) > 0
    
    for b = 1:size(R, 1)
        r = R(b);
        c = C(b);
        
        rgb = makeRGB(mask, branchPoints, endPoints);
        
    end
    result = input('*****');
    error('***');
end


sz = size(mask);


%legs = skeleton & ~branchpoints
%legs = imdilate(legs, true(3));
r = skeleton;
g = skeleton;
b = skeleton;
r(branchPoints) = false;
g(branchPoints) = true;
b(branchPoints) = false;
%figure, imshow(double(cat(3, r,g,b))), title('Branch Points');

%result = input('***');
%error('***');

fprintf('[newcreategraph7] Starting findEdges\n');
[edgeStack vertexLocations] = findEdges(skeleton, branchPoints, endPoints);
fprintf('[newcreategraph7] edgeStack1 contains %d edges\n', edgeStack.size);

fprintf('[newcreategraph7] Calling NeuriteGraph constructor\n');
tic;
G = NeuriteGraph(edgeStack.toCellArray(), vertexLocations, cellNumberGrid, size(mask), ringVertices, skeleton);
toc;

end


function rgb = makeRGB(skel)
branchPoints = bwmorph(skel, 'branchpoints');
endPoints = bwmorph(skel, 'endpoints');

red = zeros(size(skel));
green = zeros(size(skel));
blue = zeros(size(skel));

% Yellow neurites
red(skel) = 1;
green(skel) = 1;
blue(skel) = 0;

% Blue branch points
red(branchPoints) = 0;
green(branchPoints) = 0;
blue(branchPoints) = 1;

% Cyan end points
red(endPoints) = 0;
green(endPoints) = 1;
blue(endPoints) = 1;


rgb = double(cat(3, red, green, blue));
end
