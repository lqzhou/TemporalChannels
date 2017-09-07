function model = pred_runs_2ch_opt(model)
% Generates run predictors using the 2 temporal-channel model with dCTS on
% sustained channel. 

% get design parameters
params_init = model.params; irfs_init = model.irfs;
fs = model.fs; tr = model.tr; rd = model.run_durs; stim = model.stim;
cat_list = unique([model.cats{:}]); ncats = length(cat_list);
[nruns_max, ~] = size(model.run_durs);
params_names = fieldnames(params_init); params = [];
for pp = 1:length(params_names)
    params.(params_names{pp}) = repmat(params_init.(params_names{pp}), nruns_max, 1);
end
irfs_names = fieldnames(irfs_init); irfs = [];
for ff = 1:length(irfs_names)
    irfs.(irfs_names{ff}) = repmat(irfs_init.(irfs_names{ff}), nruns_max, 1);
end

% generate run predictors for each session
run_preds = cellfun(@(X) zeros(X / tr, ncats), rd, 'uni', false);
empty_cells = cellfun(@isempty, run_preds); run_preds(empty_cells) = {[]};
predSl = cellfun(@(X, Y) convolve_vecs(X, Y, fs, fs), stim, irfs.nrfS, 'uni', false);
predSn = cellfun(@(X) X .^ 2, predSl, 'uni', false);
predSf = cellfun(@(X, Y) convolve_vecs(X, Y, fs, fs), predSl, irfs.lpf, 'uni', false);
predSd = cellfun(@(X, Y) X .^ 2 + Y .^ 2, predSf, params.sigma, 'uni', false);
predS = cellfun(@(X, Y) X ./ Y, predSn, predSd, 'uni', false);
clear('predSl', 'predSn', 'predSf', 'predSd');
predTl = cellfun(@(X, Y) convolve_vecs(X, Y, fs, fs), stim, irfs.nrfT, 'uni', false);
predS(empty_cells) = {1}; predTl(empty_cells) = {1};
predT = cellfun(@(X) X .^ 2, predTl, 'uni', false);
fmriS = cellfun(@(X, Y) convolve_vecs(X, Y, fs, 1 / tr), predS, irfs.hrf, 'uni', false);
fmriT = cellfun(@(X, Y) convolve_vecs(X, Y, fs, 1 / tr), predT, irfs.hrf, 'uni', false);
fmriS(empty_cells) = {[]}; fmriT(empty_cells) = {[]};
run_preds = cellfun(@(X, Y) [X Y * model.normT], fmriS, fmriT, 'uni', false);
model.run_preds = run_preds;

end
