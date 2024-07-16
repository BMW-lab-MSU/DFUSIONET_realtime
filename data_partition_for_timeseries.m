function [Traindata, pixelinfo, numFeatures, numResponses] = data_partition_for_timeseries(n_features,sensorETdata,spatialETdata,sitenames,window_size)

Xin_1_size = n_features * window_size;
Xin_2_size = 1 * window_size;
numFeatures = [Xin_1_size, Xin_2_size];
numResponses = 1;

% init XTrain, YTrain
tempXTrain1 = [];  % size = [Xin_1_size, :];
tempXTrain2 = []; % size = [Xin_2_size, :];
tempYTrain = []; % size = [numResponses, :];

pixelinfo = {};
for site_idx = 1:length(sitenames)

    % site-specific sensordata
    current_sensordata = sensorETdata{site_idx};
    % site-specific spatial ET data
    current_spatialETdata = spatialETdata{site_idx};

    % only keep the first n features as per their ranking
    sensordata_selectedvars = current_sensordata{:,1:n_features};

    ETspatial = single(current_spatialETdata{:,3:end});
    n_pixels = height(current_spatialETdata);
    n_days = height(current_sensordata); % number of days for that site

    for k = 1:n_days
        start_day = k;
        end_day = start_day + window_size -1;
        if end_day > 0 && end_day + 1 <= n_days
            for pixel_idx = 1:n_pixels
                [Xin] = Xin_timeseries(sensordata_selectedvars,ETspatial,pixel_idx,start_day,end_day);
                tempXTrain1 = [tempXTrain1, Xin(1 : Xin_1_size, 1)];
                tempXTrain2 = [tempXTrain2, Xin(Xin_1_size + 1 : end, 1)];
                tempYTrain = [tempYTrain, ETspatial(pixel_idx, end_day + 1)];

                % append pixel info
                pixelinfo{end + 1,1} = "site: " + sitenames{site_idx} + "; days: " + string(start_day) + "-" + string(end_day) + "; pixel idx: " + string(pixel_idx);
            end
        end
    end

end

dsXTr1 = arrayDatastore(tempXTrain1, IterationDimension=2);
dsXTr2 = arrayDatastore(tempXTrain2, IterationDimension=2);
dsYTr = arrayDatastore(tempYTrain, IterationDimension=2);
Traindata = combine(dsXTr1,dsXTr2,dsYTr);
end
