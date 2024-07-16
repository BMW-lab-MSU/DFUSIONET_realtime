function [Tsensor] = load_allfiles_sensor(foldername, current_site, sensor_keyword)

% load sensordata --- all arable data should be under the folder 'Arable'
sensor_fullpath = [foldername filesep current_site filesep sensor_keyword];
sensor_files = dir([sensor_fullpath filesep '*.csv']);
sensordata= {};
for i = 1:length(sensor_files)
    filename = sensor_files(i).name;
    fullfilename = fullfile(sensor_fullpath,filename);
    if contains(filename,'Arable')
        im_opts = detectImportOptions(fullfilename);
        im_opts.VariableNamesLine = 14;
        im_opts.DataLines = [15, inf];
        Ttemp = readtable(fullfilename,im_opts);
        sensordata{end+1} = Ttemp;
        clear Ttemp
    end
end

% accumulate all the arable sensor data in one table
Tsensor = vertcat(sensordata{:});

end