%% Import the MRI image and extract volumes

% Specify the path to the NIfTI file containing brain imaging data
path_func = "BRATS_008.nii.gz";

% Read the NIfTI file and get its information
Vf = niftiread(path_func); 
info = niftiinfo(path_func); 

dim = size(Vf);

% Extract FLAIR, T1w, T1gd, and T2w volumes
flair_volume = Vf(:,:,:,1); % Assuming FLAIR is the first volume
t1w_volume = Vf(:,:,:,2);   % Assuming T1w is the second volume
t1gd_volume = Vf(:,:,:,3);  % Assuming T1gd is the third volume
t2w_volume = Vf(:,:,:,4);   % Assuming T2w is the fourth volume

% % Define slices for visualization to show a 3D image as a 2D image
sliceX = 150; 
sliceY = 80; 
sliceZ = 60;

% Display the extracted volumes
figure;
subplot(2,2,1); imshow(flair_volume(:,:,sliceZ), []);
subplot(2,2,2); imshow(t1w_volume(:,:,sliceZ), []);
subplot(2,2,3); imshow(t1gd_volume(:,:,sliceZ), []);
subplot(2,2,4); imshow(t2w_volume(:,:,sliceZ), []);
%% Extract frontal, sagittal and horizontal view for the selected MRI type

% Looking at different images, we choose to work with t1gd volume 
% Extract frontal, sagittal, and horizontal slices
frontal = t1gd_volume(:,:,sliceZ);
sagittal = reshape(t1gd_volume(sliceX,:,:),[dim(2) dim(3)]); 
horizontal = reshape(t1gd_volume(:,sliceY,:),[dim(1) dim(3)]);

figure;
subplot(2,2,1); imshow(imrotate(frontal,90), []); title('Frontal');
subplot(2,2,2); imshow(imrotate(sagittal,90), []); title('Sagittal');
subplot(2,2,3); imshow(imrotate(horizontal,90), []); title('Horizontal');
%% Noise removal done with blurring using a median filter 

% Apply a median filter to blur the image in order to remove noise
% This intermediate step will make the segmentation easier
kernel_size = 8; % Experimentally determined
frontal_filtered = medfilt2(frontal, [kernel_size, kernel_size]);
sagittal_filtered = medfilt2(sagittal, [kernel_size, kernel_size]);
horizontal_filtered = medfilt2(horizontal, [kernel_size, kernel_size]);

% Display filtered slices
figure
subplot(2,2,1); imshow(imrotate(frontal_filtered,90), []); title('Frontal (Filtered)');
subplot(2,2,2); imshow(imrotate(sagittal_filtered,90), []); title('Sagittal (Filtered)');
subplot(2,2,3); imshow(imrotate(horizontal_filtered,90), []); title('Horizontal (Filtered)');

%% Pixel-based segmentation 

% Apply Otsu's multi-level thresholding
levels = 10; % Specify the number of desired regions. Sperimentally determined
thresholds_frontal = multithresh(frontal_filtered, levels);
thresholds_sagittal = multithresh(sagittal_filtered, levels);
thresholds_horizontal = multithresh(horizontal_filtered, levels);

frontal_otsu = imquantize(frontal_filtered, thresholds_frontal);
sagittal_otsu = imquantize(sagittal_filtered, thresholds_sagittal);
horizontal_otsu = imquantize(horizontal_filtered, thresholds_horizontal);

% Extract a specific region after Otsu's thresholding
region = 9 % Sperimentally determined
binary_frontal = frontal_otsu == region;
binary_sagittal = sagittal_otsu == region;
binary_horizontal = horizontal_otsu == region;

% Display binary images after thresholding
figure
subplot(2,2,1); imshow(imrotate(binary_frontal,90)); title('Otsu Frontal');
subplot(2,2,2); imshow(imrotate(binary_sagittal,90)); title('Otsu Sagittal');
subplot(2,2,3); imshow(imrotate(binary_horizontal,90)); title('Otsu Horizontal');
%% Morphological operation (dilatation) to connect pixels of segmented area

se = strel('disk', 3); % Structuring element (disk with radius 3)
dilated_frontal = imdilate(binary_frontal, se);
dilated_sagittal = imdilate(binary_sagittal, se);
dilated_horizontal = imdilate(binary_horizontal, se);

% Display images after dilatation
figure
subplot(2,2,1); imshow(imrotate(dilated_frontal,90)); title('Dilatated Frontal');
subplot(2,2,2); imshow(imrotate(dilated_sagittal,90)); title('Dilatated Sagittal');
subplot(2,2,3); imshow(imrotate(dilated_horizontal,90)); title('Dilatated Horizontal');
%% Read the grond truth image, take same slices used for detection and extract the 3 views

path_func_label = "BRATS_008_label.nii.gz";
V_label = niftiread(path_func_label);

dim = size(V_label);

% % Define slices for visualization to show a 3D image in a 2D image
sliceX = 150; 
sliceY = 80; 
sliceZ = 60;

frontal_label = squeeze(V_label(:,:,sliceZ)); % Extract the 2D slice along the X-axis
sagittal_label = squeeze(V_label(sliceX,:,:)); % Extract the 2D slice along the X-axis
horizontal_label = squeeze(V_label(:,sliceY,:)); % Extract the 2D slice along the X-axis

%% Show all steps

figure
subplot(3,4,1); imshow(imrotate(frontal_filtered,90), []); title('Frontal');
subplot(3,4,2); imshow(imrotate(binary_frontal,90), []); title('Otsu Frontal');
subplot(3,4,3); imshow(imrotate(dilated_frontal,90), []); title('Dilatated Frontal');
subplot(3,4,4); imshow(imrotate(frontal_label,90), []); title('Ground-truth Frontal');
subplot(3,4,5); imshow(imrotate(sagittal_filtered,90), []); title('Sagittal');
subplot(3,4,6); imshow(imrotate(binary_sagittal,90), []); title('Otsu Sagittal');
subplot(3,4,7); imshow(imrotate(dilated_sagittal,90), []); title('Dilatated Sagittal');
subplot(3,4,8); imshow(imrotate(sagittal_label,90), []); title('Ground-truth Sagittal');
subplot(3,4,9); imshow(imrotate(horizontal_filtered,90), []); title('Horizontal');
subplot(3,4,10); imshow(imrotate(binary_horizontal,90), []); title('Otsu Horizontal');
subplot(3,4,11); imshow(imrotate(dilated_horizontal,90), []); title('Dilatated Horizontal');
subplot(3,4,12); imshow(imrotate(horizontal_label,90), []); title('Ground-truth Horizontal');