Code related to or used by Professor Scarborough's Planar Near-Field Scanner. Majority of design and code created by Jacob Stewart. To communicate with a Keysight VNA, the code located in the "instrument" folder was created by Pual Flaten and Joel Johnson. Thank you for the code nerds!

# Quickstart
This quickstart guide is assuming you are trying to run the near-field scanner. This quickstart guide also assumes the user has arranged the antenna the user is testing (the AUT), and that the desired probe is installed. There is other code included in this repo that is used for just post processing the data located in the `./PostProcessing` directory. Hopefully, in a future version of the code, all post processing can be completed within the Matlab app. 

Because this guide is not exhaustive and perfect, if you think something is stupid/dangerous and you disagree with this guide, use your judgement. For example, if this guide does not tell you to wear an ESD strap while handling the VNA, but you think you should, use an ESD strap.

1. If you have not already, pull the git repo with desired method (using [GitHub Desktop](https://desktop.github.com/download/), the [terminal](https://github.com/git-guides/git-pull), etc.).
2. Start Matlab[^1], and turn on the VNA.
3. Inside Matlab, go to the directory of the git repo, then to `./ScannerCode`.
4. Inside Matlab, open `moveGUI.mlapp`. This is the Matlab app where the near-field scanner is controlled from.
5. The Matlab App Designer should have opened. Start the app by pressing the green play button up in the top left.
6. The app should be started. Now, plug in the Arduino Uno USB into the computer running the Matlab app and the <insert power block> into an outlet. If either does not seem to recieve power after plugging in, ensure the Arduino USB is connected to the USB-B port on the Arduino, and that the barrel connector is plugged into the PCB.
7. If you have not already, clear the space in and around the near-field scanner. It is about to start moving, so you don't want it to run into anything. Also, it is advised to unplug the probe and the AUT from the VNA, as future steps might cause electrical connections between the ports. Feel free to maintain the connection between the cable and the AUT/probe.
8. In the App, press the "Initialize" button in the top right. This will begin homing the machine.
9. Once the homing is completed and you have confirmed the completion, if this is the first time testing with the AUT positioned as it is now, you will need to run "Determine Z Dist" and "Find Probe Center". These will tell the program where the AUT is. If this has already been completed for the current setup, skip to step 12.
10. Click "Determine Z Dist". Follow the program, and use the controls to put the probe close to the AUT, and use a caliper to measure the physical distance between the probe and AUT. Write down the value provided by the program.
<insert image>
11. At the completion of "Determine Z Dist", you will be prompted to run "Find Probe Center". Go for it. Using the same controls, position the probe as close as possible to the center of the AUT. Write down the values provided by the program.
12. If you want the program to calculate the sampling criteria for a measurement, select "Determine Criteria". If you already have the criteria, skip this step.
13. Once you are ready to begin measuring, plug in the probe and AUT to the VNA.
14. Click "Run Measurement". The program will prompt you for anything it is missing, move to the center for one final check, then begin measuring.
15. At the completion of the measurements, you will be prompted to make a struct. This is advised, as variables such as the distance will be saved into the struct, which can be used later if you forgot how far the AUT was from the probe.
16. Once the measurement is complete, the data will be output to the `./ScannerCode/Data/` directory. Save this as preferred (e.g. USB drive, OneDrive, etc.).
17. Feel free to use the "Raw to Gated" program in the bottom right of the app to time gate your raw data, and "Raw to Struct" to turn the gated data into structs which can be used for plotting with the app's "Struct to Plots" program and transforming into the far field using the program `./PostProcessing/SimpleFarFieldTransform.m`.

# Data
It is not best practice to put your raw data files inside of git. Git is for tracking changes in text files. Instead, data files for the GitHub repo will be located in the [Microsoft Teams's `Files/Near Field Scanner/GitHubData` folder](https://o365coloradoedu.sharepoint.com/:f:/r/sites/ECEE-EMRG/Shared%20Documents/General/Near%20Field%20Scanner/GitHubData?csf=1&web=1&e=mdIfOC).
Folders named "Data" will be included in the git repo for the convenience of the user to put their own data. If there is data available in the Teams folder, it will be located in the same directory.
For example, the "Data" folder located at `./ScannerCode/Data/` is located at `/Near Field Scanner/GitHubData/ScannerCode` directory on Teams.

# Contact
Professor Cody Scarborough: cody.scarborough@colorado.edu

Jacob Stewart: jast5436@colorado.edu

Joel Johnson: jojo1082@colorado.edu

# Footnotes
[^1]: There are two different ways of starting Matlab apps. First, you do it through your file explorer without Matlab already opened. This will immediately open the app. The second is to open the app through Matlab's built in folder directory. In this case, the Matlab App Designer will also open up. This has the advantage of allowing the user to see the code (accessed by pressing "Code View" on the top right of the main window) and to see error messages. Because this code was made by an inept programmer and will likely produce many errors that require Matlab's error codes, it is advised to access the Matlab app through the Matlab App Designer.
