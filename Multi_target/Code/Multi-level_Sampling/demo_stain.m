% The demo below is for wavelets
clc;clear;close all
%load('Shepp-Logan.mat') % test image, 1024 by 1024
addpath('/home/akshay/Desktop/CVC/Multi_target/Code/Multi-level_Sampling/spgl1-1.9')

img = imread('10-12813-01-2.bmp');
img_gray = rgb2gray(img);
I_full = double(img_gray);
I = I_full(1:512,1:512)/255;
%I = I_512;


%for i=1:8
   
%% Step 1: through trail and error, find a sparse approximation of the image in the wavelet domain
level = 8;
per = 0.03;
[II,S] = sparse_approx(I,level,per);
PSNR21 = psnr(II,I); % model error

%% Step 2: perform sampling
[n1,n2] = size(I);
N = n1*n2;
m = floor(per*N);
const = 6;
M = const*m;

c = 3; % 1 - uniform, 2 - Fourier+wavelet, 3 - Hadamard+wavelet

switch c
    case 1
        % uniform sampling
        IND = randsample(n1*n2,M); % uniform sampling
        IND = sort(IND);
    case 2
        % multi-level sampling (Fourier+wavelet)
        nu = round(log2(min(n1,n2)));
        bounds = [2^(nu-4),2^(nu-2),2^(nu-1)];
        pos = random_circ_subsamp(n1,n2,bounds,M);
        IND = sub2ind([n1,n2],pos(:,1),pos(:,2));
        IND = sort(IND);
    case 3
        % multi-level sampling (Hadamard+wavelet)
        scheme = uniform_rect_samp_scheme(n1,n2,M);
        pos = random_rect_subsamp(scheme);
        IND = sub2ind([n1,n2],pos(:,1),pos(:,2));
        IND = sort(IND); % Note this has repetitions
end



%% Step 3: recovery from samples

switch c
    case 1
        b = I(IND);
        bb = II(IND);
        sigma = norm(II(IND)-I(IND));
        opA = @(x,mode) partial_Uniform(x,S,IND,n1,n2,level,mode);
    case 2 
        b = fftshift(fft2(I))/sqrt(n1*n2);
        b = b(IND);
        bb = fftshift(fft2(II))/sqrt(n1*n2);
        bb = bb(IND);
        sigma = norm(bb-b);
        opA = @(x,mode) partial_Fourier(x,S,IND,n1,n2,level,mode);
    case 3
        b = fwht2(I);
        b = b(IND)*sqrt(n1*n2);
        bb = fwht2(II);
        bb = bb(IND)*sqrt(n1*n2);
        sigma = norm(bb-b);
        opA = @(x,mode) partial_Hadamard(x,S,IND,n1,n2,level,mode);
end

C = spg_bpdn(opA,b,sigma);
III = waverec2(C,S,'haar'); % Changed from haar to db4
III = reshape(III,n1,n2);

PSNR32 = psnr(III,II); % recovery error
PSNR31 = psnr(III,I); 

% %%% 2-norm error
% error21 = norm(I-II);
% error23 = norm(II-III);
error13 = norm(I-III)/norm(I)*100;

%%% Frobenius-norm error
error13_fro = norm(I-III,'Fro')/norm(I,'Fro')*100;

%%% inf-norm error
error13_inf = norm(I-III,'inf')/norm(I,'inf')*100;


%%% If value is scaled between 0-255 
% figure(1)
% imshow(uint8(I))
% figure(2)
% imshow(uint8(II))
% figure(3)
% imshow(uint8(III))

%%% If value is scaled between 0-1
% imtool(I)
% imtool(II)
% imtool(III)

% MulitWavelet plot
[C,S] = wavedec2(I,level,'haar');
   
dec=plotwavelet2(C,S,level,'haar',255,'square');

%% Finding no.of samples at each level

% % showing the sampling pattern
% sample=zeros(size(I));
% sample(IND)=1;
% imshow(sample)
% 
% % Finding no.of samples at each level
% max_level=log2(size(I,1));
% sample_level=zeros(level,1);
% for i=1:level
%     count=nnz(sample(1:2^(max_level-level+i),1:2^(max_level-level+i)));
%     sample_count = count-sum(sample_level);
%     sample_level(i) = sample_count;
% end
% 
% coeff=dec{1}/255;
% 
% % showing the sparsity
% % Finding no.of coeff at each level
% coeff_level=zeros(level,1);
% for i=1:level
%     coeff_count=nnz(coeff(1:2^(max_level-level+i),1:2^(max_level-level+i)));
%     coeff_count = coeff_count-sum(coeff_level);
%     coeff_level(i) = coeff_count;
% end
% 
