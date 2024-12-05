#!/bin/sh
# Calculate tSNR using errts on a dataset that was converted to signal percentage change before running the subject-level GLM
# Must have run subject-level GLM first to create errts file

if [ $# -ne 5 ]
then
  echo "*****************************************************************************************************"
  echo "Insufficient arguments supplied"
  echo "Input 1 should be the full path to errts file (include file extension)"
  echo "Input 2 should be the full path to the mean file found during SPC calculation (do not include file extension - assumes .nii.gz)"
  echo "Input 3 should be the full path to the mask to use in functional space (do not include file extension - assumes .nii.gz)"
  echo "Input 4 should be the full path to the output directory"
  echo "Input 5 should be the output prefix"
  echo "*****************************************************************************************************"
  exit
fi

#Define inputs
errts=${1}
mean=${2}
mask=${3}
output_dir=${4}
prefix=${5}

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

# Add the mean back into the errts file to properly calculate tSNR: [X*avg(X)]+avg(X)
fslmaths ${errts}.nii.gz -mul $mean -add $mean "${errts}_withMean.nii.gz"

# Calculate tSNR
3dTstat -tsnr -prefix ${output_dir}/${prefix}_tsnr.nii.gz ${errts}_withMean.nii.gz

# Compute mean and median tSNR in mask
meanTSNR=`3dBrickStat -nonan -mean -mask ${mask}.nii.gz ${output_dir}/${prefix}_tsnr.nii.gz`
medTSNR_full=`3dBrickStat -nonan -median -mask ${mask}.nii.gz ${output_dir}/${prefix}_tsnr.nii.gz`
  medTSNR_full_length=${#medTSNR_full}
  medTSNR=`echo ${medTSNR_full} | cut -c6-${medTSNR_full_length}`

# Make tSNR outputs global variables
echo ${meanTSNR} > ${output_dir}/${prefix}_meantSNR.txt
echo ${medTSNR} > ${output_dir}/${prefix}_mediantSNR.txt
