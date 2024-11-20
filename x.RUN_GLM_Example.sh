#!/bin/sh

#######################################
# Choose analysis options below (1=run)
#######################################
DO_RejICA=1
DO_GLM_REML=1

parent_dir=""
version="v1"

################################
################################
################################

for subject in sub-03
do

echo "*********************"
echo "Processing ${subject}"
echo "*********************"

########### START TASK LOOP ######################################
for task in MOTOR
do

echo "*********************"
echo "Processing ${task}"
echo "*********************"

for session in ses-01 #ses-02
do

echo "*********************"
echo "Processing ${session}"
echo "*********************"

for model in Basic ConsOrth TaskCorr
do

echo "*********************"
echo "Processing ${model}"
echo "*********************"

if [ "${DO_RejICA}" -eq 1 ]

then
  echo "****************************"
  echo "Running Rejected ICA"
  echo "****************************"

  ica_mix=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.tedana_auto/desc-ICA_mixing.tsv
  metrics=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.tedana_auto/desc-tedana_metrics.tsv
  CO2=${parent_dir}/Other/HGDev_${subject}/phys_regressors/${task}/HGDev_${subject}_${task}_CO2_HRFconv_rm10
  motion=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.mc/${subject}_${task}_rm10_1_mc_demean
  motion_deriv=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.mc/${subject}_${task}_rm10_1_mc_deriv_demean
  Legendre_degree=4
  output_dir=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}

  # if you needed to tranpose the task regressors to run x.tedana_extReg.sh, you will need use those versions here as well
  task1=${parent_dir}/Other/TaskRegressors/${subject}_${task}_RGrip_Force_HRFconv_trans
  task2=${parent_dir}/Other/TaskRegressors/${subject}_${task}_LGrip_Force_HRFconv_trans

  ./x.PreProc_RejectedICA.sh ${ica_mix} ${metrics} ${CO2} ${motion} ${motion_deriv} ${Legendre_degree} ${output_dir} ${model} ${task1} ${task2}

fi

if [ "${DO_GLM_REML}" -eq 1 ]

then
  echo "****************************"
  echo "Running Subject-level GLM"
  echo "****************************"

  input_file=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.SPC/${subject}_${task}_SPC.nii.gz
  motion_file=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.mc/${subject}_${task}_rm10_1_mc_demean.1D
  motion_deriv_file=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.mc/${subject}_${task}_rm10_1_mc_deriv_demean.1D
  CO2_file=${parent_dir}/Other/HGDev_${subject}/phys_regressors/${task}/HGDev_${subject}_${task}_CO2_HRFconv_rm10.txt
  rejComp_file=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/rejected_forGLM.1D
    rej_rowcol=`1d_tool.py -show_rows_cols -infile ${rejComp_file} -verb 0` # find no of rows and cols in rejected comp file
    arr=($rej_rowcol)
  num_ica=${arr[0]} # number of rejected ICA components in file
  sub_ID=${subject}_${task}
  output_dir=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}
  mask=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.bet/${subject}_${task}_SBREF_1_bet_mask_ero.nii.gz
  task1_file=${parent_dir}/Other/TaskRegressors/${subject}_${task}_RGrip_Force_HRFconv.txt
  task2_file=${parent_dir}/Other/TaskRegressors/${subject}_${task}_LGrip_Force_HRFconv.txt

  ./x.GLM_REML_ICA.sh ${input_file} ${motion_file} ${motion_deriv_file} ${CO2_file} ${rejComp_file} ${num_ica} ${sub_ID} ${output_dir} ${mask} ${task1_file}

fi

done
done
done
done
