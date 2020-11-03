function statistics = statistical_agreement(myDataPath, agreement_parameter,ccep_clin)
%% Paired t-test or Wilcoxon signed rank non parametric test for two paired groups
% For the number of ERs detected in the 2 stimuli and the 10 stimuli
% null hypothesis is that the two means are the same
SubjectName = extractBetween(ccep_clin.dataName,'ieeg/sub-','_ses-1_');

ER_stimpClin = agreement_parameter.ERs_stimpClin;
ER_stimpProp = agreement_parameter.ERs_stimpProp;
 
NorDisClin = lillietest(ER_stimpClin);                  % null hypothesis that x is normally distributed, results in 1 when the null hypothesis is rejected 
NorDisClin = lillietest(ER_stimpProp);
 
% Check for monotonic relation
figure(2)
scatter(ER_stimpClin,ER_stimpProp)
refline
 
% Check for normal distribution
figure(1)
subplot(2,1,1)
normplot(ER_stimpClin)                                % normal distribution is datapoints along the reference line
subplot(2,1,2)
normplot(ER_stimpProp)

if NorDisClin == 1 && NorDisClin ==1
    p = ranksum(ER_stimpClin, ER_stimpProp) ;           % tests the null hypothesis that data in x and y are samples from continuous distributions with equal medians
    fprintf('The detected ERs per stimulation pair is NOT normally distributed, Wilcoxon Signed Rank test is used.\n')

else
    fprintf('The detected ERs per stimulation pair is normally distributed, still the Wilcoxon Signed Rank test is used.\n')
    p = ranksum(ER_stimpClin, ER_stimpProp);          % alpha default = 0.05
     
end

if p<0.05
    fprintf('Test between the number of ERs evoked in SPES-clin and SPES-prop gives p-value = %1.4f. This means that there is a significant difference between the two protocols for %s \n', p, SubjectName{1});
else
    fprintf('Test between the number of ERs evoked in SPES-clin and SPES-prop gives p-value = %1.4f. This means that there is NO significant difference between the two protocols for %s \n', p, SubjectName{1});
end

%% Spearman test for ranking of stimpairs
% Rank the stimuli from stimulus pairs with most evoked ERs to stimulus
% pairs with least evoked ERs
mode = {'SPES_clin','SPES_prop'};
rank = struct;

for i = 1:size(mode,2)
    
     if strcmp(mode{i},'SPES_clin')
        ERs = ER_stimpClin;
    elseif strcmp(mode{i},'SPES_prop')
        ERs = ER_stimpProp;
     end

    rank.(mode{i})(:,1:2) = ccep_clin.stimsets_avg;
    rank.(mode{i})(:,3) = ERs;
    [~, order] = sort(rank.(mode{i})(:,3), 'descend');          % most ER evoking stimpairs first
    rank.(['sort_' mode{i}]) = rank.(mode{i})(order, :);
    
    
     % If the next stimpair has the same number of ERs, give it the same order number
    rank.(['sort_' mode{i}])(1,4) = 1;
    for j = 2:size(rank.(['sort_' mode{i}]),1)
        if rank.(['sort_' mode{i}])(j,3) == rank.(['sort_' mode{i}])(j-1,3)          
            rank.(['sort_' mode{i}])(j,4) = rank.(['sort_' mode{i}])(j-1,4);
        else
            rank.(['sort_' mode{i}])(j,4) = j;
        end
    end
    
    rank.(['sort_names_' mode{i}]) = ccep_clin.stimpnames_avg(order);
end

%% Create with lines drawn between the positions of the stimpairs in the two rankings.

