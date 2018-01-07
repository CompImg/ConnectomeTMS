ref_vol = 'TMSoriginal.nii.gz'
input_point = 'points.csv' %those are related to the points seen in the file *Above_anatomic

points = csvread(input_point);

points(:,1) = 170 -  points(:,1) ;
points(:,2) = points(:,2) -10 ;
points(:,3) = 250 -   points(:,3)   ;
 
% Swap X with Y
temp = points(:,3);
points(:,3) = points(:,1);
points(:,1) = temp;

num_points = length(points);

myvol =  load_untouch_nii(ref_vol);
myimm = zeros(size(myvol.img));

for ii = 1 : num_points
    myimm(round(points(ii,1)), round(points(ii,2))   , round(points(ii,3))    ) = 1;    
end

[r c d ]  = size(myimm);
%se = strel('disk',3);
[x,y,z] = ndgrid(-1:1);
se = strel(sqrt(x.^2 + y.^2 + z.^2) <=3);

for jj = 1 : r
    myimm(jj,:,:) =  imdilate(  myimm(jj,:,:) ,se);
end


for jj = 1 : c
    myimm(:,jj,:) =  imdilate(  myimm(:,jj,:) ,se);
end

for jj = 1 : d
    myimm(:,:,jj) =  imdilate(  myimm(:,:,jj) ,se);
end


myvol.img = myimm;
save_untouch_nii(myvol,'points.nii');
