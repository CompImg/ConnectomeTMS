######################## Tractography and Global metrix generation #############################
####
###
######################## A. Crimi, University of Zurich ########################################


#Import for tractography
import dipy
import numpy as np
import nibabel as nib
from nibabel import trackvis as tv
from dipy.tracking.streamline import set_number_of_points
from dipy.segment.mask import median_otsu
from dipy.io import read_bvals_bvecs
from dipy.core.gradients import gradient_table
from dipy.reconst.dti import TensorModel
from dipy.reconst.dti import fractional_anisotropy
from dipy.reconst.dti import color_fa
from dipy.reconst.shm import CsaOdfModel
from dipy.data import get_sphere
from dipy.reconst.peaks import peaks_from_model
from dipy.tracking.eudx import EuDX
from dipy.tracking.utils import density_map
#from dipy.viz import fvtk
from dipy.tracking import utils
import matplotlib.pyplot as plt

#Import for connectome metrics
from bct.algorithms.clustering import  transitivity_wu
from bct.algorithms.distance import charpath
from bct.algorithms.modularity import community_louvain
from bct.algorithms.distance import   distance_wei 
from bct.utils.other import weight_conversion

import sys
#subject_name = sys.argv[1]

fimg = "input.nii.gz"
img = nib.load(fimg)
data = img.get_data()
affine = img.get_affine()
header = img.get_header() 
voxel_size = header.get_zooms()[:3]
mask, S0_mask = median_otsu(data[:, :, :, 0])
fbval = "original.bval"
fbvec = "original.bvec"

#Create tensor model
bvals, bvecs = read_bvals_bvecs(fbval, fbvec)
gtab = gradient_table(bvals, bvecs)
ten_model = TensorModel(gtab)
ten_fit = ten_model.fit(data, mask)
fa = fractional_anisotropy(ten_fit.evals)
cfa = color_fa(fa, ten_fit.evecs)
csamodel = CsaOdfModel(gtab, 6)
sphere = get_sphere('symmetric724')
pmd = peaks_from_model(model=csamodel,
                       data=data,
                       sphere=sphere,
                       relative_peak_threshold=.5,
                       min_separation_angle=25,
                       mask=mask,
                       return_odf=False)

#Deterministic tractography 
eu = EuDX(a=fa, ind=pmd.peak_indices[..., 0], seeds=2000000, odf_vertices=sphere.vertices, a_low=0.1)
affine = eu.affine
csd_streamlines= list(eu)

#Remove tracts shorter than 30mm
#print np.shape(csd_streamlines)
from dipy.tracking.utils import length 
csd_streamlines=[t for t in csd_streamlines if length(t)>30]
 
  
#Trackvis
hdr = nib.trackvis.empty_header()
hdr['voxel_size'] = img.get_header().get_zooms()[:3]
hdr['voxel_order'] = 'LAS'
hdr['dim'] = fa.shape
tensor_streamlines_trk = ((sl, None, None) for sl in csd_streamlines)
ten_sl_fname = 'tensor_streamlines.trk'
nib.trackvis.write(ten_sl_fname, tensor_streamlines_trk, hdr, points_space='voxel')
 
#Load atlas
print np.shape(csd_streamlines)
atlas = nib.load('atlas_reg.nii.gz')
labels = atlas.get_data()
labelsint = labels.astype(int)
 
M = utils.connectivity_matrix(csd_streamlines, labelsint, affine=affine  )

#Remove background
M = M[1:,1:]

# AAl has 90 or 116 areas
# Craddock atlas has 200-220 areas
# Remove eventual connectivity which are beyond the atlas labeling
M = M[:200,:200]

# U-fibers are on the diagonal, set them to zero
np.fill_diagonal(M,0)

#Save connectivity matrix
np.savetxt("connectome.csv", M, delimiter=",")
#np.savetxt('connectome.txt', M) 
#Plot and save connectivity matrix
#plt.imshow(np.log1p(M), interpolation='nearest')
#plt.savefig("connectivity.png") 

'''
# Global Connectivity metrics
modularity = community_louvain(M)[1]
#Charpath needs some conversion
L = weight_conversion(M, 'lengths')
D = distance_wei( M )[0]
charpath,efficiency,_,_,_ = charpath(D)
m_clustering_coef = transitivity_wu(M)  

outF = open("metrics.csv", "w")
outF.write("Subject, louvain, char_path_len, global_eff, transitivity \n")
outF.write( subject_name + ", " + str(modularity) + ", " + str(charpath) + ", " + str(efficiency) + ", " +str(m_clustering_coef) )
''' 
