# MotorOrth
Testing orthogonalization of ME-ICA components for motor-task analysis

## 1. Motor calculations
*FDcorrCalc.m*: Function to calculate average FD and correlations of motion regressors with task regressor(s)

*RUN_FDcorrCalc_Example.m*: Example script to call FDcorrCalc.m for every dataset in a study

## 2. tedana
*x.tedana_extReg.sh*: Example script to create the required inputs and run tedana with external regressors

*demo_external_regressors_motion_task_models.json*: Tedana automatic classification decision tree to use (included as part of tedana v24.0.2)

## 3. Subject-level GLM
*x.PreProc_RejectedICA.sh*: Function to prep rejected ICA components w/ or w/o considering task-correlation and w/o or w/o orthogonalization based on the model used (Basic, ConsOrth, TaskCorr)

*x.GLM_REML_ICA.sh*: Function to run subject-level GLM including motion, motion derivatives, CO2, and 1 or 2 task regressors

*x.RUN_GLM_Example.sh*: Example script to run the above two functions

## 4. Group-level analysis
*x.3dMEMA_1samp_Example.sh*: Example script to run 3dMEMA 

*x.Cluster_Example.sh*: Example script to run cluster simulation and creation of cortex and cerebellum ROIs based on results

## 5. Subject-level metrics
*harvardoxford-cortical_prob_Precentral_Gyrus_2mm.nii.gz*: Mask of precentral gyrus from Harvard-Oxford atlas, resampled to 2mm MNI space; for use in creating a mask to calculate metrics within

*mni_prob_Cerebellum_p50_2mm.nii.gz* Mask of cerebellum, thresholded at 50% probability and resampled to 2mm MNI space; for use in creating masks / ROIs

*x.tSNR_calc.sh*: Function to calculate mean and median tSNR within a mask

*x.tstat_calc.sh*: Function to calculate mean and median tSNR within a mask

*x.spatialCorr_calc.sh*: Function to calculate spatial correlation between beta coefficient maps from two runs, within a mask

*x.activation_calc.sh*: Function to calculate mean and median beta coefficient and percent activated voxels within a mask

*x.RUN_Metrics_Example.sh*: Example script to run the above three functions for every dataset in a study and save outputs to text files
