#!/bin/bash
# This script is an example of how to run cluster analysis on output from 3dMEMA
## Change subjects, sessions, and file paths as needed

DO_acf=0
DO_ClustSim=0
DO_Clusterize=0
DO_createROI=0

parent_dir="~BIDS"
version="v1"
output_dir="${parent_dir}/group"
cond2="0"
fxn="3dMEMA"
mask="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz" # whole brain mask

pthr="005" # p-value threshold for clustering
athr="05" # alpha threshold for clustering

for cond1 in Rgrip Lgrip
do

for model in Basic ConsOrth TaskCorr
do

output_folder="${output_dir}/${fxn}_${cond1}-${cond2}_${model}_${version}"

#########################
##### Calculate acf #####
#########################

if [ "${DO_acf}" -eq 1 ]
then
  echo "Running acf"
  echo "*****************"

  # Calculate acf for each individual subject/scan using 3dFWHMx
  for subject in sub-01 sub-02 sub-03 sub-04 sub-05
  do
    for session in ses-01 ses-03 ## USE BOTH RUNS
    do
      run3dFWHMx="3dFWHMx -mask ${parent_dir}/derivatives/${subject}/${session}/func/${cond1}/output.tedana/desc-optcom_bold_mask.nii.gz"
      run3dFWHMx="${run3dFWHMx} -input ${parent_dir}/derivatives/${subject}/${session}/func/${cond1}/output.GLM_REML_${version}/${subject}_${cond1}_errts.nii.gz -acf ${output_folder}/${subject}_${session}_acf_emp.1D"
      run3dFWHMx="${run3dFWHMx} > ${output_folder}/${subject}_${session}_acf.1D" ## EDIT THIS AND ABOVE LINE TO HAVE THE APPROPRIATE VARIABLE (session vs run)
      eval ${run3dFWHMx}
    done
  done

  # Calculate average acf across all subjects/scans
  awk 'FNR == 1 { nfiles++; ncols = NF }
     { for (i = 1; i < NF; i++) sum[FNR,i] += $i
       if (FNR > maxnr) maxnr = FNR
     }
     END {
         for (line = 2; line <= maxnr; line++)
         {
             for (col = 1; col < ncols; col++)
                  printf "  %f", sum[line,col]/nfiles;
             printf "\n"
         }
     }' ${output_folder}/sub-*_acf.1D > ${output_folder}/allSub_acf.1D

fi

##########################
### Cluster simulation ###
##########################

if [ "${DO_ClustSim}" -eq 1 ]
then
  echo "Cluster Simulation"
  echo "*****************"

  # Obtain ACF values
  acf_file="${output_folder}/allSub_acf.1D"

  read -ra values < ${acf_file}

  # Assign the values to individual variables
  value1=${values[0]}
  value2=${values[1]}
  value3=${values[2]}

  # Get cluster information
  3dClustSim -prefix "${output_folder}/${fxn}_${cond1}-${cond2}_${version}_clustSim" \
    -mask ${mask} -acf  ${value1}  ${value2}  ${value3} -iter 10000

fi

##########################
####### Clusterize #######
##########################

if [ "${DO_Clusterize}" -eq 1 ]
then
  echo "Clusterize"
  echo "*****************"

  # Find number of voxels at pthr = .005 and athr =.05 (extract from clustSim file)
  clustSim_file="${output_folder}/3dMEMA_${cond1}-${cond2}_${version}_clustSim.NN1_1sided.1D"
  target_row=4 #p = 0.005
  target_column=3 #a = 0.05
  clustNum=$(awk -v row="$target_row" -v col="$target_column" '/^[^#]/{line_count++; if(line_count==row){for(i=1;i<=NF;i++) if($i!~/^#/){if(++count==col){print $i;exit}}}}' "$clustSim_file" | sed 's/^#.*$//')
  rounded_clustNum=$(( (${clustNum%.*} + 1) ))
  echo "Minimum cluster size is $rounded_clustNum"

  ## Actually threshold and cluster group results based on info from 3dClustSim
  ## You will need to change the parameters manually below based on results of 3dClustSim and the desired clustering (e.g. -1sided, -2sided, -bisided)
  3dClusterize -inset "${output_folder}/${fxn}_${cond1}-${cond2}_${model}_${version}+tlrc.BRIK" \
  -mask ${mask} -ithr 1 -idat 0 -1sided RIGHT_TAIL p=${pthr} -NN 1 -clust_nvox ${rounded_clustNum} \
  -pref_dat "${output_folder}/${fxn}_${cond1}-${cond2}_${model}_${version}_clusters_bcoef_p${pthr}_a${athr}.nii.gz"

  ## Extract stats from group analysis bucket for ease of plotting in FSL as transparent underlay
  # Extract tstat [1]
  3dbucket -prefix "${output_folder}/${fxn}_${cond1}-${cond2}_${model}_${version}_tstat.nii.gz" \
  "${output_folder}/${fxn}_${cond1}-${cond2}_${model}_${version}+tlrc"[1]

  # Extract bcoef [0]
  3dbucket -prefix "${output_folder}/${fxn}_${cond1}-${cond2}_${model}_${version}_bcoef.nii.gz" \
  "${output_folder}/${fxn}_${cond1}-${cond2}_${model}_${version}+tlrc"[0]

fi

done ## End model loop

##########################
####### Create ROI #######
##########################

if [ "${DO_createROI}" -eq 1 ]
then
  echo "Create ROI"
  echo "*****************"

  output_dir_union=${output_dir}/${fxn}_${cond1}-${cond2}_Union_${version}

  if [ ! -d ${output_dir_union} ]
  then
    mkdir ${output_dir_union}
  fi

  # Create cortex and cerebellum ROIs using results from cluster analysis
  # Find union of clusters from all 3 models
  3dcalc -a ${output_dir}/${fxn}_${cond1}-${cond2}_Basic_${version}/${fxn}_${cond1}-${cond2}_Basic_${version}_clusters_bcoef_p${pthr}_a${athr}.nii.gz \
    -b ${output_dir}/${fxn}_${cond1}-${cond2}_ConsOrth_${version}/${fxn}_${cond1}-${cond2}_ConsOrth_${version}_clusters_bcoef_p${pthr}_a${athr}.nii.gz \
    -c ${output_dir}/${fxn}_${cond1}-${cond2}_TaskCorr_${version}/${fxn}_${cond1}-${cond2}_TaskCorr_${version}_clusters_bcoef_p${pthr}_a${athr}.nii.gz \
    -expr 'a+b+c' -prefix ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}.nii.gz

  # Isolate and binarize clusters in pre-central gyrus
  3dcalc -a ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}.nii.gz \
    -b ${parent_dir}/masks/harvardoxford-cortical_prob_Precentral_Gyrus_2mm.nii.gz \
    -expr 'a*b' -prefix ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}_cortex.nii.gz

  fslmaths ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}_cortex.nii.gz -bin \
    ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}_cortex_bin.nii.gz

  # Isolate and binarize clusters in cerebellum
  3dcalc -a ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}.nii.gz \
  -b ${parent_dir}/masks/mni_prob_Cerebellum_p50_2mm.nii.gz \
    -expr 'a*b' -prefix ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}_cerebellum.nii.gz

  fslmaths ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}_cerebellum.nii.gz -bin \
    ${output_dir_union}/${fxn}_${cond1}-${cond2}_Union_${version}_clusters_bcoef_p${pthr}_a${athr}_cerebellum_bin.nii.gz

fi

done ## end regressor loop
