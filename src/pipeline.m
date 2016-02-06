load('classes.mat', 'classes');
params = matfile('params.mat', 'Writable', true);
params.classes = classes;
params.nTrees = 10;
params.treeSamples = 200000;
params.nComponents = 20;
params.nClasses = 101;
params.descriptorType = 'surf';
params.gridStep = 8;
params.pyramidLevels = 3;
params.datasetPath = 'data/images';
params.descriptorBases = 512;
params.colorBases = 64;
params.pooling = 'mean';

if strcmp(params.descriptorType, 'sift')
    params.descriptorLength = 128;
    params.modes = 32;
elseif strcmp(params.descriptorType, 'surf')
    params.descriptorLength = 64;
    params.modes = 64;
end

params.encodingLength = params.descriptorBases + params.colorBases;
% if ~isfield(params, 'encParams')
%     encParams = calcGlobalParams(params);
%     save('params.mat', '-append', '-struct', 'encParams');
% end
params = load('params.mat');
disp(params);

% Generate random seed
[~, seed] = system('od /dev/urandom --read-bytes=4 -tu | awk ''{print $2}''');
seed = str2double(seed);
rng(seed);

% Compute bases
if ~isfield(params, 'Bd') || ~isfield(params, 'Bc')
    [Xd, Xc] = getFeatureSample(100, params.descriptorType, false);
    [Bd, Bc] = computeBases(Xd, Xc, params.descriptorBases, params.colorBases);
    params.Bd = Bd;
    params.Bc = Bc;
    save('params.mat', '-struct', 'params');
end

% Segment and encode dataset
if ~exist('data.mat', 'file')
    total = segmentDataset(params);
end

% Grow forest
trees = randomForest(params);

if ~exist('trees', 'var')
    load('trees.mat');
end

if ~exist('vset', 'var')
    load('vset', 'vset');
end

leaves = cell2mat(extractfield(trees, 'leaves'));

metrics = leafMetrics( leaves, params );
save('metrics.mat', '-struct', 'metrics');

if ~exist('metrics', 'var')
    metrics = load('metrics');
end

models = mineComponents(leaves, metrics, vset, params);
params.models = models;
save('params.mat', '-struct', 'params');

clear vset trees

trainFinalClassifier(params);
clear;

load('train.mat');
model = train(double(y), sparse(double(X)), '-s 2 -n 64');
save('model.mat', 'model');
clear;

load('test.mat');
load('model');
p = predict(double(y), sparse(double(X)), model);
