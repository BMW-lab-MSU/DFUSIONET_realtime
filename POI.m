function [ETmaps_daily,flightday] = POI(Tsensor,dates,spatialdata)
% extract date-specific ETc
sensordates = Tsensor.local_time; 
[spatialdates,sensoridx_common,spatialidx_common] = intersect(sensordates,dates); % the dates overlap between the spatial imagery and the daily ETc (selected sensor)

% find the specific daily ETc array 
ETc = Tsensor.ETc(min(sensoridx_common):max(sensoridx_common));

% find the specific seasonal ETmaps 
ETmaps = spatialdata{:,(spatialidx_common+2)};
ETmaps = ETmaps.*25.4; % convert inches to mm

refdate = spatialdates(1);
for k = 1:length(spatialdates)
    currentdate = spatialdates(k);
    % add 1 cause this is only taking the differences
    flightday(k) = daysact(refdate,currentdate) + 1;
end

A = ETc; %ref_timeseries
ndays = length(A);

required_size = height(spatialdata); % No. of pixels
datearray = string(sensordates(min(sensoridx_common):max(sensoridx_common)));
ETmaps_pred = array2table(zeros(required_size,ndays),"VariableNames",datearray);

ETmaps_daily = spatialdata(:,1:2); % append easting northing

for i = 1:required_size
Bactual = ETmaps(i,:); % all imagery data for a specific row (pixel)
ETpixel_pred =  zeros(1,ndays);

for k = 1:length(spatialdates)-1

    startday = flightday(k);
    endday = flightday(k+1);

    x = [startday, endday];
    xq = linspace(startday,endday,(endday - startday + 1));

    % get line points
    vA = [A(startday), A(endday)];

    % get line
    Aline = interp1(x,vA,xq).';

    % find distance
    Adist = A(startday:endday) - Aline;

    % get line points
    vB = [Bactual(k), Bactual(k+1)];

    % get line
    Bline = interp1(x,vB,xq).';

    % use distance
    scaling_factor = mean(vB)/mean(vA);
    % scaling_factor = 1;
    Bpred_temp = Bline + (Adist*scaling_factor); % try a bunch of different stuff in here


    % append in the pixel array
    ETpixel_pred(startday:endday) = reshape(Bpred_temp,1,[]); % make it a row array
end
% append in the image matrix
ETmaps_pred{i,:} = ETpixel_pred;
end

% throwout the weird 3 pixels
[ETmaps_vals_cleaned,outlier_pixel_idx] = throw_outliers(ETmaps_pred{:,:});
ETmaps_vals_cleaned(:,:) = max(ETmaps_vals_cleaned(:,:),0); % throw the negative values
ETmaps_pred{:,:} = ETmaps_vals_cleaned;
ETmaps_pred(outlier_pixel_idx,:) = [];
ETmaps_daily(outlier_pixel_idx,:) = [];
ETmaps_daily = [ETmaps_daily,ETmaps_pred];

% check error in interpolation or append or anything else
% test_ET_interpolated = ETmaps_pred{:,flightday};
% test_ET_error = ETmaps - test_ET_interpolated;
% max(test_ET_error,[],'all') % max error value
end

function [ETmaps_vals_cleaned,outlier_pixel_idx] = throw_outliers(spatialET_vals)
% throw off outliers (outside the 99th percentile)
outlierPercentage = 1;
meanETpixels = mean(spatialET_vals,2); % mean of each timeseies
outliers = isoutlier(meanETpixels, 'percentiles', [0, 100 - outlierPercentage],  1);
outlier_pixel_idx = find(any(outliers == 1, 2));
ETmaps_vals_cleaned = spatialET_vals;
ETmaps_vals_cleaned(outlier_pixel_idx,:) = 0;
end
