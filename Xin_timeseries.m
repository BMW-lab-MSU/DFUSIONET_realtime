function [Xin] = Xin_timeseries(sensordata_selectedvars,ETspatial,pixel_idx,start_day,end_day)
    temp_S = [sensordata_selectedvars(start_day:end_day,:)]; % those specific rows (days) from sensordata
    % Data append structure:
    % each row in temp_S is the different arable features for a particular day.
    % To make the time-series, we want all rows append one-after another.
    % For example, at first, we want features 1:n of day 1.
    % The n+1 th element should be feature 1 of day 2.
    % The n+2 th element feature 2 of day 2 and so on...
    temp_S = reshape(temp_S',[],1); % reshape to column vector
    temp_ET = [ETspatial(pixel_idx,start_day:end_day)]; % those specific days from ET_pixel plus one "day-ahead"
    temp_ET = reshape(temp_ET,[],1); % reshape to column vector
    Xin = [temp_S;temp_ET];
end