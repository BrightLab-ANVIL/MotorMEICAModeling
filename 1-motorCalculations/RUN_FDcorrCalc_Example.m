% Run FD and motion correlation calculations for a study and save to a table

clear

%% Inputs - EDIT

study = 'HealthyHand'; % e.g. MShand, MSfoot, Shoulder

subs = {'sub-02','sub-03','sub-04','sub-05','sub-07','sub-09','sub-10','sub-11'};
sessions = {'ses-01','ses-02'};
tasks = {'Hand'};

input_dir = '';
output_dir = '';

%% Initialize table to save data
vals = table('Size',[0 6],'VariableTypes',["string","string","string","string","string","double"], ...
    'VariableNames',{'Group','Subject','Session','Task','Metric','Value'});

%% Call FD calc function

for i = 1:length(subs)
    for j = 1:length(sessions)
        for k = 1:length(tasks)
            
            sub = subs{i};
            ses = sessions{j};
            task = tasks{k};
            
            %%%% File paths - EDIT
            % output from volume registration (*_mc_demean.1D)
            motion_file = importdata([input_dir '/BIDS/derivatives/' sub '/func/' task '/output.mc/' sub '_' task '_rm10_1_mc_demean.1D']);
            
            % task regressor(s) BEFORE convolution with HRF, downsampled to TR
            task_file1 = importdata([input_dir '/Other/TaskRegressors/' sub '_' task '_RGrip_noConv.txt']);
            task_file2 = importdata([input_dir '/Other/TaskRegressors/' sub '_' task '_LGrip_noConv.txt']);
                % Run function without task_file2 if there is only 1 task regressor

            % *** EDITED LINE ***
            [FDavg,corrX,corrY,corrZ,corrRoll,corrPitch,corrYaw,R2_adjusted] = FDcorrCalc(motion_file,task_file1,task_file2);

            % Add data to table
            vals = [vals;{study, sub, ses, task, 'FD', FDavg}];
            vals = [vals;{study, sub, ses, task, 'X', corrX}];
            vals = [vals;{study, sub, ses, task, 'Y', corrY}];
            vals = [vals;{study, sub, ses, task, 'Z', corrZ}];
            vals = [vals;{study, sub, ses, task, 'Roll', corrRoll}];
            vals = [vals;{study, sub, ses, task, 'Pitch', corrPitch}];
            vals = [vals;{study, sub, ses, task, 'Yaw', corrYaw}];
            vals = [vals;{study, sub, ses, task, 'AdjR2', R2_adjusted}]; %% ***NEW LINE


        end
    end
end

%% Save table
writetable(vals,[output_dir '/' study '_MotionVals.csv'])
