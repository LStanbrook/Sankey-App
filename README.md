
	## There are 3 ways to launch this app:

	1: Navigate to the following website: https://louisstanbrook.shinyapps.io/sankey_app/

	2: Run from the GitHub Repository, using the following code in RStudio:
	install.packages('shiny')
	library(shiny)
	shiny::runGitHub('L057278/Sankey_App', ref = 'main')

	3: Run locally, downloaded from the GitHub Repository:
	Navigate to the GitHub Repository: https://github.com/L057278/Sankey_App
	Click on the green ‘Code’ button and click ‘Download ZIP’
	Once it has downloaded, extract the folder to somewhere useful in your files e.g. your section of the EW_STATS drive.
	Run the following code. Be careful about your file directory link as the syntax is quite unforgiving and it also changes for different versions. This will be a link to your app folder (Sankey_App unless you called it something different):
	install.packages(‘shiny’)
	library(shiny)
	shiny::runApp("[YOUR DIRECTORY LINK]")

  
	## Instructions for use:
  
  	Data(csv, excel or sas7bdat) need to be in the following format:
  	
	Required Columns:
	Subject ID: Defaults as USUBJID, it is a unique subject id for each person.
	Starting Node: Defaults as NODE_S, it is the name of the starting node for the path.
	Ending Node: Defaults as NODE_E, it is the name of the ending node for the path.
	Path Number: Defaults as PATHNO, it is the number of the path (starting from 1).
  
	Optional Columns:
	Path Name: Defaults as PATHNAME, it is an encoding for the names of each path. Preferable format is "{start_timepoint} - {end_timepoint}". (e.g. for PATHNO 1, PATHNAME is DAY1 - DAY2). For additional functionality, Make sure PATHNAME is correctly mapped to PATHNO.
	Filters to display: Defaults as FILTERS, it is any kind of filters to be displayed in the dashboard. 

  
	Each row is a unique combination of the USUBJID (subject ID) and PATHNO (path number), meaning that it contains information for the link containing a subject at a specific path.
	Thus, for each unique id, the data should include where it started and where it ended at each timepoint (path no.).

  
