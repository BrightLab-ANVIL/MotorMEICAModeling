#!/bin/bash

# Calculate metrics on subject-level GLM outputs and save to text files

#######################################
# Choose analysis options below (1=run)
#######################################

DO_tSNR=0
DO_extract=0
DO_tstat=0
## END task loop
DO_corr=0

parent_dir=""

session="ses-01"
version="v1"
studyName="HealthyHand" # MShand, MSfoot, Shoulder

################################
################################
################################

for subject in sub-02 sub-03 sub-04 sub-05 sub-07 sub-10 sub-11
do

echo "*********************"
echo "Processing ${subject}"
echo "*********************"

for session in ses-01 ses-02
do

echo "*********************"
echo "Processing ${session}"
echo "*********************"

for model in Basic ConsOrth TaskCorr
do

echo "*********************"
echo "Processing ${model}"
echo "*********************"

for task in MOTOR MOTORmotion
do

echo "*********************"
echo "Processing ${task}"
echo "*********************"

if [ "${DO_tSNR}" -eq 1 ]

then
  echo "****************************"
  echo "Running tSNR calculation"
  echo "****************************"

  # Create pre-central gyrus grey matter mask if it does not exist
  if [ ! -f "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/GM_precentralGyrus_mask.nii.gz" ]; then
    # Create grey matter mask from fsl_anat segmentation output
    fslmaths ${parent_dir}/BIDS/derivatives/${subject}/anat/T1_fast_pve_1.nii.gz -thr 0.5 -bin ${parent_dir}/BIDS/derivatives/${subject}/anat/GM_mask_p5.nii.gz

    # Transform grey matter regressor to functional space
    ./x.PreProc_Transform_lin.sh ${parent_dir}/BIDS/derivatives/${subject}/anat/GM_mask_p5 \
      ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.bet/${subject}_${task}_SBREF_1_bet_ero \
      ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/${subject}_${task}_anat2func \
      ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg \
      anat2func

    # Transform pre-central gyrus mask to functional space
    ./x.PreProc_Transform_nonlin.sh ${parent_dir}/Other/Masks/harvardoxford-cortical_prob_Precentral_Gyrus_2mm \
      ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.bet/${subject}_${task}_SBREF_1_bet_ero \
      ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/${subject}_${task}_stand2func_warp \
      ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg \
      stand2func

    # Find intersection of grey matter and pre-central gyrus masks to use in tSNR calculation
    3dcalc -a ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/GM_mask_p5_anat2func.nii.gz \
      -b ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/harvardoxford-cortical_prob_Precentral_Gyrus_2mm_stand2func.nii.gz \
      -expr 'a*b' -prefix ${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/GM_precentralGyrus_mask.nii.gz
  fi

  # Calculate tSNR and save to output file
  errts=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_errts
  mean=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.SPC/${subject}_${task}_mean
  mask=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/GM_precentralGyrus_mask
  output_dir=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.tSNR
  prefix=${subject}_${task}_${model}_${version}

  ./x.tSNR_calc.sh ${errts} ${mean} ${mask} ${output_dir} ${prefix}

  read -ra meanTSNR < ${output_dir}/${prefix}_meantSNR.txt
  read -ra medTSNR < ${output_dir}/${prefix}_mediantSNR.txt

  echo -e ${studyName} '\t' ${subject} '\t' ${session} '\t' ${task} '\t' ${model} '\t' ${meanTSNR} '\t' ${medTSNR} >> ${parent_dir}/${studyName}_tSNR.txt

fi

if [ "${DO_extract}" -eq 1 ]

then
  echo "****************************"
  echo "Extract bcoef / tstat maps"
  echo "****************************"

  ## Extract bcoef and tstat from bucket (for each task regressor) **** HAVE TO CONFIRM THE BRICK NUMBERS FOR YOUR DATASET ***
  ## I accidentally flipped the order of right / left regressors for MOTORmotion

  # Rgrip
  3dbucket -prefix "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_Rgrip_bcoef.nii.gz" \
    "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_bucket.nii.gz"[41]

  3dbucket -prefix "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_Rgrip_tstat.nii.gz" \
    "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_bucket.nii.gz"[42]

  # Lgrip
  3dbucket -prefix "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_Lgrip_bcoef.nii.gz" \
    "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_bucket.nii.gz"[44]

  3dbucket -prefix "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_Lgrip_tstat.nii.gz" \
    "${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_bucket.nii.gz"[45]

fi

if [ "${DO_tstat}" -eq 1 ]

then
  echo "****************************"
  echo "Running t-stat calculation"
  echo "****************************"

  for reg in Rgrip Lgrip
  do

    tstat_file=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.GLM_${model}_${version}/${subject}_${task}_${reg}_tstat
    mask=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.reg/GM_precentralGyrus_mask ## need to find a more appropriate mask to use
    output_dir=${parent_dir}/BIDS/derivatives/${subject}/func/${task}/output.tstat
    prefix=${subject}_${task}_${reg}_${model}_${version}

    ./x.tstat_calc.sh ${tstat_file} ${mask} ${output_dir} ${prefix}

    read -ra meanTstat < ${output_dir}/${prefix}_meanTstat.txt
    read -ra medTstat < ${output_dir}/${prefix}_medianTstat.txt

    echo -e ${studyName} '\t' ${subject} '\t' ${session} '\t' ${task} '\t' ${model} '\t' ${reg} '\t' ${meanTstat} '\t' ${medTstat} >> ${parent_dir}/${studyName}_tstat.txt

  done

fi

done ### END TASK LOOP ###

## IMPORTANT: whichever variable you are trying to compare spatial correlations between (e.g. session) should be your INNERMOST code loop
# That loop should END above
if [ "${DO_corr}" -eq 1 ]

then
  echo "****************************"
  echo "Running spatial correlation"
  echo "****************************"

  for reg in Rgrip Lgrip
  do

    # Both bcoef maps must be in the SAME FUNCTIONAL SPACE
    # First convert map 2 to map 1's functional space if necessary

    if [ ! -f ${parent_dir}/BIDS/derivatives/${subject}/func/MOTORmotion/output.GLM_${model}_${version}/${subject}_MOTORmotion_${reg}_bcoef_func2funcMOTOR.nii.gz ]
    then
      # combine func2anat ses-02 w/ anat2func ses-01 --> func ses-02 to func ses-01
      convert_xfm -omat ${parent_dir}/BIDS/derivatives/${subject}/func/MOTORmotion/output.reg/${subject}_MOTORmotion_func2funcMOTOR.mat \
        -concat ${parent_dir}/BIDS/derivatives/${subject}/func/MOTOR/output.reg/${subject}_MOTOR_anat2func.mat \
        ${parent_dir}/BIDS/derivatives/${subject}/func/MOTORmotion/output.reg/${subject}_MOTORmotion_func2anat.mat

      # convert ses-02 func to ses-01 func space
      ./x.PreProc_Transform_lin.sh "${parent_dir}/BIDS/derivatives/${subject}/func/MOTORmotion/output.GLM_${model}_${version}/${subject}_MOTORmotion_${reg}_bcoef" \
        "${parent_dir}/BIDS/derivatives/${subject}/func/MOTOR/output.bet/${subject}_MOTOR_SBREF_1_bet_ero" \
        "${parent_dir}/BIDS/derivatives/${subject}/func/MOTORmotion/output.reg/${subject}_MOTORmotion_func2funcMOTOR" \
        "${parent_dir}/BIDS/derivatives/${subject}/func/MOTORmotion/output.GLM_${model}_${version}" \
        func2funcMOTOR
    fi

    bcoef_file1=${parent_dir}/BIDS/derivatives/${subject}/func/MOTOR/output.GLM_${model}_${version}/${subject}_MOTOR_${reg}_bcoef
    bcoef_file2=${parent_dir}/BIDS/derivatives/${subject}/func/MOTORmotion/output.GLM_${model}_${version}/${subject}_MOTORmotion_${reg}_bcoef_func2funcMOTOR
    mask=${parent_dir}/BIDS/derivatives/${subject}/func/MOTOR/output.reg/GM_precentralGyrus_mask
    output_dir=${parent_dir}/BIDS/derivatives/${subject}/func/MOTOR/output.spatialCorr
    prefix=${subject}_${reg}_${model}_${version}

    ./x.spatialCorr_calc.sh ${bcoef_file1} ${bcoef_file2} ${mask} ${output_dir} ${prefix}

    read -ra spatialCorr < ${output_dir}/${prefix}_spatialCorr.txt

    echo -e ${studyName} '\t' ${subject} '\t' ${session} '\t' ${task} '\t' ${model} '\t' ${reg} '\t' ${spatialCorr} >> ${parent_dir}/${studyName}_spatialCorr.txt

  done

fi

done
done
done
