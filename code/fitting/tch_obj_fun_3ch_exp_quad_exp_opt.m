function obj_fun = tch_obj_fun_3ch_exp_quad_exp_opt(roi, model)
% Generates anonymous objective function that can be passed to fmincon for
% the 3ch-exp-quad-exp model (3-channel model with optimized adapated 
% sustained, quadratic transient, and exponential persistent channels).
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
% AS 1/2018

if ~strcmp(model.type, '3ch-exp-quad-exp-opt'); error('Incompatible model type'); end
stim = model.stim; nruns = size(stim, 1); irfs = model.irfs; fs = model.fs;
run_avgs = roi.run_avgs; baseline = roi.baseline; tr = roi.tr;
% generate IRFs/filters for optimization
nrfS_fun = @(tau) tch_irfs('S', tau);
nrfT_fun = @(tau) tch_irfs('T', tau);
adapt_fun = @(tau_ae) exp(-(1:60000) / (tau_ae * 1000));
persist_fun = @(tau_pe) exp(-(1:12000) / (tau_pe * 1000));
% sustained response: (stimulus * sustained IRF) x exponential[tau_ae]
conv_snS = @(s, tau, tau_ae) cellfun(@(X, Y, ON, OFF) code_exp_decay(X, ON, OFF, Y, fs), ...
    cellfun(@(XX, YY) convolve_vecs(XX, YY, 1, 1), s, repmat({nrfS_fun(tau)}, nruns, 1), 'uni', false), ...
    repmat({adapt_fun(tau_ae)}, nruns, 1), model.onsets, model.offsets, 'uni', false);
% transient response: (stimulus * transient IRF)^2
conv_snT = @(s, tau) cellfun(@(X, Y) convolve_vecs(X, Y, 1, 1) .^ 2, ...
    s, repmat({nrfT_fun(tau)}, nruns, 1), 'uni', false);
% persistent response: persistent function x exponential[k]
poffsets = cellfun(@(X, Y) [X(2:end) Y], model.onsets, model.run_durs, 'uni', false);
conv_snP = @(s, tau_pe) cellfun(@(X, Y, ON, OFF) code_exp_decay(X, ON, OFF, Y, fs), ...
    cellfun(@code_persist_act, s, 'uni', false), repmat({persist_fun(tau_pe)}, nruns, 1), ...
    model.offsets, poffsets, 'uni', false);
% sustained BOLD: sustained response * HRF
conv_nbS = @(s, tau, tau_ae) cellfun(@(NS) convolve_vecs(NS, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snS(s, tau, tau_ae), 'uni', false);
% transient BOLD: transient response * HRF
conv_nbT = @(s, tau) cellfun(@(NT) convolve_vecs(NT, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snT(s, tau), 'uni', false);
% persistent BOLD: persistent response * HRF
conv_nbP = @(s, tau_pe) cellfun(@(NP) convolve_vecs(NP, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snP(s, tau_pe), 'uni', false);
% channel predictors: [sustained BOLD, transient BOLD, persistent BOLD]
conv_nb = @(s, tau, tau_ae, tau_pe) cellfun(@(S, T, P) [S T P], ...
    conv_nbS(s, tau, tau_ae), conv_nbT(s, tau), conv_nbP(s, tau_pe), 'uni', false);
% measured signal: time series - baseline estimates
comp_bs = @(m, b0) cellfun(@(M, B0) M - repmat(B0, size(M, 1), 1), ...
    m, b0, 'uni', false);
% channel weights: channel predictors \ measured signal
comp_ws = @(s, tau, tau_ae, tau_pe, m, b0) cell2mat(conv_nb(s, tau, tau_ae, tau_pe)) \ cell2mat(comp_bs(m, b0));
% predicted signal: channel predictors x channel weights
pred_bs = @(s, tau, tau_ae, tau_pe, m, b0) cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
    conv_nb(s, tau, tau_ae, tau_pe), repmat({comp_ws(s, tau, tau_ae, tau_pe, m, b0)'}, nruns, 1), 'uni', false);
% model residuals: (predicted signal - measured signal)^2
calc_br = @(s, tau, tau_ae, tau_pe, m, b0) cellfun(@(S, M) (sum(S, 2) - M) .^ 2, ...
    pred_bs(s, tau, tau_ae, tau_pe, m, b0), comp_bs(m, b0), 'uni', false);
% model error: summed squared residuals for all run time series
calc_me = @(s, tau, tau_ae, tau_pe, m, b0) sum(cell2mat(calc_br(s, tau, tau_ae, tau_pe, m, b0)));
obj_fun = @(x) calc_me(stim, x(1), x(2), x(3), run_avgs, baseline);

end