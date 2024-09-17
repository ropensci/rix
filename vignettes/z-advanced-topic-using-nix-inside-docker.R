## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----include=FALSE------------------------------------------------------------
library(rix)

## ----eval = FALSE-------------------------------------------------------------
#  library(rix)
#  
#  rix(
#    r_ver = "4.3.1",
#    r_pkgs = c("dplyr", "ggplot2"),
#    ide = "other",
#    project_path = ".",
#    shell_hook = "R",
#    overwrite = TRUE
#  )

## ----eval = FALSE-------------------------------------------------------------
#  library(rix)
#  
#  rix(
#    r_ver = "4.2.2",
#    r_pkgs = "shiny",
#    ide = "other",
#    project_path = ".",
#    overwrite = TRUE
#  )

## ----eval = FALSE-------------------------------------------------------------
#  # k-means only works with numerical variables,
#  # so don't give the user the option to select
#  # a categorical variable
#  vars <- setdiff(names(iris), "Species")
#  
#  pageWithSidebar(
#    headerPanel("Iris k-means clustering"),
#    sidebarPanel(
#      selectInput("xcol", "X Variable", vars),
#      selectInput("ycol", "Y Variable", vars, selected = vars[[2]]),
#      numericInput("clusters", "Cluster count", 3, min = 1, max = 9)
#    ),
#    mainPanel(
#      plotOutput("plot1")
#    )
#  )

## ----eval = FALSE-------------------------------------------------------------
#  function(input, output, session) {
#    # Combine the selected variables into a new data frame
#    selectedData <- reactive({
#      iris[, c(input$xcol, input$ycol)]
#    })
#  
#    clusters <- reactive({
#      kmeans(selectedData(), input$clusters)
#    })
#  
#    output$plot1 <- renderPlot({
#      palette(c(
#        "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
#        "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"
#      ))
#  
#      par(mar = c(5.1, 4.1, 0, 1))
#      plot(selectedData(),
#        col = clusters()$cluster,
#        pch = 20, cex = 3
#      )
#      points(clusters()$centers, pch = 4, cex = 4, lwd = 4)
#    })
#  }

