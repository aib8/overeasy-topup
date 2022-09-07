# overeasy-topup
This is a set of UNIX shell scripts to perform correction of EPI MRI data geometric distortion occuring in slice-encoding direction.
It requires input datasets acuired with the opposite slice gradient encoding polarities which are used to calculate voxel shift map.
This voxel shift map can be applied to distortion correct the same dataset or a corresponding one passed as the two additional input volumes.

The script requires:
- FSL 6.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
- additional topup_config.cfg file to be located in the same directory the same directory

