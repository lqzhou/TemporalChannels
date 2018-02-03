function model = pred_runs_2ch_lin_dquad(model)
% Generates run predictors using the 2 temporal-channel model with linear
% sustained and quadratic + normalized transient channels.

% get design parameters
fs = model.fs; tr = model.tr; stim = model.stim;
nruns_max = size(stim, 1); empty_cells = cellfun(@isempty, stim);
params_names = fieldnames(model.params); params = [];
for pp = 1:length(params_names)
    pname = model.params.(params_names{pp});
    params.(params_names{pp}) = repmat(pname, nruns_max, 1);
end
irfs_names = fieldnames(model.irfs); irfs = [];
for ff = 1:length(irfs_names)
    iname = model.irfs.(irfs_names{ff});
    irfs.(irfs_names{ff}) = repmat(iname, nruns_max, 1);
end

% generate run predictors for each session
predS = cellfun(@(X, Y) convolve_vecs(X, Y, fs, fs), ...
    stim, irfs.nrfS, 'uni', false); predS(empty_cells) = {[]};
predTq = cellfun(@(X, Y) rectify(convolve_vecs(X, Y, fs, fs) .^ 2, 'abs', .001), ...
    stim, irfs.nrfT, 'uni', false); predTq(empty_cells) = {[]};
predTd = cellfun(@(X, Y) X ./ (X + Y .^ 2), ...
    predTq, params.sigma, 'uni', false);
fmriS = cellfun(@(X, Y) convolve_vecs(X, Y, fs, 1 / tr), ...
    predS, irfs.hrf, 'uni', false); fmriS(empty_cells) = {[]};
fmriT = cellfun(@(X, Y) convolve_vecs(X, Y, fs, 1 / tr), ...
    predTd, irfs.hrf, 'uni', false); fmriT(empty_cells) = {[]};
model.run_preds = cellfun(@(X, Y) [X Y * model.normT], ...
    fmriS, fmriT, 'uni', false);

end
