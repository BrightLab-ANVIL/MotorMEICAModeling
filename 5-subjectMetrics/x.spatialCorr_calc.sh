#!/bin/sh
# Calculate spatial correlation between two statistical maps within a mask

if [ $# -ne 5 ]
then
  echo "*****************************************************************************************************"
  echo "Insufficient arguments supplied"
  echo "Input 1 should be the full path to beta coefficient file 1 (do not include file extension - assumes .nii.gz)"
  echo "Input 2 should be the full path to beta coefficient file 2 (do not include file extension - assumes .nii.gz)"
  echo "Input 3 should be the full path to the mask to use in functional space (do not include file extension - assumes .nii.gz)"
  echo "Input 4 should be the full path to the output directory"
  echo "Input 5 should be the output prefix"
  echo "*****************************************************************************************************"
  exit
fi

#Define inputs
bcoef_file1=${1}
bcoef_file2=${2}
mask=${3}
output_dir=${4}
prefix=${5}

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

# Compute spatial correlation within mask
corr=`3ddot -mask ${mask}.nii.gz ${bcoef_file1}.nii.gz ${bcoef_file2}.nii.gz`

# Make tSNR outputs global variables
echo ${corr} > ${output_dir}/${prefix}_spatialCorr.txt
