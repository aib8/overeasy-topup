#!/bin/sh
# # Anna Blazejewska Sept 2022
# If you use this code please cite:
# Blazejewska et al., Slice-direction geometric distortion evaluation and correction with reversed slice-select gradient acquisitions., NeuroImage 2022.

# NOTE: requires preinstalled FSL 6.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)

# overeasy_topup_slice.sh input1 input2 [-apply input3 input4]
# 
# input1 = 3D/4D dataset with slice encoding gradient polarity +z
# input2 = 3D/4D dataset with slice encoding gradient polarity -z
# these two inputs have to be identical except for the slice encoding gradient polarity
# they have to be in NIfTI format (nii.gz extension)
#
# by default the distortion etimation and correction is performed on the same datasets
# in order to apply correction to a different *matched* dataset --apply flag with two optional arguments has to be used
#

input1=$1
input2=$2

flag=$3 # optional application to another pair of fatasets
optinput1=$4
optinput2=$5


# ROTATION  ######################
# topup works for x or y directions this trick allows it to work for z direction
echo fslswapdim $input1 x z -y ${input1/.nii.gz/_rot.nii.gz};
fslswapdim $input1 x z -y ${input1/.nii.gz/_rot.nii.gz};
echo fslswapdim $input2 x z -y ${input2/.nii.gz/_rot.nii.gz};
fslswapdim $input2 x z -y ${input2/.nii.gz/_rot.nii.gz};
  

# checking the time series length (have to be the same for both inputs)
N=`mri_info --nframes ${input1} | tail -1`;


# CONCATENATION of the two frames: +z and -z
base_dir=$(dirname $input1)
topup_input=$base_dir/topup_input.nii.gz
echo fslmerge -t $topup_input ${input1/.nii.gz/_rot.nii.gz} ${input2/.nii.gz/_rot.nii.gz};
fslmerge -t $topup_input ${input1/.nii.gz/_rot.nii.gz} ${input2/.nii.gz/_rot.nii.gz};


# TOPUP: create corresponding list file 
rm topup_info.txt
echo "0 1 0 1" > topup_info.txt
for (( c=1; c<$N; c++ )); do echo "0 1 0 1" >> topup_info.txt done;
echo "0 -1 0 1" >> topup_info.txt
for (( c=1; c<$N; c++ )); do echo "0 -1 0 1" >> topup_info.txt done;


# TOPUP: config file
topup_cfg_file=./topup_config.cnf


# TOPUP: calculate deformation
echo topup --v -imain=$topup_input --datain=./topup_info.txt --config=$topup_cfg_file --out=${topup_input/.nii.gz/} --fout=${topup_input/.nii.gz/_field.nii.gz} --dfout=${topup_input/.nii.gz/_deformation}
topup -v --imain=$topup_input --datain=./topup_info.txt --config=$topup_cfg_file --out=${topup_input/.nii.gz/} --fout=${topup_input/.nii.gz/_field.nii.gz} --dfout=${topup_input/.nii.gz/_deformation}


# TOPUP - APPLY TO MATCHED DATASET ##################################
if [[ $flag == "--apply" ]] ; then

  # rotation to match the estimated voxel shift map
  echo fslswapdim $optinput1 x z -y ${optinput1/.nii.gz/_rot.nii.gz};
  fslswapdim $optinput1 x z -y ${optinput1/.nii.gz/_rot.nii.gz};
  echo fslswapdim $optinput2 x z -y ${optinput2/.nii.gz/_rot.nii.gz};
  fslswapdim $optinput2 x z -y ${optinput2/.nii.gz/_rot.nii.gz};

  # number of frames might be different than for the original inputs
  # but the same in each of two datasets to be corrected
  NC=`mri_info --nframes ${input1} | tail -1`;

  # split the volumes into single frames
  fslsplit ${optinput1/.nii.gz/_rot.nii.gz} ${optinput1/.nii.gz/_rot_}
  fslsplit ${optinput2/.nii.gz/_rot.nii.gz} ${optinput2/.nii.gz/_rot_}

  # input list
  inlist1=$(echo ${optinput1/.nii.gz/_rot_0???.nii.gz} | sed 's/ /,/g' | sed 's/.nii.gz//g')
  inlist2=$(echo ${optinput2/.nii.gz/_rot_0???.nii.gz} | sed 's/ /,/g' | sed 's/.nii.gz//g')
  inlist_all=$(echo $inlist1","$inlist2)

  # indexes 
  index1=1; index2=$(($NC+1));
  for (( c=1; c<$NC; c++ )); do index1="$index1,1"; index2="$index2,$(($NC+1))"; done
  index_all="$index1,$index2"

  # TOPUP: apply deformation - correct distortion
  echo applytopup -v --imain=${inlist_all} --inindex=$index_all --datain=topup_info.txt --topup=${topup_input/.nii.gz/} --out=${optinput1/.nii.gz/_corrected.nii.gz}
  applytopup -v --imain=${inlist_all} --inindex=$index_all --datain=topup_info.txt --topup=${topup_input/.nii.gz/} --out=${optinput1/.nii.gz/_corrected.nii.gz}


# TOPUP - APPLY TO THE SAME DATASET ##################################
else

  # split the volumes into single frames
  fslsplit ${input1/.nii.gz/_rot.nii.gz} ${input1/.nii.gz/_rot_}
  fslsplit ${input2/.nii.gz/_rot.nii.gz} ${input2/.nii.gz/_rot_}

  # input list
  inlist1=$(echo ${input1/.nii.gz/_rot_0???.nii.gz} | sed 's/ /,/g' | sed 's/.nii.gz//g')
  inlist2=$(echo ${input2/.nii.gz/_rot_0???.nii.gz} | sed 's/ /,/g' | sed 's/.nii.gz//g')
  inlist_all=$(echo $inlist1","$inlist2)

  # indexes
  index_all=$(seq -s',' 1 $((2*$N)))

  # TOPUP: apply deformation - correct distortion
  echo applytopup -v --imain=${inlist_all} --inindex=$index_all --datain=topup_info.txt --topup=${topup_input/.nii.gz/} --out=${topup_input/.nii.gz/_corrected.nii.gz}
  applytopup -v --imain=${inlist_all} --inindex=$index_all --datain=topup_info.txt --topup=${topup_input/.nii.gz/} --out=${topup_input/.nii.gz/_corrected.nii.gz}

fi

