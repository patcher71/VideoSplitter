# VideoSplitter


This is a simple Matlab app for splitting up a video that contains multiple behavioral trials into either individual videos or a single compiled video containing just the trial events. In this case, the program was written for fear conditioning sessions, with markers for the CS/US collected from a MedAssociates system coupled to a TDT Photometry system with a camera collecting video at 20 fps.  

Only two files are needed: a .CSV file containing all of the camera frame events and the event markers (created using pMAT software), and the raw video file collected during the session.   The basic workflow is as follows:

(1) Use the 'Get Event Framepoints' program to find the event markers and organize them with respect to the camera frame number.  An 'adjusted frame reference' is used to add 10 seconds prior to the CS, and 5 s following the US.  So a single trial segment would be 25 seconds long (including the pre-CS, CS time of 10 s, US, and 5 seconds after).

(2) Use the 'Get Video File' button to load the raw uncompressed .avi video file ( a preview of the first 100 frames will be displayed).
(3) Use 'Create Video Segments' to create the segments (trials) between each CS-US by referencing the event framepoints created in step (1). 
(4) Choose to either write individual segment (trials) or a single video file containing all trials.  Although a single file will be much larger, when multiple trials are used, it may be easier for file handling.
(5) Give a file prefix for the created video (usually the animal identifier, and maybe the session; for example Rat14_Session1, etc.)
(6) Click Process Videos and the file will be sent to the current video file directory.

**In version 3, the event framepoint table will also indicate the duration of the marker (useful cross-check if different duration markers were used to to distinguish events).  In addition, when processing videos as 'All Trials', a 2s black frame will be added between video files to help distinguish when each trial starts/ends.**

**Version 4 allows the user to truncate videos to a pre-specified length**
