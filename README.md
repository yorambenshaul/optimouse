# optimouse

This repository contains source files for running optimouse, a program for analusis of mouse position data

A few notes on running optimouse:
- Make sure that both the "optimouse" and the "optimouse_user_definitions" directories are in the MATLAB path.
- To run optimouse, type "optimouse" on the command line, this will show the main optimouse GUI.
- The "instructions" button in the main optimouse GUI will open the user manual (from its location in the optimouse folder)
- when first opening optimouse (with any of the specific GUIS  - prepare, detect, review, analyze) you will need to specify the main video directory - otherwise no files will be shown. The main video directory is the parent directory to all video files. During processing, OptiMouse will add various sub-directories and files into the main video directory. 

Notes and disclaimers:
- optimouse requires the MATLAB statistics and image processing toolboxes.
- It was tested on MATLAB releases 2015b and 2016a, and partially on 2016b. It is known not to be compatible with some older versions. 
- optimouse was tested on a PC, with a windows operating system. Although MATLAB should be platform independent, it was NOT tested on different operating systems (MAC, Linux).
- The GUIs are specified in normalized units, but it appears that some screen ratios/resolutions may change GUI proportions, in some cases even obscuring GUI controls. These issues can be fixed using the GUIDE tool. 
- OptiMouse has been tested by multiple users using several video files and analyses. Nevertheless, it is almost certain that there are undiscoevered bugs. If any bugs are discoevered please contact me.


This version last updated Feb 2017. Ver 3.0.

Contact Yoram Ben-Shaul for assistance and suggestions.
yoram ben-shaul
yoramb@ekmd.huji.ac.il



