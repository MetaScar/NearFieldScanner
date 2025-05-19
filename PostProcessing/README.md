# Quickstart

The most powerful version of the post processing is contained in the `post_proc_nf_scan.m` Matlab file. By default, it uses the `NearFieldRawdata_Eravant_051525.mat` file located in the `./PostProcessing/Data/` directory. This file is provided in this GitHub repo as a link to a OneDrive as the file is around 600 MB (GitHub allows only a maximum of 100 MB before requiring [git-lfs](https://git-lfs.com/)). We do not use git-lfs due to our group's better familiarity with OneDrive compared to git.

With the post processing, the user can
- Time gate measurement by plotting both time and frequency domain
- Plot the near-field
- Plot the far-feild
- Plot the near-field radiation pattern to determine the phase center
- Plot the far-field radiation pattern 
- Plot 2D cuts at phi at 0, 45, and 90 degrees

Do be warned that the code can be quite memory hungry due to interpolation. To reduce memory usage by reducing interpolation, reduce the variable `N1q`.
