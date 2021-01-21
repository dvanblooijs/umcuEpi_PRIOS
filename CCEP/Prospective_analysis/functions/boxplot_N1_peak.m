function boxplot_N1_peak(dataBase, myDataPath)
% Make boxplots of the latency of the N1 peaks.

close all
clc

% Statistics
for subj = 1:size(dataBase,2)
    ccep_clin = dataBase(subj).ccep_clin;
    ccep_prop = dataBase(subj).ccep_prop;

    fs = 1/(size(ccep_prop.tt,2)/4);                             % Devide tt by four because ccep_prop.tt includes 4 seconds.
    clin = ccep_clin.n1_peak_sample_check;
    clin = ((clin*fs)-2)*1000;                                   % to convert samples to milliseconds, minus 2 becuase of the period before the stimulation artefact
    prop = ccep_prop.n1_peak_sample_check;
    prop = ((prop*fs)-2)*1000;                                   % to convert samples to milliseconds, minus 2 becuase of the period before the stimulation artefact


    % Create matrix with the clinical values in the first column and
    % the propofol values in the second
    i = 1;
    for stimp = 1:size(ccep_prop.stimpnames_avg,2)                          % For each stimpair
        for elec = 1:size(ccep_prop.ch,1)                                   % For each electrode

        % When both clinical SPES and propofol SPES show an ER
          if ~isnan(clin(elec, stimp)) &&  ~isnan(prop(elec, stimp)) 
                new_mat(i,1) = clin(elec, stimp);            %#ok<AGROW> % plot the SPES-clin amp in column 1
                new_mat(i,2) = prop(elec, stimp);            %#ok<AGROW> % plot the SPES-prop amp in column 2
                i = i+1;                
          end
        end      
    end

    % Determine gaussianity
    % Biggest part of the data is not normally distributed (determined on 10-12-2020)
%         NorDisClin = lillietest(new_mat(:,1))   ;               % null hypothesis that x is normally distributed, results in 1 when the null hypothesis is rejected 
%         NorDisProp = lillietest(new_mat(:,2));

    % Paired, non-gaussian, comparison of two rankings
    p = ranksum(new_mat(:,1), new_mat(:,2)) ;                       % tests the null hypothesis that data in x and y are samples from continuous distributions with equal medians
    dataBase(subj).ccep_clin.p_n1 = {sprintf('%1.4f',p)};
    dataBase(subj).ccep_clin.mean_N1_lat = mean(new_mat(:,1));
    dataBase(subj).ccep_prop.p_n1 = {sprintf('%1.4f',p)};
    dataBase(subj).ccep_prop.mean_N1_lat = mean(new_mat(:,2));

    % Display the p value 
    if p<0.05
        fprintf('Test between the N1-Latency of %s SPES-clin and SPES-prop gives p-value = %1.4f. This means that there is a significant difference between the two protocols \n',dataBase(subj).sub_label, p);
    else
        fprintf('Test between the N1-Latency of %s SPES-clin and SPES-prop gives p-value = %1.4f. This means that there is NO significant difference between the two protocols \n',dataBase(subj).sub_label, p);
    end

end

%% Make boxPlots    
new_mat = [];  
fs = 1/(size(ccep_prop.tt,2)/4);                                        % Devide tt by four because ccep_prop.tt includes 4 seconds.
              
for subj = 1:size(dataBase,2)
    ccep_clin = dataBase(subj).ccep_clin;
    ccep_prop = dataBase(subj).ccep_prop;

    clin = ccep_clin.n1_peak_sample_check;
    clin = ((clin*fs)-2)*1000;                                   % to convert samples to milliseconds, minus 2 becuase of the period before the stimulation artefact
    prop = ccep_prop.n1_peak_sample_check;
    prop = ((prop*fs)-2)*1000;                                   % to convert samples to milliseconds, minus 2 becuase of the period before the stimulation artefact

     i = 1;
     clin_colm = 2*subj-1;                      % prealloction of the column number
     prop_colm = 2*subj;                        % prealloction of the column number



            for stimp = 1:size(ccep_prop.stimpnames_avg,2)                          % For each stimpair
                for elec = 1:size(ccep_prop.ch,1)                                   % For each electrode

                % When both clinical SPES and propofol SPES show an ER
                  if ~isnan(clin(elec, stimp)) &&  ~isnan(prop(elec, stimp)) 
                        new_mat(i,clin_colm) = clin(elec, stimp);            % plot the SPES-clin amp in column 1
                        new_mat(i,prop_colm) = prop(elec, stimp);          % plot the SPES-prop amp in column 2
                        i = i+1;

                  end
                end      
            end             
end

new_mat((new_mat == 0)) = NaN;                                      % replace zero with NaN to avoid influence on the mean
means =  median(new_mat,'omitnan');
Ns = sum(~isnan(new_mat(:,:)) ) ;                                       % Number of ERs

