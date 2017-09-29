function fig = plot_roi_model(roi, save_flag)

% check inputs
if length(roi) > 1; roi = roi(1); end
if nargin < 2; save_flag = 0; end

% get design parameters, data, and predictor names
nexps = size(roi.experiments, 2); npreds = size(roi.model.betas{1}, 2);
amps = reshape([roi.model.betas{:}], npreds, [])';
R2 = [roi.model.varexp{:}]; R2_str = num2str(mean(R2), 3);
fit_str = [roi.model.type ' fit to ' strjoin(roi.model.fit_exps, '/')];
val_str = ['R^{2} in ' strjoin(roi.experiments, '/') ' = ' R2_str];
xlabs = label_preds(roi.model); xlabs = xlabs(1:npreds);

% setup figure
fig_name = [roi.nickname ' - ' roi.model.type ' model'];
fig = figTS(fig_name, [.1 .1 .8 .3 + nexps * .2]);

% plot model weights
subplot(1 + nexps, 2, 1); hold on;
[ymin, ymax] = barTS(amps, [0 0 0]);
axis tight; xlim([0 size(amps, 2) + 1]); ylim([ymin ymax]);
title({roi.nickname; fit_str; val_str});
xlabel('Predictor'); ylabel('Beta (% signal)');
set(gca, 'TickDir', 'out', 'XTick', 1:npreds, 'XTickLabel', xlabs);

% plot variance explained for each session
subplot(1 + nexps, 2, 2); hold on;
[ymin, ymax] = barTS(R2, [0 0 0]);
xlim([0 size(R2, 2) + 1]); ylim([ymin ymax]);
for ss = 1:length(roi.sessions)
    ypos = max([0 R2(ss)]) + .1; lab = num2str(R2(ss), 2);
    text(ss, ypos, lab, 'HorizontalAlignment', 'center');
end
title('Performance'); xlabel('Session'); ylabel('R^2'); ylim([0 1]);
set(gca, 'TickDir', 'out', 'XTick', 1:length(roi.sessions), ...
    'XTickLabel', strrep(roi.session_ids, '_', '-'));

% plot measurement vs prediction for each trial type
for ee = 1:nexps
    ax(ee) = subplot(1 + nexps, 1, ee + 1); hold on;
    xcnt = 3; zlc = xcnt;
    for cc = 1:length(roi.trial_avgs(:, 1, ee))
        % plot custom zero line for trial
        tl = length(roi.trial_avgs{cc, 1, ee});
        plot([zlc - 1 zlc + tl], [0 0], 'k-');
        % plot measured response for peristimulus time window
        x = xcnt:xcnt + tl - 1; ym = [roi.trial_avgs{cc, :, ee}]';
        me = lineTS(x, ym, 1, [.7 .7 .7], [.7 .7 .7], 'std');
        % plot model prediction for peristimulus time window
        pr = lineTS(x, [roi.pred_sum{cc, :, ee}]', 2, [0 0 0]);
        % plot separate channel contributions if applicable
        if roi.model.num_channels > 1
            sp = lineTS(x, [roi.predS_sum{cc, :, ee}]', 1, [0 0 1]);
            tp = lineTS(x, [roi.predT_sum{cc, :, ee}]', 1, [1 0 0]);
        end
        if roi.model.num_channels > 2
            dp = lineTS(x, [roi.predD_sum{cc, :, ee}]', 1, [0 1 0]);
        end
        % plot stimulus
        stim = [xcnt + roi.model.pre_dur xcnt + tl - roi.model.post_dur];
        cond_name = roi.model.cond_list{ee}(cc);
        plot(stim, [-.5 -.5], 'k-', 'LineWidth', 4);
        text(xcnt + roi.model.pre_dur - 1, -1, cond_name, 'FontSize', 8);
        xcnt = xcnt + tl + 3; zlc = xcnt;
    end
    % set legend and format plot
    leg{1} = [roi.nickname ' (N = ' num2str(length(roi.sessions)) ')'];
    leg{2} = [roi.model.type ' model']; ptrs = [me pr];
    if roi.model.num_channels > 1
        leg(3:4) = {'Sustained' 'Transient'}; ptrs = [ptrs sp tp];
    end
    if roi.model.num_channels > 2
        leg{5} = 'Delay'; ptrs = [ptrs dp];
    end
    legend(ptrs, leg, 'Location', 'NorthWestOutside'); legend boxoff;
    title([roi.experiments{ee}], 'FontSize', 8); ylabel('fMRI (% signal)');
    set(gca, 'XColor', 'w', 'TickDir', 'out', 'FontSize', 8); axis tight;
end

% match y-axis limits across experiments
[xmin, xmax, ymin, ymax] = deal(0);
for ee = 1:nexps
    xlims = get(ax(ee), 'XLim'); ylims = get(ax(ee), 'YLim');
    xmin = min([xmin xlims(1)]); xmax = max([xmax xlims(2)]);
    ymin = min([ymin ylims(1)]); ymax = max([ymax ylims(2)]);
end
yticks = floor(ymin):ceil(ymax);
for ee = 1:nexps
    set(ax(ee), 'XLim', [xmin xmax], 'YLim', [ymin ymax], 'YTick', yticks);
end

% save to figures directory if applicable
if save_flag
    fpath = fullfile(roi.project_dir, 'figures');
    fname = [roi.nickname '_' roi.model.type ...
        '_fit' [roi.model.fit_exps{:}] ...
        '_val' [roi.experiments{:}] ...
        '_' date '.fig'];
    saveas(fig, fullfile(fpath, fname), 'fig');
end

end