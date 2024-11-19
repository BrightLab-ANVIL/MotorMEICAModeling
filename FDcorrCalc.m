% FD and motion correlation calculations

function [FDavg, corrX, corrY, corrZ, corrRoll, corrPitch, corrYaw] = FDcorrCalc(motion_file, task_file1, task_file2)
    % set default values so task_file2 can be an optional argument
    arguments
        motion_file = 0;
        task_file1 = 0;
        task_file2 = 0;
    end

z = motion_file(:,4); % superior
y = motion_file(:,5); % left
x = motion_file(:,6); % posterior
y_deg = motion_file(:,1);
p_deg = motion_file(:,2);
r_deg = motion_file(:,3);

% Convert pitch, roll, yaw to mm
% Use arc length formula and radius of sphere = 50 mm
% arc length = theta/360 * 2 * pi * radius (if theta is in degrees)
rad = 50;
p_mm = p_deg./360.*2.*pi.*rad;
r_mm = r_deg./360.*2.*pi.*rad;
y_mm = y_deg./360.*2.*pi.*rad;

% Create shifted versions of each vector
x_shift = [x(1); x(1:end-1)];
y_shift = [y(1); y(1:end-1)];
z_shift = [z(1); z(1:end-1)];
p_mm_shift = [p_mm(1); p_mm(1:end-1)];
r_mm_shift = [r_mm(1); r_mm(1:end-1)];
y_mm_shift = [y_mm(1); y_mm(1:end-1)];

% Take the difference between original and shifted vectors
x_diff = x - x_shift;
y_diff = y - y_shift;
z_diff = z - z_shift;
p_mm_diff = p_mm - p_mm_shift;
r_mm_diff = r_mm - r_mm_shift;
y_mm_diff = y_mm - y_mm_shift;

% Sum the absolute value of the vectors
FD = abs(x_diff) + abs(y_diff) + abs(z_diff) + abs(p_mm_diff) + ...
    abs(r_mm_diff) + abs(y_mm_diff);

FDavg = mean(FD,'omitnan');

% Calculate motion correlations with task regressor(s)
% Sum task regressors if more than one
if task_file2 == 0
    task = task_file1;
else
    task = task_file1 + task_file2;
end

if size(task,2) > size(task,1)
    task = task';
end

% If task vector is only zeros and ones, use point biserial correlation
% Point biserial reference: https://dx.doi.org/10.4135/9781412952644.n57
if isempty(find(task~=0 & task~=1,1)) == 1
    p = sum(task)/length(task);
    q = 1 - p;

    allMot = zeros(1,6);
    for mot = 1:6
        dir = motion_file(:,mot);
        one_f = dir(task == 1);
        zed_f = dir(task == 0);
        m1_f=mean(one_f);
        m0_f=mean(zed_f);
        s_f=std(dir);

        allMot(mot) = ((m1_f-m0_f)/s_f)*sqrt(p*q);
    end

    corrX = allMot(:,6);
    corrY = allMot(:,5);
    corrZ = allMot(:,4);
    corrRoll = allMot(:,3);
    corrPitch = allMot(:,2);
    corrYaw = allMot(:,1);

else
    % Pearson correlation
    corrX = corr(task,x);
    corrY = corr(task,y);
    corrZ = corr(task,z);
    corrRoll = corr(task,r_deg);
    corrPitch = corr(task,p_deg);
    corrYaw = corr(task,y_deg);
end

end