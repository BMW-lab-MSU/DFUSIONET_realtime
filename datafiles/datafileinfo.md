# Sensor Data and Spatial Data

## Directory Structure

### For Arable Data:
The `Irrigation_rec` directory will contain all site-specific Arable and SpatialET data organized into folders and subfolders. The directory structure should be as follows:

Irrigation_rec/[sitename]/Arable/[1 arable file for that specific site]Arable.xlsx

* The keyword `Arable` is a must in the file name.

### For Spatial ET Data:
The directory structure for Spatial ET data should be as follows:

Irrigation_rec/[sitename]/SpatialET/Spatial_[1 spatial ET file for each date].xlsx

* The keyword `Spatial` is a must in the file name.
* The date format in the file name should be `[monthname (3 letters), day (2 digits), year (4 digits)]`.

## Feature Ranks
The file `feature_rank_traindata_Bill_Upper_Travis_120_Travis_180.xlsx` contains all features ranked according to their importance. This file might be updated in the future.

## All Datafiles from 2023
The file `alldatafiles_2023.mat` contains all the data files from the year 2023.
