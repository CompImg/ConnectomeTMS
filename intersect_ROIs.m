%%%%%%%%%%%%%%%%%%%%%% Code to intersect atlas with TMS points  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%%%%%%%%%%%%%%%%%%%%%% A. Crimi University of Zurich %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load atlas and points, it is assumed that those are coregistered and the same voxel size
points =  load_untouch_nii('points20_swap13.nii.gz');  #TMS points as NIFTI file
atlas =  load_untouch_nii('atlas_reg.nii.gz'); #Atlas registered to the TMS points volume

img1 = points.img;
img2 = atlas.img;
and_vol = img1 .* img2;
 

areas_list = unique(and_vol);
areas_list(1) = [];

disp('Those are the intersected areas')
areas_list
 

% Create eventual mask by the intersection of the areas
for xx = 1 : length(areas_list)

atlas_reg =  load_untouch_nii('atlas_reg.nii.gz');
[r c d] = size(atlas_reg.img);
rois = zeros(r,c,d);

for ii = 1 : r
    
    for jj = 1 : c
        
        for kk = 1 : d
            
            if ( atlas_reg.img(ii,jj,kk) == areas_list(xx) )
               rois(ii,jj,kk) = areas_list(xx);
            end
             
        end
        
    end
    
end

atlas_reg.img = rois;

name= strcat('roi',num2str(xx),'.nii');
save_untouch_nii(atlas_reg, name);
 
end
