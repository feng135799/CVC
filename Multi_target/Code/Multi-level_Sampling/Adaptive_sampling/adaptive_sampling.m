% The demo below is for wavelets
clc;clear;close all;imtool close all;

% add the path to the solver
addpath('/home/akshay/Desktop/CVC/Multi_target/Code/Multi-level_Sampling/spgl1-1.9')

img = imread('10-12813-01-2.bmp');
img_gray = rgb2gray(img);
I_full = double(img_gray);
I = I_full(1:512,1:512)/255;


%% Step 1: through trail and error, find a sparse approximation of the image in the wavelet domain
level = 8;
per = 0.03;
[II,S] = sparse_approx(I,level,per);
PSNR21 = psnr(II,I);

psnr_values=zeros(level,1);


% MulitWavelet plot
[C,S] = wavedec2(I,level,'haar');
   
dec=plotwavelet2(C,S,level,'haar',255,'square');

coeff=dec{1}/255;


% Finding no.of non zero coeff at each level
% max_level=log2(size(I,1));
% coeff_level=zeros(level,1);
% for i=1:level
%     coeff_count=nnz(coeff(1:2^(max_level-level+i),1:2^(max_level-level+i)));
%     coeff_count = coeff_count-sum(coeff_level);
%     coeff_level(i) = coeff_count;
% end

% Turns out none of them are zeros so basically got how many points are in
% that level.

%% Step 2: perform sampling
[n1,n2] = size(I);
N = n1*n2;
m = floor(per*N);
const = 6;
M = const*m;

c = 3; % 1 - uniform, 2 - Fourier+wavelet, 3 - Hadamard+wavelet
scheme = uniform_rect_samp_scheme(n1,n2,M);
sample_level={};
% using samples of that level only
for i=2:length(scheme) % since 1st value in schema should be 4 always
    temp_scheme=zeros(size(scheme));
    temp_scheme(1:i)=scheme(1:i); % scheme values till that level
    pos = random_rect_subsamp(temp_scheme);
    IND = sub2ind([n1,n2],pos(:,1),pos(:,2));
    IND = sort(IND);
    
    % counting actual number of samples which is not same as given in
    % schema but close enough. So I am assuming, whatever values I am
    % giving to schema, I get exactly that 
    [sample_level{i-1}]=sample_level_count(I,IND,level); 
    b = fwht2(I);
    b = b(IND)*sqrt(n1*n2);
    bb = fwht2(II);
    bb = bb(IND)*sqrt(n1*n2);
    sigma = norm(bb-b);
    opA = @(x,mode) partial_Hadamard(x,S,IND,n1,n2,level,mode);
    C = spg_bpdn(opA,b,sigma);
    III = waverec2(C,S,'haar'); % Changed from haar to db4
    III = reshape(III,n1,n2);
    %imtool(III) 
    
    % saving the figures 
    des=num2str(i-1);
    des=strcat('upto ',des);
    hFigure = imtool(III,[]);
    saveas(hFigure,des,'png')
    psnr_values(i-1) = psnr(III,I);
%     set(hFigure,'NumberTitle','off','Name',des);
end    

plot(psnr_values)
xlabel('Levels')
ylabel('PSNR')  
imtool close all


