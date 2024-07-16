function [net,traininfo,options] = ET_pred_1step_train_RT(NN_param,Traindata,t)
%% Load training parameters
miniBatchSize_train = NN_param.miniBatchSize_train;
numResponses = NN_param.numResponses;
numHiddenUnits = NN_param.numHiddenUnits;
initial_LR = NN_param.initial_LR;
gradient_thr = NN_param.gradient_thr;
dropput_prob = NN_param.dropput_prob;
maxEpochs = NN_param.maxEpochs;
numFeatures = NN_param.numFeatures;

%% NN architecture 

lgraph = layerGraph;

lgraph = addLayers(lgraph,featureInputLayer(numFeatures(1,1),"Name","layers_S_in"));
lgraph = addLayers(lgraph,featureInputLayer(numFeatures(1,2),"Name","layers_ET_in"));
nLabels = {strcat('layers_S_in' , '_' , string(numFeatures(1,1)) )};
nLabels{end+1} = strcat('layers_ET_in' , '_', string(numFeatures(1,2)) );

l_prev_S = "layers_S_in";
l_prev_ET = "layers_ET_in";
for i = 1:length(numHiddenUnits(1,:))
    % row 1 = sensor; row 2 = ET; row 3 = combined; 
    if numHiddenUnits(1,i)> 0
        layername_S = "layers_S_hidden" + string(i);
        lgraph = addLayers(lgraph,fullyConnectedLayer(numHiddenUnits(1,i),"Name",layername_S));
        lgraph = connectLayers(lgraph,l_prev_S,layername_S);
        nLabels{end+1} = strcat( layername_S , '_', string(numHiddenUnits(1,i)));
        l_prev_S = layername_S;

        % add batchNormalizationLayer
        layername_S = "bnlayer_S" + string(i);
        lgraph = addLayers(lgraph,reluLayer("Name",layername_S));
        lgraph = connectLayers(lgraph,l_prev_S,layername_S);
        nLabels{end+1} = strcat(layername_S , '_', string(numHiddenUnits(1,i)));
        l_prev_S = layername_S;

        % add relulayer
        layername_S = "reluLayer_S" + string(i);
        lgraph = addLayers(lgraph,reluLayer("Name",layername_S));
        lgraph = connectLayers(lgraph,l_prev_S,layername_S);
        nLabels{end+1} = strcat(layername_S , '_', string(numHiddenUnits(1,i)));
        l_prev_S = layername_S;
    end
    if numHiddenUnits(2,i)> 0
        layername_ET = "layers_ET_hidden" + string(i);
        lgraph = addLayers(lgraph,fullyConnectedLayer(numHiddenUnits(2,i),"Name",layername_ET));
        lgraph = connectLayers(lgraph,l_prev_ET,layername_ET);
        nLabels{end+1} = strcat(layername_ET , '_', string(numHiddenUnits(2,i)));
        l_prev_ET = layername_ET;

        % add batchNormalizationLayer
        layername_ET = "bnLayer_ET" + string(i);
        lgraph = addLayers(lgraph,reluLayer("Name",layername_ET));
        lgraph = connectLayers(lgraph,l_prev_ET,layername_ET);
        nLabels{end+1} = strcat(layername_ET , '_', string(numHiddenUnits(2,i)));
        l_prev_ET = layername_ET;

        % add relulayer
        layername_ET = "reluLayer_ET" + string(i);
        lgraph = addLayers(lgraph,reluLayer("Name",layername_ET));
        lgraph = connectLayers(lgraph,l_prev_ET,layername_ET);
        nLabels{end+1} = strcat(layername_ET , '_', string(numHiddenUnits(2,i)));
        l_prev_ET = layername_ET;
    end
    % append dropout if not the last layer
    if i < length(numHiddenUnits(1,:))        % need to double check this condition, looks like the underlying assumption is numHiddenUnits will always have equal number of elements (and they are all non-zeros) in all of the rows
        
        % add dropoutlayer
        layername_S = "dropoutLayer_S" + string(i);
        lgraph = addLayers(lgraph,dropoutLayer(dropput_prob,"Name",layername_S));
        lgraph = connectLayers(lgraph,l_prev_S,layername_S);
        nLabels{end+1} = strcat(layername_S , '_', string(dropput_prob));
        l_prev_S = layername_S;

        layername_ET = "dropoutLayer_ET" + string(i);
        lgraph = addLayers(lgraph,dropoutLayer(dropput_prob,"Name",layername_ET));
        lgraph = connectLayers(lgraph,l_prev_ET,layername_ET);
        nLabels{end+1} = strcat(layername_ET , '_', string(dropput_prob));
        l_prev_ET = layername_ET;
    end
