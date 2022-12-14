# overeasy-topup
This work is licensed under CC BY-NC-SA 4.0. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/

Author: Anna Blazejewska

If you use this code please cite:
Blazejewska et al., Slice-direction geometric distortion evaluation and correction with reversed slice-select gradient acquisitions., NeuroImage 2022.

This is a UNIX shell script to perform correction of EPI MRI data geometric distortion occurring in slice-encoding direction.
It requires input datasets acquired with two opposite slice gradient encoding polarities which are used to calculate a voxel shift map.
This voxel shift map can be applied to distortion correct the same datasets or a pair of different but *matched* datasets.
The *matched* datasets also with two slice-encoding polarities have to be spatially aligned with the original dataset.

The script requires:
- FSL 6.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
- additional topup_config.cfg file to be downloaded to the same directory the same directory
- input data: two 3D/4D EPI datasets acquired with opposite polarity of slice-encoding gradient and otherwise identical
