#!/bin/sh
# Calculate summary activation values within a mask

if [ $# -ne 7 ]
then
  echo "*****************************************************************************************************"
  echo "Insufficient arguments supplied"
  echo "Input 1 should be the full path to t-statistic file (do not include file extension - assumes .nii.gz)"
  echo "Input 2 should be the full path to beta coefficient file (do not include file extension - assumes .nii.gz)"
  echo "Input 3 should be the full path to the ROI mask to use in functional space (do not include file extension - assumes .nii.gz)"
  echo "Input 4 should be the full path the subject's brain mask (do not include file extension - assumes .nii.gz)"
  echo "Input 5 should be the matrix.1D file output from the subject-level GLM (do not include file extension - assumes .1D)"
  echo "Input 6 should be the full path to the output directory"
  echo "Input 7 should be the output prefix"
  echo "*****************************************************************************************************"
  exit
fi

#Define inputs
tstat_file=${1}
bcoef_file=${2}
mask=${3}
brain_mask=${4}
matrix_file=${5}
output_dir=${6}
prefix=${7}

alpha="05"

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

## Compute mean and median beta coefficient in mask
meanBcoef=`3dBrickStat -nonan -mean -mask ${mask}.nii.gz ${bcoef_file}.nii.gz`
medBcoef_full=`3dBrickStat -nonan -median -mask ${mask}.nii.gz ${bcoef_file}.nii.gz`
  medBcoef_full_length=${#medBcoef_full}
  medBcoef=`echo ${medBcoef_full} | cut -c6-${medBcoef_full_length}`

## Calculate percent positive activated voxels
# find number of TRs and number of regressors from matrix.1D file
matrix_rowcol=`1d_tool.py -show_rows_cols -infile ${matrix_file}.1D -verb 0`
arr=($matrix_rowcol)
n_TRs=${arr[0]} # rows = number of TRs
n_regressors=${arr[1]} # cols = number of regressors

# calculate DOF
ndof=$((${n_TRs}-${n_regressors}-1)) #N-k-1
echo "ndof is $ndof"

# find t-stat threshold for a < alpha
tstat=$( cdf -p2t fitt 0.${alpha} ${ndof} )
tstat=${tstat##* }
echo "tstat is $tstat"

# convert tstat to z score by FDR correction and threshold significant voxels
3dFDR -input ${tstat_file}.nii.gz -mask ${brain_mask}.nii.gz -prefix ${tstat_file}_fdr.nii.gz # FDR correction
fslmaths ${tstat_file}_fdr.nii.gz -thr ${tstat} ${tstat_file}_fdr${alpha}.nii.gz # threshold by tstat (includes pos and neg significant tstats)

# find only significant POSITIVE voxels
fslmaths ${tstat_file}.nii.gz -thr 0 -bin ${tstat_file}_thrp.nii.gz # find where tstat is positive
3dcalc -a ${tstat_file}_fdr${alpha}.nii.gz -b ${tstat_file}_thrp.nii.gz \
  -expr 'a*b' -prefix ${tstat_file}_fdrp${alpha}.nii.gz # find intersection of positive tstat and significant tstat maps --> only significant positive voxels

# remove intermediate files
rm ${tstat_file}_fdr.nii.gz ${tstat_file}_fdr${alpha}.nii.gz ${tstat_file}_thrp.nii.gz

# Calculate percent activated voxels in mask
actExtent=`3dBrickStat -positive -nonan -count -mask ${mask}.nii.gz ${tstat_file}_fdrp${alpha}.nii.gz`
  totROIvox=`3dBrickStat -count -non-zero ${mask}.nii.gz`
  actExtentPer=`printf "%.6f\n" $((10**6 * $actExtent/$totROIvox))e-6` # gives 6 digits after decimal

# Save outputs to text files
echo ${meanBcoef} > ${output_dir}/${prefix}_meanBcoef.txt
echo ${medBcoef} > ${output_dir}/${prefix}_medianBcoef.txt
echo ${actExtentPer} > ${output_dir}/${prefix}_percentActivated.txt
