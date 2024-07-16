function [Tsensor_filtered] = filter_data_by_features_normalize(Tsensor_filtered,allfeatures_sorted)
% keep only important features in Tsensor
Tsensor_filtered = Tsensor_filtered(:,allfeatures_sorted);
% Normalize for each column
Tsensor_filtered{:,:} = single(normc(Tsensor_filtered{:,:}));
end