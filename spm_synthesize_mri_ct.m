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
if nargin < 3, odir = ''; end

% check MATLAB path
%--------------------------------------------------------------------------
if isempty(fileparts(which('spm')))
    error('SPM12 not on the MATLAB path! Download from https://www.fil.ion.ucl.ac.uk/spm/software/download/'); 
end
if isempty(fileparts(which('spm_shoot3d')))
    error('Shoot toolbox not on the MATLAB path! Add from spm12/toolbox/Shoot'); 
end
if isempty(fileparts(which('spm_dexpm')))
    error('Longitudinal toolbox not on the MATLAB path! Add from spm12/toolbox/Longitudinal'); 
end
% add MB toolbox
addpath(fullfile(spm('dir'),'toolbox','mb')); 
if isempty(fileparts(which('spm_mb_fit')))
    error('Multi-Brain toolbox not on the MATLAB path! Download/clone from https://github.com/WTCN-computational-anatomy-group/mb and place in the SPM12 toolbox folder.');
end
if ~(exist('spm_gmmlib','file') == 3)
    error('Multi-Brain GMM library is not compiled, please follow the Install instructions on the Multi-Brain GitHub README.')
end

% parameters
%--------------------------------------------------------------------------
dir_code = fileparts(mfilename('fullpath'));
pth_mu   = fullfile(dir_code,'mu.nii');
pth_int  = fullfile(dir_code,'prior.mat');
modalities_learned = {'ct', 't1', 't2', 'pd'};  % order of modalities in learned intensity prior

% sanity check
%--------------------------------------------------------------------------
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

% Get model files
if ~(exist(pth_mu, 'file') == 2)
    % Path to model zip file
    pth_model_zip = fullfile(dir_code, 'model.zip');    
    % Model file not present
    if ~(exist(pth_model_zip, 'file') == 2)
        % Download model file
        url_model = 'https://www.dropbox.com/s/jpxxuv90ouv19c6/model.zip?dl=1';
        fprintf('Downloading model files (first use only)... ')
        websave(pth_model_zip, url_model);                
        fprintf('done.\n')
    end    
    % Unzip model file, if has not been done
    fprintf('Extracting model files  (first use only)... ')
    unzip(pth_model_zip, dir_code);
    fprintf('done.\n')    
    % Delete model.zip
    spm_unlink(pth_model_zip);
end

% output directory
[odir0,nam0,ext0] = fileparts(files{1});
if isempty(odir), odir = odir0; end
if ~isempty(odir) && ~(exist(odir,'dir') == 7), mkdir(odir); end

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
        dummies{i}     = fullfile(odir,['dummy' num2str(i) '_' nam0 ext0]);
        copyfile(fullfile(odir0, [nam0 ext0]), dummies{i});
        Nii            = nifti(dummies{i});
        Nii.dat(:,:,:) = NaN;
        images{i}      = dummies{i};
    end
end

% algorithm settings
run             = struct;
run.mu.exist    = {pth_mu};
run.onam        = 'synthesise_mri_ct';
run.odir        = {odir};        
run.gmm.pr.file        = {pth_int};
run.gmm.pr.hyperpriors = [];
run.v_settings  = [0.00001 0 0.4 0.1 0.4]*4;
run.min_dim     = 8;
% input images
mod_mri     = 1;
mod_ct      = 2;
inu_reg_mri = 1e4;
inu_reg_ct  = 1e6;
for i=1:numel(images)
    run.gmm(1).chan(i).images = {images{i}};
    if strcmpi(modalities_learned{i}, 'ct')
        run.gmm(1).chan(i).modality    = mod_ct;
        run.gmm(1).chan(i).inu.inu_reg = inu_reg_ct;
    else
        run.gmm(1).chan(i).modality    = mod_mri;
        run.gmm(1).chan(i).inu.inu_reg = inu_reg_mri;
    end        
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

% subtract 1,000 from output CT image (because 1,000 is added during the fitting process)
for i=1:numel(images)
    if strcmpi(modalities_learned{i}, 'ct')
        if isempty(dummies{i})
            pth_ct = fullfile(odir,['mi' num2str(i) '_1_00001_' nam0  '_' run.onam ext0]);
        else
            pth_ct = fullfile(odir,['mi' num2str(i) '_1_00001_dummy1_' nam0  '_' run.onam ext0]);
        end
        Nii            = nifti(pth_ct);
        dat            = Nii.dat();
        dat            = dat - 1000;
        Nii.dat(:,:,:) = dat;
    end
end

% clean-up
[~,nam,ext] = fileparts(images{1});
spm_unlink(fullfile(odir, ['v_1_00001_' nam '_' run.onam ext]));
spm_unlink(fullfile(odir, ['y_1_00001_' nam '_' run.onam ext]));
spm_unlink(out.result{1});
for i=1:numel(dummies)    
    if ~isempty(dummies{i})
        spm_unlink(dummies{i});
    end
end
%==========================================================================
