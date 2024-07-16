function [spatialdates,spatialdata] = load_allfiles_spatialET(foldername, current_site, spatial_keyword)

% load spatialdata
spatial_fullpath = [foldername filesep current_site filesep spatial_keyword];
spatial_files = dir([spatial_fullpath filesep '*.csv']);
spatial_info_flag = 0;
for i = 1:length(spatial_files)
    filename = spatial_files(i).name;
    fullfilename = fullfile(spatial_fullpath,filename);
    if contains(filename,'Spatial')
        % extract dates from filename
        pat = lettersPattern(3) + '_' + digitsPattern(2) + '_' + digitsPattern(4); % month name has to be exactly 3 letters, date has to be exactly 2 numbers 
        dateinfo = extract(filename,pat);
        dateinfo = replace(dateinfo,'_','-');
        tempdate = datetime(dateinfo,"InputFormat","MMM-dd-uuuu");
        
        % load data
        Ttemp = readtable(fullfilename);
        if spatial_info_flag == 0
            spatialdata = Ttemp; % init table
            spatialdata = renamevars(spatialdata,"ET",string(tempdate)); % replace the column name 'ET' with current date
        else
            spatialdata.(string(tempdate)) = Ttemp.ET;
        end

        % append date
        if exist('spatialdates','var') % check if the variable named "dates" exist
            % check if the current date already exists
            flag = find(spatialdates == tempdate);
            if isempty(flag)
                spatialdates(end+1,1) = tempdate;
                spatial_info_flag = 1;
            end
        else
            spatialdates(1,1) = tempdate;
            spatial_info_flag = 1;
        end
        clear Ttemp
    end
end

% no relevant files in the folder
if ~exist('spatialdates','var')
    spatialdates = [];
    spatialdata = [];
end

end