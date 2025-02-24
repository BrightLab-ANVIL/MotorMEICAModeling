#!/bin/sh
# Calculate Dice coefficient between two thresholded activation maps within a mask

if [ $# -ne 5 ]
then
  echo "*****************************************************************************************************"
  echo "Insufficient arguments supplied"
  echo "Input 1 should be the full path to activation file 1 (do not include file extension - assumes .nii.gz)"
  echo "Input 2 should be the full path to activation file 2 (do not include file extension - assumes .nii.gz)"
  echo "Input 3 should be the full path to the mask to use in functional space (do not include file extension - assumes .nii.gz)"
  echo "Input 4 should be the full path to the output directory"
  echo "Input 5 should be the output prefix"
  echo "*****************************************************************************************************"
  exit
fi

#Define inputs
act_file1=${1}
act_file2=${2}
mask=${3}
output_dir=${4}
prefix=${5}

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

# Find number of voxels within mask in each activation file
actNum1=`3dBrickStat -non-zero -nonan -count -mask ${mask}.nii.gz ${act_file1}.nii.gz`
actNum2=`3dBrickStat -non-zero -nonan -count -mask ${mask}.nii.gz ${act_file2}.nii.gz`

# Find number of voxels within mask where activation maps overlap
3dcalc -a ${act_file1}.nii.gz -b ${act_file2}.nii.gz -expr 'a*b' \
  -prefix ${act_file1}_overlap.nii.gz

actNumOverlap=`3dBrickStat -non-zero -nonan -count -mask ${mask}.nii.gz ${act_file1}_overlap.nii.gz`

# Calculate Dice coefficient
dice=$(echo "scale=4; 2 * $actNumOverlap / ($actNum1 + $actNum2)" | bc)

# Make tSNR outputs global variables
echo ${dice} > ${output_dir}/${prefix}_dice.txt

echo "actNum1 = $actNum1"
echo "actNum2 = $actNum2"
echo "actNumOverlap = $actNumOverlap"
