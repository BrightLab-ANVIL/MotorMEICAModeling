#!/bin/bash
# Prepping data to run tedana with external regressors
parent_dir=""

for subject in sub-03 sub-05
do

if [ ! -f ${parent_dir}/BIDS/derivatives/${subject}/anat/CSF_mask_p5.nii.gz ]
then
  ## Prepare CSF regressor
  # Create CSF mask from fsl_anat segmentation output
  fslmaths ${parent_dir}/BIDS/derivatives/${subject}/anat/T1_fast_pve_0.nii.gz -thr 0.5 -bin ${parent_dir}/BIDS/derivatives/${subject}/anat/CSF_mask_p5.nii.gz
fi

for session in ses-01
do

for task in MOTOR
do

if [ ! -f ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/CSF_meanTS.txt ]
then
  # Transform CSF regressor to functional space
  ./x.PreProc_Transform_lin.sh ${parent_dir}/BIDS/derivatives/${subject}/anat/CSF_mask_p5 \
    ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.bet/${subject}_${task}_SBREF_1_bet_ero \
    ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/${subject}_${task}_anat2func \
    ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg \
    anat2func

  # Find mean timeseries within CSF mask
  fslmeants -i "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.tedana_bet/desc-optcom_bold.nii.gz" \
    -o "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/CSF_meanTS.txt" \
    -m "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/CSF_mask_p5_anat2func.nii.gz"
fi

## Combine CSF, motion, and task into .tsv file
CSF=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/CSF_meanTS.txt
motion=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.mc/${subject}_${task}_rm10_1_mc_demean.1D
motionDeriv=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.mc/${subject}_${task}_rm10_1_mc_deriv_demean.1D
task1=${parent_dir}/Other/TaskRegressors/${subject}_${task}_RGrip_Force_HRFconv
task2=${parent_dir}/Other/TaskRegressors/${subject}_${task}_LGrip_Force_HRFconv

# If needed, tranpose task regressors so they are in 1 column instead of 1 row
1dtranspose ${task1}.txt > ${task1}_trans.txt
1dtranspose ${task2}.txt > ${task2}_trans.txt

# Concatenate by column and add column headers
paste ${motion} ${motionDeriv} ${CSF} ${task1}_trans.txt ${task2}_trans.txt > ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extReg.txt
awk -v OFS='\t' '{ $1=$1; print }' ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extReg.txt \
  > ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extRegNohdr.tsv
awk 'BEGIN {print "Mot_X\tMot_Y\tMot_Z\tMot_Pitch\tMot_Roll\tMot_Yaw\tMot_d1_X\tMot_d1_Y\tMot_d1_Z\tMot_d1_Pitch\tMot_d1_Roll\tMot_d1_Yaw\tCSF\tSignal_Right\tSignal_Left"} {print $0}' ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extRegNohdr.tsv \
  > ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extReg.tsv

# remove temporary files
rm ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extReg.txt
rm ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extRegNohdr.tsv

## Re-run tedana
tedana -d "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.betmask/${subject}_${task}_rm10_1_mc_brain.nii.gz" \
  "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.betmask/${subject}_${task}_rm10_2_mc_brain.nii.gz" \
  "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.betmask/${subject}_${task}_rm10_3_mc_brain.nii.gz" \
  "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.betmask/${subject}_${task}_rm10_4_mc_brain.nii.gz" \
  "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.betmask/${subject}_${task}_rm10_5_mc_brain.nii.gz" \
  -e 10.8 28.03 45.26 62.49 79.72 \
  --out-dir "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.tedana_auto" \
  --tree "${parent_dir}/demo_external_regressors_motion_task_models.json" \
  --external "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/${subject}_${session}_${task}_extReg.tsv" \
  --mix "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.tedana_bet/desc-ICA_mixing.tsv" \
  --mask "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.bet/${subject}_${task}_SBREF_1_bet_mask_ero.nii.gz"

done
done
done
