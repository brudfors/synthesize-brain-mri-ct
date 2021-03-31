function spm_synthesize_mri_ct(files, modalities, odir)
% Image synthesize (translation) of CTs and MRIs. Input images (.nii) need 
% to be of the same dimensions. Output synthesized scans are prefixed as:
%     - mi1_*: CT
%     - mi2_*: T1w
%     - mi3_*: T2w
%     - mi4_*: PDw
% Note, only the missing modalities are synthesized, others remain the same
% as input (but intensity non-uniformity corrected).
%
% PARAMETERS
% ----------
% files : cell(str) of length N
%     Paths to N input image(s) (.nii).
% modalities : cell(str) of length N
%     Modality of N input image(s), options are:
%     - 't1' | 'T1'
%     - 't2' | 'T2'
%     - 'pd' | 'PD'
%     - 'ct' | 'CT'
% odir : str, optional
%     Folder where to write synthesised images. Default uses same as input.
%
% REFERENCE
% ----------
% Brudfors, M., Ashburner, J., Nachev, P. and Balbastre, Y., 2019, October.
% Empirical bayesian mixture models for medical image translation. In
% International Workshop on Simulation and Synthesis in Medical Imaging
% (pp. 1-12). Springer, Cham.
%
%_______________________________________________________________________
if nargin < 3, odir = '.'; end

% add MB toolbox
addpath(fullfile(spm('dir'),'toolbox','mb')); 

% parameters
pth_mu  = '/home/mbrud/Projects/mb-tools/mb-merge/mu_merged.nii';
pth_int = '/home/mbrud/Projects/mb-tools/mb-merge/prior_merged_2.mat';
modalities_learned = {'ct', 't1', 't2', 'pd'};  % order of modalities in learned intensity prior

% sanity check
if ischar(files), files = {files}; end
if ischar(modalities), modalities = {modalities}; end    
if ~iscell(files) || ~iscell(modalities)
    error('Inputs need to be cell arrays!')
end
if numel(files) ~= numel(modalities)
    error('Same number of input images and input types need to be given!')
end
for i=1:numel(modalities)
    if ~any(strcmp(modalities{i}, modalities_learned))
        error('Undefined input type!')
    end
end
if numel(unique(files)) ~= numel(files)
    error('There are duplicates in input types!')
end

% output directory
[odir0,nam,ext] = fileparts(files{1});
if nargin < 3, odir = odir0; end
if ~(exist(odir,'dir') == 7), mkdir(odir); end    

% order input files to match intensity prior
images = cell(1,numel(modalities_learned));
for i1=1:numel(modalities_learned)  % loop over modalities in intensity prior
    for i2=1:numel(modalities)  % loop over input modalities
        if strcmpi(modalities{i2}, modalities_learned{i1})
            images{i1} = files{i2};
            break
        end
    end
end

% make dummy files (for missing modalities)
dummies = cell(1,numel(modalities_learned));
for i=1:numel(images)
    if isempty(images{i})
        dummies{i}     = fullfile(odir,['dummy' num2str(i) '_' nam ext]);
        copyfile(fullfile(odir0, [nam ext]), dummies{i});
        Nii            = nifti(dummies{i});
        Nii.dat(:,:,:) = 0;
        images{i}      = dummies{i};
    end
end

% algorithm settings
run             = struct;
run.mu.exist    = {pth_mu};
run.onam        = 'synthesise_mri_ct';
run.odir        = {odir};        
run.gmm.pr.file = {pth_int};
run.v_settings  = [0.00001 0 0.4 0.1 0.4]*4;
% input images
modality = [2, 1, 1, 1];
inu_reg  = [1e6, 1e3, 1e3, 1e3];
for i=1:numel(images)
    run.gmm(1).chan(i).images      = {images{i}};
    run.gmm(1).chan(i).modality    = modality(i);
    run.gmm(1).chan(i).inu.inu_reg = inu_reg(i);
end
% output settings
out        = struct;
out.result = {fullfile(run.odir{1},['mb_fit_' run.onam '.mat'])};
out.i      = false;
out.mi     = true;
out.wi     = false;
out.wmi    = false;
out.c      = false;

% fit model and make output
jobs{1}.spm.tools.mb.run = run;
jobs{2}.spm.tools.mb.out = out;
spm_jobman('run', jobs);

% subtract 1,000 from output CT image
[pth,nam,ext]  = fileparts(images{1});
pth_ct         = fullfile(pth, ['mi1_1_00001_' nam '_' run.onam ext]);
Nii            = nifti(pth_ct);
dat            = Nii.dat();
dat            = dat - 1000;
Nii.dat(:,:,:) = dat;

% clean-up
spm_unlink(fullfile(pth, ['v_1_00001_' nam '_' run.onam ext]));
spm_unlink(fullfile(pth, ['y_1_00001_' nam '_' run.onam ext]));
spm_unlink(out.result{1});
for i=1:numel(dummies)    
    if ~isempty(dummies{i})
        spm_unlink(dummies{i});
    end
end

return
%==========================================================================