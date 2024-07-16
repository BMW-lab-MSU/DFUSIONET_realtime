# DFUSIONET_RT

# Irrigation Prediction Model

This repository contains a MATLAB script for predicting irrigation requirements using sensor and spatial data. The script preprocesses data, trains a neural network model, makes predictions, and generates irrigation prescriptions based on the predicted evapotranspiration (ET).

IMPORTANT: before running the real-time prediction main file (main_ET_pred_1step_RT.m), make sure the specific sites in the datafiles/Irrigation_rec/[sitename]/ directory has 3 folders named 'Figures', 'Final Output', and 'SpatialPredET'.

## Table of Contents
- [Usage](#usage)
- [User Inputs](#user-inputs)
- [Script Workflow](#script-workflow)
  - [Data Preprocessing](#data-preprocessing)
  - [Model Training](#model-training)
  - [Prediction](#prediction)
  - [Irrigation Prescription](#irrigation-prescription)
- [Dependencies](#dependencies)
- [Data Files](#data-files)
- [Results](#results)
- [Contact](#contact)

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/[]
   cd irrigation-prediction

2. Place the required data files in the 'datafiles' directory.

3. Open the MATLAB script and set the user inputs as needed.

4. Run the script in MATLAB.

## User Inputs

- `site_idx`: Index to select which site to work with (1 for R5, 2 for R6).
- `currentdate`: Current irrigation date.
- `last_irr_date`: Last irrigation date.
- `site_dir`: Directory containing site data files.
- `filename_2023`: Filename of the 2023 data file.
- `n_features`: Number of features for the model.
- `window_size`: Sliding window size (in days) for the time series.
- `a`: RNG array for initializing neural network predictors.
- `xval`: Hidden layer sizes for the neural network.
- `NN_param`: Parameters for the neural network (batch size, learning rate, dropout probability, epochs).

## Script Workflow

### Data Preprocessing

- Load sensor (Arable) ETc data and spatial ET data for the selected site.
- Filter and normalize the data based on the required dates and features.
- Perform proportional-offset interpolation (POI) to align site-specific values.
- Partition the data into sliding windows for time series analysis.

### Model Training

- Initialize the neural network with specified parameters.
- Train the neural network with multiple random initializations.
- Save the trained networks.

### Prediction

- Load the trained networks.
- Generate predictions for the specified date range.
- Save the predictions to CSV files.

### Irrigation Prescription

- Load the predicted spatial ET data.
- Calculate total ET from the last irrigation date to the current date.
- Save the irrigation prescription to a CSV file.

## Dependencies

- MATLAB R2021b or later
- Neural Network Toolbox

## Data Files

- `datafiles/Irrigation_rec/`: Directory containing site data files.
- `datafiles/alldatafiles_2023.mat`: 2023 data file containing sensor and spatial data.

## Results

- Predicted spatial ET data saved as CSV files in the `SpatialPredET` directory.
- Irrigation prescription saved as a CSV file in the `Final output` directory.

## Contact

For any questions or issues, please contact Farshina at farshin.nazrulshimim@student.montana.edu
