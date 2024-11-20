# MotorOrth
Testing orthogonalization of ME-ICA components for motor-task analysis

## Motor calculations
*FDcorrCalc.m*: Function to calculate average FD and correlations of motion regressors with task regressor(s)

*RUN_FDcorrCalc_Example.m*: Example script to call FDcorrCalc.m for every dataset in a study

## tedana / Orthogonalization
*x.tedana_extReg.sh*: Example script to create the required inputs and run tedana with external regressors

*demo_external_regressors_motion_task_models.json*: Tedana automatic classification decision tree to use (included as part of tedana v24.0.2)
