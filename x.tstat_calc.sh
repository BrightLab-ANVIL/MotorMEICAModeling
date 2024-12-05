#!/bin/sh
# Calculate summary t-statistic values within a mask

if [ $# -ne 4 ]
then
  echo "*****************************************************************************************************"
  echo "Insufficient arguments supplied"
  echo "Input 1 should be the full path to t-statistic file (do not include file extension - assumes .nii.gz)"
  echo "Input 2 should be the full path to the mask to use in functional space (do not include file extension - assumes .nii.gz)"
  echo "Input 3 should be the full path to the output directory"
  echo "Input 4 should be the output prefix"
  echo "*****************************************************************************************************"
  exit
fi

#Define inputs
tstat_file=${1}
mask=${2}
output_dir=${3}
prefix=${4}

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

# Compute mean and median t-stat in mask
meanTstat=`3dBrickStat -nonan -mean -mask ${mask}.nii.gz ${tstat_file}.nii.gz`
medTstat_full=`3dBrickStat -nonan -median -mask ${mask}.nii.gz ${tstat_file}.nii.gz`
  medTstat_full_length=${#medTstat_full}
  medTstat=`echo ${medTstat_full} | cut -c6-${medTstat_full_length}`

# Make tSNR outputs global variables
echo ${meanTstat} > ${output_dir}/${prefix}_meanTstat.txt
echo ${medTstat} > ${output_dir}/${prefix}_medianTstat.txt