end

concat = concatenationLayer(1,2,'Name','concat'); % check dimension

lgraph = addLayers(lgraph, concat);

lgraph = connectLayers(lgraph, l_prev_S, 'concat/in1');
lgraph = connectLayers(lgraph, l_prev_ET, 'concat/in2');
nLabels{end+1} = strcat(concat.Name);

l_prev = concat.Name;

for i = 1:length(numHiddenUnits(3,:))
    if numHiddenUnits(3,i)> 0
        layername = "layers_hidden" + string(i);
        lgraph = addLayers(lgraph,fullyConnectedLayer(numHiddenUnits(3,i),"Name",layername));
        lgraph = connectLayers(lgraph,l_prev,layername);
        nLabels{end+1} = strcat(layername , '_', string(numHiddenUnits(3,i)));
        l_prev = layername;

        % add batchNormalizationLayer
        layername = "bnLayer" + string(i);
        lgraph = addLayers(lgraph,reluLayer("Name",layername));
        lgraph = connectLayers(lgraph,l_prev,layername);
        nLabels{end+1} = strcat(layername , '_', string(numHiddenUnits(3,i)));
        l_prev = layername;

        % add relulayer
        layername = "reluLayer" + string(i);
        lgraph = addLayers(lgraph,reluLayer("Name",layername));
        lgraph = connectLayers(lgraph,l_prev,layername);
        nLabels{end+1} = strcat(layername , '_', string(numHiddenUnits(3,i)));
        l_prev = layername;
    end
    % append dropout if not the last layer
    if i < length(numHiddenUnits(3,:))
        % add dropoutlayer
        layername = "dropoutLayer" + string(i);
        lgraph = addLayers(lgraph,dropoutLayer(dropput_prob,"Name",layername));
        lgraph = connectLayers(lgraph,l_prev,layername);
        nLabels{end+1} = strcat(layername , '_', string(dropput_prob));
        l_prev = layername;
    end
end

layername = "outputLayer";
lgraph = addLayers(lgraph,fullyConnectedLayer(numResponses,"Name",layername));
lgraph = connectLayers(lgraph,l_prev,layername);
nLabels{end+1} = strcat(layername , '_', string(numResponses));
l_prev = layername;
layername = "regressionLayer";
lgraph = addLayers(lgraph,regressionLayer("Name",layername));
lgraph = connectLayers(lgraph,l_prev,layername);
nLabels{end+1} = strcat(layername);

%% showfigure
% figure('units','inch','Position',[0 0 13 10]) %[left bottom width height]
% plot(lgraph)
% gplot = gca().Children;
% 
% for i = 1:length(nLabels)
%     newlabels{i} = convertStringsToChars(nLabels{i});
% end
% 
% gplot.NodeLabel = newlabels;
% graphfilename = "FNN architecture" + "_" + join(string(numHiddenUnits(1,:))) + "_" + join(string(numHiddenUnits(2,:))) + "_" + join(string(numHiddenUnits(3,:)));
% title(strrep(graphfilename,"_","\_"))
% 
% % savefigure
% saveas(gcf,[graphfilename + ".png"])
% savefig(graphfilename)
% close(gcf)
%% Train
options = trainingOptions('adam', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize_train, ...
    'InitialLearnRate',initial_LR, ...
    'GradientThreshold',gradient_thr, ...
    'Shuffle','every-epoch', ...
    'Plots','training-progress',...
    'Verbose',1);

[net, traininfo] = trainNetwork(Traindata,lgraph,options);

%% save training plot
% currentfig = findall(groot, 'Tag', 'NNET_CNN_TRAININGPLOT_UIFIGURE');
% filename_date = datestr(now, 'dd_mm_yy_HH_MM');
% filename_seed = string(t.Seed);
% trainingfilename = "Traininginfo"  + "_" + join(string(numHiddenUnits(1,:))) + "_" + join(string(numHiddenUnits(2,:))) + "_" + join(string(numHiddenUnits(3,:))) + "_seed_" + string(filename_seed) + "_datetime_" + filename_date;
% savefig(currentfig,trainingfilename);
% close
end
