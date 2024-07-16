% Filename: main_ET_pred_1step_RT.m
% Author: Farshina Nazrul Shimim
% Date: 2024-06-24
% Description: This script performs daily spatial ET (Evapotranspiration) prediction and provides an irrigation prescription 
% for a specific site using neural networks and a custom interpolation named POI. The script includes data preprocessing, model training,
% prediction, and saving the results in appropriate folders.

clear all
close all
clc
%% set user inputs

% Specify the site index to work with (e.g., 1 for R5, 2 for R6)
site_idx = 2; 

% Set current irrigation date
currentdate = datetime({'Jun_12_2024'},'InputFormat','MMM_dd_yyyy');

% Set last irrigation date
last_irr_date = datetime({'Jun_10_2024'},'InputFormat','MMM_dd_yyyy');

% Set the directory containing site data files for 2024
site_dir = '.\datafiles\Irrigation_rec\';

% Set the filename for 2023 data
filename_2023 = ".\datafiles\alldatafiles_2023.mat";

% Specify the number of features selected for best performance (lowest RMSE from hyperparameter optimization procedure)
n_features = 1;

% Set the window size to 9 days (10th day is satellite visit interval)
window_size = 9;

% Set RNG array to control neural network initialization. 
% Final prediction will be the average of 5 predictions from different networks
a = [0:4];

% Set network hidden layer sizes based on hyperparameter optimization
xval = [25;425;550]; % [network 1 hidden layers; network 2 hidden layers; combined network hidden layers]

% Set other parameters based on 'bayesopt' hyperparameter optimization procedure
NN_param.miniBatchSize_train = 761;
NN_param.initial_LR = 5.6e-04;
NN_param.gradient_thr = Inf;
NN_param.dropput_prob = 0.3;
NN_param.maxEpochs = 20;
NN_param.miniBatchSize_test = 386;
%% Data Preprocessing
% Get all sites from the specified directory
files = dir(site_dir);
sitenames = {};
for i = 1:length(files)
    if ~strcmpi(unique(files(i).name),'.') % find the sites with actual letters. not only '.'
        sitenames{end+1} = files(i).name;
    end
end

% Set the current site based on user input
current_site = sitenames{site_idx};
clear sitenames
foldername = files.folder;

% Load all daily sensor (Arable) ETc data for the current site
sensor_keyword = 'Arable';
[Tsensor] = load_allfiles_sensor(foldername, current_site, sensor_keyword);

% Load all satellite/drone data for the current site
spatial_keyword = 'SpatialET';
[spatialdates,spatialdata] = load_allfiles_spatialET(foldername, current_site, spatial_keyword);
spatialdates = sort(spatialdates);

% Load all necessary 2023 data files
data2023 = load(filename_2023);
sitenames = data2023.sitenames;
allfeatures_sorted = data2023.allfeatures_sorted;
sensorETdata = data2023.sensorETdata;
spatialETdata = data2023.spatialETdata;

% Filter sensor data by required dates
required_spatialdates = spatialdates; % only extract the min(satellite_dates):max(satellite_dates)
[Tsensor_filtered] = filter_data_by_date(Tsensor, required_spatialdates);

% Perform proportional-offset interpolation (POI) to get site-specific values
[ETmaps_daily_site,flightday_site] = POI(Tsensor_filtered,spatialdates,spatialdata);

% Filter by important features and normalize the data
[Tsensor_filtered] = filter_data_by_features_normalize(Tsensor_filtered,allfeatures_sorted);

% Append site-specific 2024 data to the existing 2023 data
sensorETdata{end+1} = Tsensor_filtered;
spatialETdata{end+1} = ETmaps_daily_site;
sitenames{end +1} = current_site;

% Create dataset with temporal partition (sliding windows)
[Traindata, pixelinfo, numFeatures, numResponses] = data_partition_for_timeseries(n_features,sensorETdata,spatialETdata,sitenames,window_size);

% Set necessary neural network fixed parameters
NN_param.numHiddenUnits = xval;
NN_param.numFeatures = numFeatures;
NN_param.numResponses = numResponses;

%% Model training
testRMSE_array = [];
t = rng(a(1));

all_nets = {};

% Train the neural network for each random initialization
for j = 1:length(a)
    % Set the seed for reproducibility
    t.Seed = a(j);

    % Train
    [net,traininfo,options] = ET_pred_1step_train_RT(NN_param,Traindata,t);
    all_nets{j}= net;
end

% Save the trained networks (if necessary)
save("alltrainednets.mat",'all_nets')
%% Prediction
% Load all trained networks (if necessary)
load("alltrainednets.mat")

% Define total prediction date range (from last drone/satelite day + 1 to the current irrigation date)
allpred_days = spatialdates(end) + 1 : currentdate;

