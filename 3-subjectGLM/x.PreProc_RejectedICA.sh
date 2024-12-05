#!/bin/sh
# x.PreProc_RejectedICA.sh

# Creates file with rejected ICA components for use in GLM
# The output "rejected_forGLM.1D" contains the components in columns.

# Basic model: REJECTS components that were accepted solely based on task-correlation; NO orthogonalization of rejected ICA components
# ConsOrth model: REJECTS components that were accepted solely based on task-correlation; conservative orthogonalization of rejected ICA components
  # Orthogonalizes ME-ICA rejected components with respect to the task, PETCO2hrf trace, the ME-ICA accepted components, motion parameters, and Legendre polynomials (as described in "ICA-based denoising strategies in breath-hold induced cerebrovascular reactivity mapping with multi echo BOLD fMRI")
# TaskCorr model: ACCEPTS components that were accepted solely based on task-correlation; NO orthogonalization of rejected ICA components

# Prior to using this script, you should have run tedana w/ automatic classification


if [ $# -ne 9 ] && [ $# -ne 10 ]
then
  echo "*****************************************************************************************************"
  echo "Insufficient arguments supplied"
  echo "Input 1 should be the full path to desc-ICA_mixing.tsv file (include file extension)"
  echo "Input 2 should be the full path to desc-tedana_metrics.tsv file (include file extension)"
  echo "Input 3 should be the full path to the demeaned PETCO2 trace convolved with the HRF (do not include file extension - assumes .txt)"
  echo "Input 4 should be the full path to the demeaned motion parameters (do not include file extension - assumes .1D)"
  echo "Input 5 should be the full path to the demeaned motion derivative parameters (do not include file extension - assumes .1D)"
  echo "Input 6 should be the Legendre polynomial degree"
  echo "Input 7 should be the full path to the output directory"
  echo "Input 8 should be the name of the model (Basic, ConsOrth, or TaskCorr)"
  echo "Input 9 should be full path to the demeaned task regressor (do not include file extension - assumes .txt)"
  echo "Input 10 (optional) should be the full path to the second demeaned task regressor (do not include file extension - assumes .txt)"
  echo "*****************************************************************************************************"
  exit
fi

#Define inputs
ica_mix=${1}
metrics=${2}
CO2=${3}
motion=${4}
motion_deriv=${5}
Legendre_degree=${6}
output_dir=${7}
model=${8}
task1=${9}

#If output directory is not present, make it
if [ ! -d ${output_dir} ]
then
  mkdir ${output_dir}
fi

if [ $# -eq 10 ]; then
  task2=${10}
fi

cd ${output_dir}

# Find REJECTED component numbers from tedana file
columnNumber=$(awk -F'\t' 'NR==1 {for (i=1; i<=NF; i++) if ($i == "classification") print i; exit}' "${metrics}")
manRej=`cut -f${columnNumber} ${metrics} | tail -n +2 | grep -n rejected | cut -d : -f1 | tr "\n" " "`

manRejArr=( $manRej ) #change string to array
for (( i = 0 ; i < ${#manRejArr[@]} ; i++ )) do  (( manRejArr[$i]=${manRejArr[$i]} - 1 )) ; done #subtract 1 from each number to start indexing at 0

printf -v manRejCom '%s,' "${manRejArr[@]}" #separate array by commas instead of spaces
echo "rejected components: ${manRejCom[@]}"

# Find ACCEPTED component numbers from tedana file
manAcc=`cut -f${columnNumber} ${metrics} | tail -n +2 | grep -n accepted | cut -d : -f1 | tr "\n" " "`

manAccArr=( $manAcc ) #change string to array
for (( i = 0 ; i < ${#manAccArr[@]} ; i++ )) do  (( manAccArr[$i]=${manAccArr[$i]} - 1 )) ; done #subtract 1 from each number to start indexing at 0

printf -v manAccCom '%s,' "${manAccArr[@]}" #separate array by commas instead of spaces
echo "accepted components: ${manAccCom[@]}"

if [ $model == 'Basic' ] || [ $model == 'ConsOrth' ]; then
# REJECT components that were accepted solely due to high task-correlation

  # Find 'Fits task' component numbers from tedana file
  tagColNumber=$(awk -F'\t' 'NR==1 {for (i=1; i<=NF; i++) if ($i == "classification_tags") print i; exit}' "${metrics}")
  taskCom=`cut -f${tagColNumber} ${metrics} | tail -n +2 | grep -n task | cut -d : -f1 | tr "\n" " "`

  taskComArr=( $taskCom ) #change string to array
  for (( i = 0 ; i < ${#taskComArr[@]} ; i++ )) do  (( taskComArr[$i]=${taskComArr[$i]} - 1 )) ; done #subtract 1 from each number to start indexing at 0

  printf -v taskFitCom '%s,' "${taskComArr[@]}" #separate array by commas instead of spaces
  echo "task fit components: ${taskFitCom[@]}"

  # Save numbers of task-correlated components to file for future use
  echo ${taskFitCom} > ${output_dir}/taskCorr_compList.txt

  # Add task-correlated components to rejected component list
  manRejCom="${manRejCom}${taskFitCom}"
  manRejCom=`echo $manRejCom | sed 's/\(.*\),/\1 /'` # remove trailing comma
  manRejCom=( $manRejCom ) #change string to array
  echo "corrected rejected components: ${manRejCom[@]}"

  # Remove task-correlated components from accepted component list
  for del in "${taskComArr[@]}"; do
    manAccCom=${manAccCom/$del,}
  done
  echo "corrected accepted components: ${manAccCom[@]}"

fi

# Create file with REJECTED component timeseries
1dcat ${ica_mix}[${manRejCom[@]}] > ${output_dir}/rejectedTrans.1D
1dtranspose ${output_dir}/rejectedTrans.1D > ${output_dir}/rejected.1D

# Create file with ACCEPTED component timeseries
1dcat ${ica_mix}[${manAccCom[@]}] > ${output_dir}/acceptedTrans.1D
1dtranspose ${output_dir}/acceptedTrans.1D > ${output_dir}/accepted.1D


if [ $model == 'ConsOrth' ]; then

  if [ $# -eq 9 ]; then
    # Orthogonalize rejected components to accepted components, CO2 trace, motion, task, and polynomials
    3dTproject -ort acceptedTrans.1D \
    -ort ${CO2}.txt \
    -ort ${motion}.1D \
    -ort ${motion_deriv}.1D \
    -ort ${task1}.txt \
    -polort ${Legendre_degree}  \
    -prefix rejected_ort.1D \
    -input rejected.1D
  fi

  if [ $# -eq 10 ]; then
    # Orthogonalize rejected components to accepted components, CO2 trace, motion, task, and polynomials
    3dTproject -ort acceptedTrans.1D \
    -ort ${CO2}.txt \
    -ort ${motion}.1D \
    -ort ${motion_deriv}.1D \
    -ort ${task1}.txt \
    -ort ${task2}.txt \
    -polort ${Legendre_degree}  \
    -prefix rejected_ort.1D \
    -input rejected.1D
  fi

  1d_tool.py -infile rejected_ort.1D -write rejected_forGLM.1D

elif [ $model == 'Basic' ] || [ $model == 'TaskCorr' ]; then

  1d_tool.py -infile rejected.1D -write rejected_forGLM.1D

fi
