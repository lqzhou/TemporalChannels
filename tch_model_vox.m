function [vox, model] = tch_model_vox(type, exps_fit, exps_val)
% Wrapper function that fits a temporal model object (tchModel) to each
% voxel in a voxel time series object (tchVoxel).. To validate the solution, 
% include the optional fourth input to predict data from 'exps_val' using a
% model fit to 'exps_fit'.
% 
% INPUTS
%   1) type: which type of model to use
%   2) exps_fit: list of experiments for fitting the model (e.g., {'Exp1' 'Exp2'})
%   3) exps_val: list of experiments for validating the fit (optional)
% 
% OUTPUTS
%   1) vox: fitted tchVoxel object containing measured and predicted responses
%   2) model: tchModel object used to fit and predict voxel responses
% 
% EXAMPLES
% 
% Fit a GLM to multiple experiments in each voxel:
% [vox, model] = model_vox('glm', {'Exp1' 'Exp2' 'Exp3'});
% 
% Cross-validate the fit of the 2ch model using independent data:
% [vox, model] = model_vox('2ch', {'Exp1' 'Exp2'}, {['Exp3'});
% 
% AS 8/2017


%% Setup paths and check inputs

% add paths to class objects and helper functions
mpath = fileparts(mfilename('fullpath'));
addpath(genpath(mpath));

% determine whether performing cross-validations
if nargin == 3
    cv_flag = 1;
elseif nargin == 2
    cv_flag = 0;
else
    error('Unexpected input arguements.');
end


%% Fit the model to fit_exps

% setup tchVoxel object for fitting tchModel
vox(1) = tchVoxel(name, exps_fit);
fprintf('\nExtracting run time series...\n')
vox(1) = tch_runs(vox(1));

% setup tchModel object to apply to tchVox
model(1) = tchModel(type, exps_fit, vox(1).sessions);
fprintf('Coding the stimulus...\n')
model(1) = code_stim(model(1));
fprintf('Generating predictors for %s model...\n', type)
model(1) = pred_runs(model(1));
model(1) = pred_trials(model(1));

% fit tchModel to tchVoxel
fprintf('Extracting trial time series...\n')
vox(1) = tch_trials(vox(1), model(1));
fprintf('Fitting the model...\n')
[vox(1), model(1)] = tch_fit(vox(1), model(1), 1);


%% validation the model on test_exps if applicable

if cv_flag
    fprintf('Performing validation...\n')
    % setup tchVoxel and tchModel objects for validation
    vox(2) = tchVoxel(exps_val);
    vox(2) = tch_runs(vox(2));
    model(2) = tchModel(type, exps_val, vox(2).sessions);
    model(2) = code_stim(model(2));
    model(2) = pred_runs(model(2));
    model(2) = pred_trials(model(2));
    % setup model struct by fitting model directly to data
    vox(2) = tch_trials(vox(2), model(2));
    [vox(2), model(2)] = tch_fit(vox(2), model(2));
    % use model fit to data from exps_fit to predict data in exps_val
    vox(2) = tch_recompute(vox(2), model(2), vox(1).model);
end

%% Save results
fname = ['Voxels_' vox(1).model.type '_fit' [vox(1).experiments{:}]];
if cv_flag
    fname = [fname '_val' [vox(2).experiments{:}]];
end
fname = [fname '.mat'];
fpath = fullfile(vox(1).project_dir, 'results', fname);
save(fpath, 'vox', 'model', '-v7.3');

end