% Only predict if there are enough spatial data available to form the NN input sliding window
if spatialdates(1) <= allpred_days(1) - window_size

    % Iterate over each prediction date 
    for i = 1 : length(allpred_days)
        current_pred_date = allpred_days(i);
        % Get start_day and end_day for the sliding window (also the NN input)
        start_day = current_pred_date - window_size;
        end_day = current_pred_date - 1;

        % Filter sensor data by required dates
        required_spatialdates = start_day:end_day;
        [Tsensor_filtered] = filter_data_by_date(Tsensor, required_spatialdates);

        % Filter by important features and normalize the data
        current_sensordata = filter_data_by_features_normalize(Tsensor_filtered,allfeatures_sorted);

        % Select only the first n features as per their feature selection ranking
        sensordata_selectedvars = current_sensordata{:,1:n_features};

        % Filter spatial data by required dates
        col_idx = [];
        for col = 3 : width(ETmaps_daily_site)
            tempdate = datetime(ETmaps_daily_site.Properties.VariableNames(col),'InputFormat','MM/dd/uuuu');
            if sum(ismember(required_spatialdates,tempdate)) > 0
                col_idx = [col_idx, col];
            end
        end
        ETspatial = single(ETmaps_daily_site{:,col_idx});

        % Load necessary spatial data from the Predicted Spatial ET folder
        spatial_keyword = 'SpatialPredET';
        [spatialPreddates,spatialPreddata] = load_allfiles_spatialET(foldername, current_site, spatial_keyword);

        % Only keep the necessary Predicted dates (dates after the last spatial date)
        if ~isempty(spatialPreddates)
            col_idx = [];
            for col = 3 : width(spatialPreddata)
                tempdate = datetime(spatialPreddata.Properties.VariableNames(col),'InputFormat','dd-MMM-uuuu');
                if tempdate > spatialdates(end) && sum(ismember(required_spatialdates,tempdate)) > 0
                    col_idx = [col_idx, col];
                end
            end
            % Convert inches to mm and append horizontally
            ETspatial = [ETspatial, single(spatialPreddata{:,col_idx}) .* 25.4]; 
        end


        % Iterate through pixels for prediction
        n_pixels = height(ETspatial);
        Xin_1_size = numFeatures(1,1);
        tempXTest1 = [];
        tempXTest2 = [];
        Xin_startday = 1;
        Xin_endday = length(required_spatialdates);
        for pixel_idx = 1:n_pixels
            [Xin] = Xin_timeseries(sensordata_selectedvars,ETspatial,pixel_idx,Xin_startday,Xin_endday); % for 1 pixel
            tempXTest1 = [tempXTest1, Xin(1 : Xin_1_size, 1)];
            tempXTest2 = [tempXTest2, Xin(Xin_1_size + 1 : end, 1)];
        end
        dsXTs1 = arrayDatastore(tempXTest1, IterationDimension=2);
        dsXTs2 = arrayDatastore(tempXTest2, IterationDimension=2);
        TestXdata =  combine(dsXTs1,dsXTs2);

        % Predict using the trained networks
        Y_Pred_array = [];
        for j = 1 : length(all_nets)
            net = all_nets{j};
            YPred = predict(net,TestXdata,'MiniBatchSize',NN_param.miniBatchSize_test);
            Y_Pred_array = [Y_Pred_array, reshape(YPred,[],1)]; % horizontal append
        end
        % Compute the average prediction
        mean_Y_pred = mean(Y_Pred_array, 2); % column vector that is mean of each row

        % Write the average prediction to a CSV file in the SpatialPredET folder
        SpatialPredOut = ETmaps_daily_site(:,1:2);
        SpatialPredOut.ET = mean_Y_pred./25.4; % convert mm to inches

        % Save the prediction
        date_name = string(day(current_pred_date));
        if day(current_pred_date) < 10 % If single digit date, make it double digit (e.g., 08 instead of 8)
            date_name = "0" + date_name;
        end
        month_name = string(month(current_pred_date,'shortname'));
        year_name = string(year(current_pred_date));
        savefile_fullpath = [foldername filesep current_site filesep spatial_keyword];
        % Be very specific with save-filename. It should be exactly 3 letters representing month, 2 digits for the date and 4 digits for the year (e.g., "SpatialPred_MMM_dd_yyyy.csv")
        savefilename = "SpatialPred_" + month_name + "_" + date_name + "_" + year_name + ".csv"; 
        savefile_fullname = fullfile(savefile_fullpath,savefilename);
        % Save the prediction in CSV format
        writetable(SpatialPredOut,savefile_fullname)
    end

else
    % Show error message if there is not enough spatial information to form the sliding window for NN input
    disp("not enough spatial information")
end


%% Irrigation prescription 
% Total spatial ET: add all prediction values from last_irr_date + 1 to currentdate 
% Save results to the Irr_rec/final_output folder
 
% Load necessary spatial data from the Predicted Spatial ET folder
spatial_keyword = 'SpatialPredET';
[spatialPreddates,spatialPreddata] = load_allfiles_spatialET(foldername, current_site, spatial_keyword);

irr_rec_ET = spatialPreddata(:,1:2); % Initialize with first two columns that represents the spatial coordinates
tempET = zeros(height(irr_rec_ET),1); % Initialize temporary ET accumulation

% Filter data by required dates and accumulate ET values
for i = last_irr_date + 1 : currentdate
    col_idx = find(spatialPreddates == i) + 2; % Adjust index to account for initial columns
    tempET = [tempET + spatialPreddata{:,col_idx}];
end
irr_rec_ET.TotalET = tempET; % Add total ET to the table

% Save the irrigation prescription data
save_keyword = 'Final output';
savefile_fullpath = [foldername filesep current_site filesep save_keyword];
savefilename = "totalspatialET" + "_" + current_site + "_" + string(last_irr_date + 1) + "_" +string(currentdate)+ ".csv";
savefile_fullname = fullfile(savefile_fullpath,savefilename);
writetable(irr_rec_ET,savefile_fullname)