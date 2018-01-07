#!/bin/bash  

 
################## Pre-processing DTI  ###############
echo " ################################################"
echo "Pre-processing DTI"

baseline=1
suffix="/"

for d in */ ; do
    echo "-------------------------------------------------"
    echo "entering subfolder" "$d"
    cd $d
    pwd
 '''
           cd gradients

                  #Convert DCM 2 NII
                  dcm2nii -4 y -n y -v y * 
                
                  mv *.nii.gz original.nii.gz
                  mv *.bval original.bval
                  mv *.bvec original.bvec

                  echo "Skull stripping"
                  bet  original.nii.gz    brain.nii.gz -m -f 0.2
                  fslmaths original.nii.gz   -mas brain_mask.nii.gz betted.nii.gz
  
                  echo "Eddy current correction"	 
                  eddy_correct betted.nii.gz  eddycorrected.nii.gz   -interp trilinear

                  echo "register the atlas using the generated matrix"
                  flirt -ref  eddycorrected.nii.gz -in   ../../atlas_swapped.nii.gz -out atlas_reg.nii.gz -cost normmi  -interp nearestneighbour
 
                  mv atlas_reg.nii.gz ../atlas_reg.nii.gz
                  mv original.bval ../original.bval
                  mv original.bvec ../original.bvec
           cd ..
 
           cd b0

                 dcm2nii -4 y -n y -v y *
                 mv *.nii.gz b0.nii.gz

                 bet  b0.nii.gz    b0betted.nii.gz -f 0.2
 
           cd ..

           fslmerge -t combined.nii.gz b0/b0betted.nii.gz  gradients/eddycorrected.nii.gz 

                  #foo=${d%$suffix}
                
                  cp  ../*.py .

                  echo "Generate Connectome matrix"
                  echo "0 $(cat original.bval)" > original.bval
                  sed -i '1s/^/0 /' original.bvec
                  sed -i '2s/^/0 /' original.bvec
                  sed -i '3s/^/0 /' original.bvec

                  python  tractography.py $d

     #             python  metrics.py $d
    cd ..
'''
    #TMS
    cd DICOMFiles

       pwd
       dcm2nii -4 y -n y -v y *.DCM
       mv 2*.nii.gz TMSoriginal.nii.gz  
       fslroi TMSoriginal.nii.gz TMSoriginal_c.nii.gz 0 240 85 240 0 170
       bet  TMSoriginal_c.nii.gz    brain.nii.gz -m -f 0.2
       flirt -ref   brain.nii.gz  -in   ../../atlas_swapped.nii.gz -out atlas_reg.nii.gz -cost normmi  -interp nearestneighbour
       cp  ../../*.m .
      
       matlab -nodesktop -r "run create_vol.m; run create_rois.m; quit"

    cd ..
done







              
