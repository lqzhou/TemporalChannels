function obj_fun = tch_obj_fun_2ch_exp_rect(roi, model)
% Generates anonymous objective function that can be passed to fmincon for
% the 2ch-exp-rect model (2-channel model with adapted sustained and
% rectified transient channels).
% 
% INPUTS:
%   1) roi: tchROI object containing single session
%   2) model: tchModel object for the same session
% 
% OUTPUTS:
%   obj_fun: anonymous objective function in the form of y = f(x0), where
%   x0 is a vector of parameters to evaluate and y is the sum of squared
%   residual error between model predictions and run response time series
% 
% AS 10/2017

if ~strcmp(model.type, '2ch-exp-rect'); error('Incompatible model type'); end
stim = model.stim; nruns = size(stim, 1); npreds = size(stim{1}, 2);
fs = model.fs; tr = model.tr; irfs = model.irfs;
run_avgs = roi.run_avgs; baseline = roi.baseline;
param_names = fieldnames(model.params); nparams = length(param_names);

adapt_fun = @(y) exp(-(1:60000) / y);
conv_snS = @(x, y) cellfun(@(X, Y, ON, OFF) code_exp_decay(X, ON, OFF, Y, fs), ...
    cellfun(@(XX) convolve_vecs(XX, irfs.nrfS{1}, 1, 1), x, 'uni', false), ...
    repmat({adapt_fun(y)}, nruns, 1), model.onsets, model.offsets, 'uni', false);
conv_snT = @(x) cellfun(@(X) rectify(convolve_vecs(X, irfs.nrfT{1}, 1, 1), 'positive'), ...
    x, 'uni', false);
conv_nbS = @(x, y) cellfun(@(NS) convolve_vecs(NS, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snS(x, y), 'uni', false);
conv_nbT = @(x) cellfun(@(NT) convolve_vecs(NT, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snT(x), 'uni', false);
pred_bsS = @(x, y, b) cellfun(@(PS, BS) PS .* repmat(BS, size(PS, 1), 1), ...
    conv_nbS(x, y), repmat({b}, nruns, 1), 'uni', false);
pred_bsT = @(x, b) cellfun(@(PT, BT) PT .* repmat(BT, size(PT, 1), 1), ...
    conv_nbT(x), repmat({b}, nruns, 1), 'uni', false);
comp_bs = @(m, b0) cellfun(@(M, B0) M - repmat(B0, size(M, 1), 1), ...
    m, b0, 'uni', false);
calc_br = @(x, y, b, m, b0) cellfun(@(SS, ST, M) (sum([SS ST], 2) - M) .^ 2, ...
    pred_bsS(x, y, b(1:npreds)), pred_bsT(x, b([1:npreds] + npreds)), ...
    comp_bs(m, b0), 'uni', false);
calc_me = @(x, y, b, m, b0) sum(cell2mat(calc_br(x, y, b, m, b0)));
obj_fun = @(x) calc_me(stim, x(1), x([1:npreds * 2] + nparams), run_avgs, baseline);

end
