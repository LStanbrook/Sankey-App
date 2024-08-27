tabItem(tabName = "dashboard",
              fluidRow(column(6,h3(htmlOutput("days"), align = "left", id ='timepoint_extract')),
                       column(6,tags$button(tags$span(h3("Number of Subjects", align="right"),
                                                      h2(htmlOutput("no_of_patients"), align="center"), style = "color:red"),
                                            type="button", style = "float:right",width="50%"))),
              sankeyNetworkOutput("SankeyPlot", width = "120%", height = "800px")%>% withSpinner(color="#0dc5c1"),      
        
              br(),
              br(),
              br(),
              br(),
              br(),
              div(id = 'prompt_explanation'),
              fluidRow(
                column(6,
                  box(DT::dataTableOutput("LinkSizeTable"),
                    title = "Link Table",
                    collapsible = TRUE,
                    collapsed =   TRUE,
                    width = 12
                    )
                  ),
                column(6,
                  box(DT::dataTableOutput("NodeSizeTable"),
                    title = "Node Table",
                    collapsible = TRUE,
                    collapsed =   TRUE,
                    width = 12
                    )
                  )
                ),
              br(),
              br(),
              br(),
              br(),
              br(),
              br(),
              br(),
              hr(),
              fluidRow(column(6,highchartOutput("BarS")),
                       column(6,highchartOutput("BarE"))),
              tags$footer(
                hr(),
                p("Eli Lilly and Company"),
                p("Louis Stanbrook")
                )
      )