% make labeling for figure
for i=1:size(mode,2)
    [~,~,ic] = unique(rank.(['sort_' mode{i}])(:,4));
    groups = splitapply(@(x){x},rank.(['sort_names_' mode{i}])',ic);
    n = cell(size(groups));
    [n{:}] = deal(' ');
    newgroups = reshape(horzcat(groups,n)',size(groups,1)*2,1);
    rank.(['fig_sort_names_' mode{i}]) = vertcat({' '}, newgroups{:});
end
    
figure('Position',[1074,4,519,1052]);
cm = colormap(parula(max(rank.sort_SPES_clin(:,4))));
colororder({'k','k'})
set(gca,'YTick',(1:size(rank.fig_sort_names_SPES_clin,1)),'YTickLabel',rank.fig_sort_names_SPES_clin)
yyaxis left
set(gca, 'YDir', 'reverse');
set(gca,'TickLength',[0 0])
ylim([1, max([size(rank.fig_sort_names_SPES_clin,1) size(rank.fig_sort_names_SPES_prop,1)])])
ylabel('order SPES-clin')

yyaxis right
set(gca,'YTick',(1:size(rank.fig_sort_names_SPES_prop,1)),'YTickLabel',rank.fig_sort_names_SPES_prop)
set(gca, 'YDir', 'reverse');
ylim([1, max([size(rank.fig_sort_names_SPES_clin,1) size(rank.fig_sort_names_SPES_prop,1)])])
ylabel('order SPES-prop')

xlim([1, 2])
set(gca,'xtick',[])
str_main = sprintf('sub-%s', SubjectName{1});
sgtitle(str_main)


n=1;
for k = 1:length(rank.fig_sort_names_SPES_clin)
    if ~strcmp(rank.fig_sort_names_SPES_clin{k},' ')
        [~,loc2] = ismember(rank.fig_sort_names_SPES_clin{k}, rank.fig_sort_names_SPES_prop);
        
        line([1, 2],[k, loc2],'Color',cm(rank.sort_SPES_clin(n,4),:), 'LineWidth',2)  ;
        n=n+1;
    end
end

% Save figure
outlabel=sprintf('sub-%s_ranking.jpg',SubjectName{1});
path = fullfile(myDataPath.CCEPpath,'Visualise_agreement/Ranking/');
if ~exist(path, 'dir')
    mkdir(path);
end
saveas(gcf,[path,outlabel],'jpg')


% Sorted matrix based on stimpair number, so ranking isunsorted 
for i=1:size(mode,2)
    [~,order] = sortrows(rank.(['sort_' mode{i}])(:,1:2));
    rank.(['unsort_' mode{i}]) = rank.(['sort_' mode{i}])(order,:);         
end

% If the order of the stimulation pairs is not equal, than the ranking
% cannot be compared
if ~isequal(rank.unsort_SPES_clin(:,1:2),rank.unsort_SPES_prop(:,1:2))
    error('Sorting stimulus pairs is incorrect and led to unequal matrices in SPES-clin and SPES-prop')
end

% Test the hypothesis of NO correlation
% When p <0.05, an rho is close to (-)1, rejection of the hypothesis that no correlation exists between the two columns
[RHO_stmp,PVAL_stmp] = corr(rank.unsort_SPES_clin(:,4) , rank.unsort_SPES_prop(:,4) ,'Type','Spearman');            % Test the hypothesis that the correlation is NOT 0
fprintf('Spearman Corr between stimpair ranking of SPES-clin and SPES-prop gives, p-value = %1.4f, rho = %1.3f, for %s \n', PVAL_stmp, RHO_stmp, SubjectName{1});


%% Spearman correlation
% For the indegree, outdegree and betweenness centrality per electrode
measure = {'indegree','outdegree','BC'};

for n=1:size(measure,2)
    
    for i=1:size(mode,2)
        
        if strcmp(mode{i},'SPES_clin')
            ERs = agreement_parameter.([measure{n} 'N_Clin']);
        elseif strcmp(mode{i},'SPES_prop')
            ERs = agreement_parameter.([measure{n} 'N_Prop']);
        end

        rank.([measure{n}, mode{i}])(:,1) = 1:size(ccep_clin.ch,1);
        rank.([measure{n}, mode{i}])(:,2) = ERs;
        [~, order] = sort(rank.([measure{n} mode{i}])(:,2), 'descend');
        rank.(['sort_' measure{n} mode{i}]) = rank.([measure{n} mode{i}])(order, :);
        
        % If the next stimpair has the same number of ERs, give it the same order number
        rank.(['sort_' measure{n} mode{i}])(1,3) = 1;
        for j = 2:size(rank.(['sort_' measure{n} mode{i}]),1)
            if rank.(['sort_' measure{n}  mode{i}])(j,2) == rank.(['sort_' measure{n} mode{i}])(j-1,2)
                rank.(['sort_' measure{n}  mode{i}])(j,3) = rank.(['sort_' measure{n} mode{i}])(j-1,3);
            else
                rank.(['sort_' measure{n} mode{i}])(j,3) = j;
            end
        end
        
        rank.(['sort_names_' measure{n} mode{i}]) = ccep_clin.ch(order);
        
         % Sorted matrix based on stimpair number, so ranking isunsorted 
        [~,order] = sort(rank.(['sort_' measure{n} mode{i}])(:,1));
        rank.(['unsort_' measure{n} mode{i}]) = rank.(['sort_' measure{n} mode{i}])(order,:);        
    end
    
    
    [RHO.(measure{n}), PVAL.(measure{n})] = corr(rank.(['unsort_' measure{n} mode{1}])(:,3), rank.(['unsort_', measure{n} mode{2}])(:,3),'Type','Spearman','rows','pairwise');
    
    fprintf('Spearman Corr between %s per electrode of SPES-clin and SPES-prop gives, p-value = %1.4f, rho = %1.3f, for %s \n', measure{n}, PVAL.(measure{n}), RHO.(measure{n}), SubjectName{1});
end

fprintf('------------ NEXT PATIENT ------------\n')

 % Write to variable
statistics.p_BC = PVAL.BC;
statistics.rho_BC = RHO.BC;
statistics.p_indegree= PVAL.indegree;
statistics.rho_indegree = RHO.indegree;
statistics.p_outdegree = PVAL.outdegree;
statistics.rho_outdegree = RHO.outdegree;
statistics.p_stimp = PVAL_stmp;
statistics.rho_stimp = RHO_stmp;
statistics.p_ERsperStimp = p;        

        
end       

