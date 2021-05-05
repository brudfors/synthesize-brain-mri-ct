# Brain MR and CT Synthesize
This is code for model-based image synthesize (translation) of brain CTs and MRIs. Given any combination of valid input modalities - MR-T1w, MR-T2w, MR-PDw, CT - the missing modalities will be synthesized. For example, if a subject has only a T1w scan, the CT, PDw and T2w scans will be synthesized:

<img style="float: right;" src="https://github.com/brudfors/synthesize-brain-mri-ct/blob/main/example.png" width="60%" height="60%">

The implementation is done in MATLAB and depends on the SPM12 package (and its MB toolbox). The code should work on **raw images**; that is, with minimal preprocessing applied beforehand. It furthermore requires no training, as it is fully **unsupervised**. If you find the code useful, please consider citing the publication in the *Reference* section.

## Dependencies

The algorithm is developed using MATLAB and relies on external functionality from the SPM12 software. The following are therefore required downloads and need to be placed on the MATLAB search path (using `addpath`):
* **SPM12:** Download from https://www.fil.ion.ucl.ac.uk/spm/software/download/.
* **Shoot toolbox:** The Shoot folder from the toolbox directory of SPM12.
* **Longitudinal toolbox:** The Longitudinal folder from the toolbox directory of SPM12.
* **Multi-Brain toolbox:** Download/clone https://github.com/WTCN-computational-anatomy-group/mb and follow the *Installation instructions*.

## Example use cases

This example code synthesize CT, PDw and T2w scans from an input T1w MRI. The ouputs are written in the `odir` folder, prefixed `mi*`. Note that only the missing modalities are synthesized, others remain the same as their input (but intensity non-uniformity corrected).

``` matlab
files      = 'T1w.nii';     % path to T1w MR image
modalities = 't1';          % inform algorithm that the image is a T1w
odir       = 'synthesized'; % folder where to write output

spm_synthesize_mri_ct(files, modalities, odir);
```

This example code synthesize PDw and CT scans from input T1w and T2w MRIs. The ouputs are written in the same folder as the input images, prefixed `mi*`.

``` matlab
files      = {'T1w.nii', 'T2w.nii'};   % path to PDw MR image
modalities = {'t1', 't2'};             % inform algorithm that the image is a PDw

spm_synthesize_mri_ct(files, modalities);
```

## Reference

``` latex
@inproceedings{brudfors2019empirical,
  title={Empirical bayesian mixture models for medical image translation},
  author={Brudfors, Mikael and Ashburner, John and Nachev, Parashkev and Balbastre, Ya{\"e}l},
  booktitle={International Workshop on Simulation and Synthesis in Medical Imaging},
  pages={1--12},
  year={2019},
  organization={Springer}
}
```

## License

This software is free but copyright software, distributed under the terms of the GNU General Public Licence as published by the Free Software Foundation (either version 2, or at your option, any later version).
