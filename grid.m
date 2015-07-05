% clc
% clear

% run('vlfeat/toolbox/vl_setup.m');
base = 'data/';

% Read class labels from file
classFile = [base 'meta/classes.txt'];
fid = fopen(classFile);
classes = textscan(fid, '%s', 'Delimiter', '\n');
classes = classes{1};

superpixelsPath = [base 'superpixels/'];
datasetPath = [base 'images/'];

% c = parcluster;
% matlabpool(c);
% parpool(c);
tic
encoded = encodeDataset(datasetPath, superpixelsPath, classes);
toc
% save('data_encoded.mat', 'encoded');
