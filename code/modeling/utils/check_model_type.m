function optimize_flag = check_model_type(model_type)
% Function that checks if the model type argument passed as input to 
% tchModel object is a valid model implemented in the code. 
% INPUT
%   model_type: model name passed to tchModel (string)
% 
% OUTPUT
%   Error if input does not match a valid_model string, otherwise:
%   optimize_flag: 1 if model requires nonlinear optimization and 0 if not
% 
% AS 10/2017

valid_models = {'1ch-lin' '1ch-balloon' '1ch-pow' '1ch-div' '1ch-dcts' '1ch-exp' ...
    '2ch-lin-lin' '2ch-lin-htd' '2ch-lin-quad' '2ch-lin-rect' ...
    '2ch-pow-quad' '2ch-pow-rect' '2ch-div-quad' '2ch-exp-quad' '2ch-exp-rect' ...
    '3ch-lin-quad-exp' '3ch-lin-rect-exp' '3ch-pow-quad-exp' '3ch-pow-rect-exp' ...
    '3ch-exp-quad-exp' '3ch-exp-rect-exp' ...
    '2ch-lin-quad-opt' '2ch-lin-rect-opt' ...
    '3ch-lin-quad-exp-opt' '3ch-lin-rect-exp-opt'};
if sum(strcmp(model_type, valid_models)) == 0; error('Invalid model'); end
optimize_flag = 0; opt_strs = {'-opt' '-exp' '-pow' '-div' '-dcts'};
if contains(model_type, opt_strs); optimize_flag = 1; end

end