% Create boxplot with the amplitude of SPES clin and SPES prop
figure('Position',[205,424,1530,638]);
% columnMeans = mean(new_mat, 1, 'omitnan');
grouporder = {'PRIOS01','','  PRIOS02**','','  PRIOS03**','','  PRIOS04','','  PRIOS05*','','  PRIOS06',''};

violins = violinplot(new_mat,grouporder) ;
for i = 1:2:size(new_mat,2)
    violins(1,i).ViolinColor = [1 0 0];
    violins(1,i+1).ViolinColor = [0 0 1];
end

ax = gca;
ax.XAxis.FontSize = 12;
ax.YAxis.FontSize = 12;
ax.XAxis.FontWeight = 'bold';
ax.YAxis.FontWeight = 'bold';
ax.XLabel.Position = [6.5, -28.4, -1];

title(sprintf('N1 Latency'),'FontSize', 15, 'FontWeight', 'bold')
ylabel('Latency (milliseconds)','FontSize', 15, 'FontWeight', 'bold')

% Plot the mean on the xaxis  
stringsz = [repmat('n = %2.0f,    ',1,size(means,2)-1),'n = %2.0f'];
xlabel(sprintf(stringsz,Ns))

legend([violins(1).ViolinPlot,violins(2).ViolinPlot], 'Clinical SPES','Propofol SPES','FontSize', 12, 'FontWeight', 'bold')

% Save figure
outlabel=sprintf('Latency_violin.jpg');
path = fullfile(myDataPath.CCEPpath,'Visualise_agreement/N1_compare/');
if ~exist(path, 'dir')
    mkdir(path);
end
saveas(gcf,[path,outlabel],'jpg')

        
%% Make scatter of the latency
figure('Position',[302,17,938,1039])

for subj = 1:size(dataBase,2)
        
       colm_clin = 2*subj-1;
       colm_prop = (2*subj);
       clin = new_mat(:,colm_clin);
       prop = new_mat(:,colm_prop);
       p = round(str2double(dataBase(subj).ccep_clin.p_n1{:}),3);
       
       % do not plot values with NaN
       if size(clin(isnan(clin)),1) > 1
          clin = clin(~isnan(clin));
          prop = prop(~isnan(prop));              
       end
       
        subplot(size(dataBase,2),1,subj)
        scatter(clin  , prop); 
        ylabel('SPES-prop (ms)','FontSize',10)
        xlabel("SPES-clin (ms)"+newline+"   ",'FontSize',10)
        title(sprintf('%s, p =  %0.3f', dataBase(subj).sub_label, p));
            if p< 0.05
                title(sprintf('%s, p < 0.05', dataBase(subj).sub_label));
            elseif p<0.01
                title(sprintf('%s, p < 0.01', dataBase(subj).sub_label));
            end
            
        str_main = ('N1 Latency');
        sgtitle(str_main)
        ax = gca;
        ax.YAxis.FontSize = 10;
        ax.XAxis.FontSize = 10;
        
        
        % Xmax is determined by the value on the x-axis which is the
        % SPES-clin
        xmin = round(min(clin, [], 'all'),2);
        xmax = round(max(clin, [], 'all'),2);
        
        % Ymax is determined by the value on the y-axis which is the
        % SPES-prop
        ymin = round(min(prop, [], 'all'),2);
        ymax = round(max(prop, [], 'all'),2);      
        xlim([xmin, xmax+2])
        ylim([ymin, ymax+5])
end 
          % Save figure
        outlabel=sprintf('n1_scatter_Latency.jpg');
        path = fullfile(myDataPath.CCEPpath,'Visualise_agreement/N1_compare/Scatter/');
        if ~exist(path, 'dir')
            mkdir(path);
        end
        saveas(gcf,[path,outlabel],'jpg')
        
%% Determine the multiplication factor

for subj = 1:size(dataBase,2)
  M_Clin = means(1:2:end);
  M_Prop = means(2:2:end);
end

% Pre-allocation
T_N1(:,1) = means(1:2:end);
T_N1(:,2) = means(2:2:end);

for i = 1:size(T_N1,1)
    T_N1(i,3) = T_N1(i,1)/T_N1(i,2);
end

% Make a table to facilitate reading the data
Size_mat = (size(T_N1,1)+1);
T_N1(Size_mat,1) = median(M_Clin);
T_N1(Size_mat,2) = median(M_Prop);
T_N1(Size_mat,3) = median(T_N1(:,3));

variables = {'N1 clinical','N1 propofol','Mult-factor'};

T_N1 = table(T_N1(:,1),T_N1(:,2),T_N1(:,3), 'VariableNames',variables,'RowNames',{'PRIOS01','PRIOS02','PRIOS03','PRIOS04','PRIOS05','PRIOS06','Medians'});
disp(T_N1)
end
    