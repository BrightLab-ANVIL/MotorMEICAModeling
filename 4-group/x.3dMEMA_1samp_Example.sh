#!/bin/bash
# This script is an example of how to run a 1-sample t-test using AFNI's 3dMEMA
## Change subjects, sessions, and file paths as needed
## Use data from both runs in one model for this analysis

parent_dir="~BIDS"
version="v1"
output_dir="${parent_dir}/derivatives/group"
mask="${FSLDIR}/data/standard/MNI152_T1_2mm_brain" # whole brain mask

for model in Basic ConsOrth TaskCorr
do

for cond1 in Rgrip Lgrip; do #regressor/conditions to run analysis on (Shoulder will have only 1)

output_folder="${output_dir}/3dMEMA_${cond1}-0_${model}_${version}"

if [ ! -d ${output_folder} ]
then
  mkdir ${output_folder}
fi

run3dMEMA="3dMEMA -prefix ${output_folder}/3dMEMA_${cond1}-0_${model}_${version}"
run3dMEMA="${run3dMEMA} -conditions ${cond1}"

run3dMEMA="${run3dMEMA} -set ${cond1}"
for subject in sub-01 sub-02 sub-03 sub-04 sub-05
do
  for session in ses-01 ses-03 #Include both runs for this variable
  do
    bcoef="${parent_dir}/derivatives/${subject}/${session}/func/${cond1}/output.GLM_${model}_${version}/${subject}_${session}_${cond1}_bcoef_func2stand.nii.gz"
    tstat="${parent_dir}/derivatives/${subject}/${session}/func/${cond1}/output.GLM_${model}_${version}/${subject}_${session}_${cond1}_tstat_func2stand.nii.gz"
    run3dMEMA="${run3dMEMA} ${subject} ${bcoef} ${tstat}"

  if [ ! -f ${bcoef} ]
  then
    for stat in bcoef tstat
    do
      ./x.PreProc_Transform_nonlin.sh "${parent_dir}/derivatives/${subject}/${session}/func/${cond1}/output.GLM_${model}_${version}/${subject}_${session}_${cond1}_${stat}" \
         "${mask}" \
         "${parent_dir}/derivatives/${subject}/func/${task}/output.reg/${subject}_${task}_func2stand_warp" \
         "${parent_dir}/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}" \
         func2stand
    done
  fi

  done
done

run3dMEMA="${run3dMEMA} -jobs 8"
run3dMEMA="${run3dMEMA} -max_zeros 0.25 -model_outliers"
run3dMEMA="${run3dMEMA} -mask ${mask}.nii.gz "

eval ${run3dMEMA}

done
done
