function [Tsensor] = filter_data_by_date(Tsensor, required_spatialdates)
%% Extract the necessary data only
sensor_startdate = min(Tsensor.local_time);
sensor_enddate = max(Tsensor.local_time);
sensor_alldates = sensor_startdate : sensor_enddate;

% mark satellite image dates
temp_dates = intersect(sensor_alldates, required_spatialdates);
required_dates = min(temp_dates):max(temp_dates);

% extract the specific range of dates based on all satellite dates
row_idx = [];
for i = 1:length(required_dates)
    row_idx = [row_idx; find(strcmpi(string(Tsensor.local_time), string(required_dates(i))))];
end
Tsensor = Tsensor(row_idx,:);

% %% extract the specific sensor
% sensorname = 'R5 1'; 
% sensor_row_idx = find(strcmpi(string(Tsensor.site),sensorname));
% Tsensor = Tsensor(sensor_row_idx,:);

% %% plot
% 
% % initialize figure
% figure("Units","normalized","OuterPosition",[0,0,1,1])
%
% % convert ETc values to mm
% xvals = required_dates;
% tempY = (Tsensor.ETc).*25.4;
%
% % plot respective arable data
% nexttile
% plot(xvals,tempY,'-o')
% lgnd{1,1} = "Daily ETc (Arable)";
% hold on
% xline(spatialdates,'--k')
% lgnd{1,2} = "satellite image dates";
% xlabel("dates of " + string(year(xvals(1))) + " season")
% xvals_new = [];
% for j = 1:3:length(xvals)
%     xvals_new = [xvals_new; xvals(j)];
% end
% tickvals = extractBefore(string(xvals_new),string(year(xvals_new(1))));
% xticks(xvals_new)
% xticklabels(tickvals)
% ylabel("ET (mm d^{-1})")
% xlim([min(xvals)-0.5 max(xvals)+0.5])
% ylim([0 10])
% grid minor
% legend(lgnd,'NumColumns',2)
% xtickangle(90)
% title("site: " + current_site)

end