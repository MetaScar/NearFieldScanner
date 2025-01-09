Code related to or used by Professor Scarborough's Planar Near-Field Scanner. Majority of design and code created by Jacob Stewart. To communicate with a Keysight VNA, the code located in the "instrument" folder was created by Pual Flaten and Joel Johnson. Thank you for the code nerds!

# Quickstart
This quickstart guide is assuming you are trying to run the near-field scanner. There is other code included in this repo that is used for just post processing the data. Hopefully, in a future version of the code, all post processing can be completed within the Matlab app. 

1. Pull the git repo with desired method (using [GitHub Desktop](https://desktop.github.com/download/), the [terminal](https://github.com/git-guides/git-pull), etc.).
2. Go into the `ScannerCode` directory.
3. [Start Matlab][^1].
4. Inside Matlab, go to the directory of the git repo, then to `./ScannerCode`.
5. Inside Matlab, open `moveGUI.mlapp`. This is the Matlab app where the near-field scanner is controlled from.
6. The Matlab App Designer should have opened. Start they app by pressing the green play button up in the top left.
7. 


# Contact
Professor Cody Scarborough: cody.scarborough@colorado.edu

Jacob Stewart: jast5436@colorado.edu

Joel Johnson: jojo1082@colorado.edu

#Footnotes
[^1]: There are two different ways of starting Matlab apps. First, you do it through your file explorer without Matlab already opened. This will immediately open the app. The second is to open the app through Matlab's built in folder directory. In this case, the Matlab App Designer will also open up. This has the advantage of allowing the user to see the code (accessed by pressing "Code View" on the top right of the main window) and to see error messages. Because this code was made by an inept programmer and will likely produce many errors that require Matlab's error codes, it is advised to access the Matlab app through the Matlab App Designer.
