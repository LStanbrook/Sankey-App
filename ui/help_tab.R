tabItem(tabName = "help",
              box(markdown("**App deployed here**: [https://louisstanbrook.shinyapps.io/sankey_app/]
                            **Code can be found here**: [https://github.com/L057278/Sankey_App]"),
                width = 12),
              box(h2('Input Data (csv, sas7bdat or xlsx file)'),
                  br(),
                  h3('Required Columns'),
                  br(),
                  HTML('<p>
                          <b>Subject ID</b>: Defaults as <b>USUBJID</b>,it is a unique subject id for each person.<br>
                         <b>Starting Node</b>: Defaults as <b>NODE_S</b>, it is the name of the starting node for the path.<br>
                         <b>Starting Node</b>: Defaults as <b>NODE_E</b>, it is the name of the ending node for the path.<br>
                         <b>Path Number</b>: Defaults as <b>PATHNO</b>, it is the number of the path (starting from 1).<br>
                          Each row is a unique combination of the USUBJID (subject ID) and PATHNO (path number), meaning that it contains information for the link containing a subject at a specific path.
                          Thus, for each unique id, the data should include where it started and where it ended at each timepoint (path no.).
                         </p>'),
                  br(),
                  h3('Optional Columns'),
                  HTML('<p>
                          <b>Path Name</b>: Defaults as <b>PATHNAME</b>, it is an encoding for the names of each path. Preferable format is "{start_timepoint} - {end_timepoint}".<br> 
                          (e.g. for PATHNO 1, PATHNAME is DAY1 - DAY2). For additional functionality, Make sure PATHNAME is correctly mapped to PATHNO.<br>
                         <b>Filters to display</b>: Defaults as <b>FILTERS</b>, it is any kind of filters to be displayed in the dashboard.  <br>
                         </p>'),
                  br(),
                  h3('Upload your data'),
                  HTML('<p>
                          Navigate to the <b>browse</b> button on the <b>input</b> tab and find your data (csv, sas7bdat, or xlsx). 
                          The selection boxes should automatically fill but change the selection if your column names are different. 
                          Also select any of the optional choices here. 
                          Click the green <b>‘Update Graph’</b> button on the sidebar to create the Sankey Diagram, 
                          this is the same whenever you want to update to show your added styles.
                         </p>'),
                  br(),
                  width = 12),
              fluidRow(box(h4('Final Dataset Format'),
                           img(src='data_example.png', height="50%", width="70%")),
                       box(h4('Sankey Output'),
                           img(src='output_example.png',height="50%", width="70%"))),
              fluidRow(box(h2('Information on transforming your data in our format'),
                br(),
                HTML('<p>
                         If your data is in wide format (one row per subject and a column per timepoint) you can use the following template to convert your data in R and prepare them for use.
                         </p>'),
                downloadButton("download_wide",
                              label = "Template"),
                HTML('<p>
                         If your data is in long format (meaning one row per subject per timepoint with each row having a timepoint, node location and subject id column) you can use the following template to convert your data in R and prepare them for use.
                         </p>'),
                downloadButton("download_long",
                              label = "Template"),
                textOutput("keep_alive"),
                width = 12)),
              tags$footer(
                hr(),
                p("Eli Lilly and Company"),
                p("Louis Stanbrook")
                )
              
              
      )
