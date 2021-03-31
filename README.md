# Brain MR and CT Synthesize
This is code for model-based image synthesize (translation) of brain CTs and MRIs (T1w, T2w, PDw). Given any combination of valid input modalities (MR-T1w, MR-T2w, MR-PDw, CT) the missing modalities will be synthesized. For example, if a subject has only a PDw scans, the T1w, T2w and CT scan will be synthesized:

<img style="float: right;" src="https://github.com/brudfors/synthesize-brain-mri-ct/blob/main/example.png" width="60%" height="60%">

The implementation is done in Matlab and depends on the SPM12 package (and its MB toolbox). The code should work on raw images; that is, with minimal preprocessing applied beforehand. It furthermore requires no training, as it is fully unsupervised.

## Dependencies

The algorithm requires that the following packages are on the MATLAB path:
* **SPM12:** Download from https://www.fil.ion.ucl.ac.uk/spm/software/spm12/.
* **Shoot toolbox:** Add Shoot folder from the toolbox directory of the SPM source code.
* **Longitudinal toolbox:** Add Longitudinal folder from the toolbox directory of the SPM source code.
* **Multi-Brain toolbox:** Download (or clone) from https://github.com/WTCN-computational-anatomy-group/diffeo-segment and add to the toolbox folder of SPM, renamed `mb`.

## Example use case

This example code synthesize T1w, T2w and CT scans from an input PDw MRI. The ouputs are written in the `odir` folder, prefixed `mi*`.

``` matlab
files      = {'PDw.nii'};   % path to PDw MR image
modalities = {'pd'};        % inform algorithm that the image is a PDw
odir       = 'synthesized'; % folder where to write output

spm_synthesize_mri_ct(files, modalities, odir);
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
