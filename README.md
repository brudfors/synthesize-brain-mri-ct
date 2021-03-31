# Brain MR and CT Synthesize
This is code for model-based image synthesize (translation) of brain CTs and MRIs (T1w, T2w, PDw). Given any combination of valid input modalities (MR-T1w, MR-T2w, MR-PDw, CT) the missing modalities will be synthesized. For example, if a subject has only a T2w scans, the T1w, PDw and CT scan will be synthesized:

<img style="float: right;" src="https://github.com/brudfors/synthesize-brain-mri-ct/blob/master/example.png" width="80%" height="80%">

The implementation is done in Matlab and depends on the SPM12 package (and its MB toolbox). The code should work on raw images; that is, with minimal preprocessing applied beforehand. It furthermore requires no training, as it is fully unsupervised.
