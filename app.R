
#install packages & load library 
#install.packages("rnaturalearth")
#install.packages("rnaturalearthhires", repos = "https://ropensci.r-universe.dev")
#install.packages("sf")
#install.packages("shinyWidgets")

library(shiny)
library(tidyverse)
library(plotly)
library(treemapify)
library(leaflet)
library(shinyWidgets)
library(sf)
library(rnaturalearth)
library(dplyr)
library(shinycssloaders)


# Load cleaned data
visa_data <- read.csv("net_migration_cleaned.csv")
cob_data <- read.csv("cob_top10_cleaned.csv")

# UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body, html {
        height: 100%;
        margin: 0;
        overflow: auto;
      }
      .dashboard-container {
        display: flex;
        flex-direction: column;
        height: 100vh;
      }
      .top-header {
        background-color: white;
        z-index: 1002;
        padding: 10px 20px;
        border-bottom: 1px solid #ccc;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
      }
      .content-area {
        display: flex;
        flex: 1;
        margin-top: 140px; 
        overflow: hidden;
      }
      .sidebar {
        width: 320px;
        background-color: #f9f9f9;
        padding: 20px;
        border-right: 1px solid #ccc;
        overflow-y: auto;
      }
      .main-content {
        flex: 1;
        padding: 50px 20px 20px 20px; 
        overflow-y: auto;
      }
      #tabs-container .tab-content > .tab-pane {
        transition: opacity 0.5s ease-in-out;
      }
      #tabs-container .tab-content > .tab-pane:not(.active) {
        opacity: 0;
      }
    "))
  ),
  
  div(class = "dashboard-container",
      div(class = "top-header",
          h2("Migration in Motion"),
          h6("Note: Charts may take a few seconds to load. Please be patient or switch tabs after data is fully loaded."),
          div(id = "tabs-container",
              tabsetPanel(id = "tabs",
                          tabPanel("User Guide",
                                   div(style = "max-height: calc(100vh - 160px); overflow-y: auto; padding-right: 10px;",
                                       
                                   h3("Welcome to Migration in Motion!"),
                                   h4("About this Project:"),
                                   p("This dashboard visualises Australia's migration trends between 2014 and 2023."),
                                   p("It provides both a high-level national overview and in-depth, state-specific analyses across multiple migration indicators, including visa type composition and country-of-origin insights."),
                                   h4("How to Use This Dashboard:"),
                                   h5("Tab 1: National Trend"),
                                   p("This tab helps users understand temporal migration patterns at both national and state levels. Begin by adjusting the Year Range Slider to your period of interest (default is 2014–2023). Use the State Filter to choose between a national view or zoom in on an individual state. Select a Migration Flow Type (Arrival, Departure, Net Migration) to drill deeper into the specific components that shape that flow. This can also be done interactively by clicking directly on the line graph."),
                                   p("After selecting a flow, two charts will appear:"),
                                   tags$ul(
                                     tags$li("A PR Stream Breakdown Stacked Area Chart to reveal stream dominance."),
                                     tags$li("A Temporary Visa Composition Line Chart to visualise trends by category.")
                                   ),
                                   h5("Tab 2: State Comparison"),
                                   p("This tab lets users explore how migration patterns vary across states. Start by selecting a specific year from the dropdown to display net migration on a choropleth map where all states are shaded by net migration volumne. Hovering over a state show detailed migration figures in a tooltip. Click on a state to reveal the drill down of:"),
                                   tags$ul(
                                     tags$li("A bar chart illustrating the net migration breakdown across four visa categories: Permanent Resident (PR), Temporary, Australian Citizens, and New Zealand Citizens."),
                                     tags$li("A treemap highlighting the origin of migrants showing the top 10 countries of birth for that state, with each tile sized by population share.")
                                   ),
                                   h4("Data Sources:"),
                                   p("\u2022 Overseas migrant arrivals and departures, Australian Bureau of Statistic (2024). Available at: ", a(href = "https://www.abs.gov.au/statistics/people/population/overseas-migration/latest-release", "31010do004_202324-overseas-migration.abs.gov.au", target = "_blank")),
                                   p("\u2022 National, state and territory population, Australian Bureau of Statistic (2024). Available at: ", a(href = "https://www.abs.gov.au/statistics/people/population/overseas-migration/latest-release", "31010do001_202324-overseas-migration.abs.gov.au", target = "_blank")),
                                   p("\u2022 Shapefile: ABS ASGS Edition 3 - States and Territories 2021 boundaries. Download from: ", a(href = "https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files", "ABS Digital Boundary Files", target = "_blank"))
                          )),
                          tabPanel("National Trend"),
                          tabPanel("State Comparison")
              )
          )
      ),
      
      # Main layout
      div(class = "content-area",
          # Sidebar
          div(class = "sidebar",
              conditionalPanel(
                condition = "input.tabs == 'National Trend'",
                uiOutput("sidebar_text_national1"),
                sliderInput("year", "Select Year Range:",
                            min = min(visa_data$Year), max = max(visa_data$Year),
                            value = c(2014, 2023), sep = "", step = 1),
                selectInput("state", "Select State/AUS for nation wide:",
                            choices = unique(visa_data$State), selected = "AUS"),
                selectInput("line_choice", "Select migration flow to drill down:",
                            choices = c("Arrival", "Departure", "Net Migration"),
                            selected = NULL),
                uiOutput("sidebar_text_national2")
              ),
              conditionalPanel(
                condition = "input.tabs == 'State Comparison'",
                uiOutput("sidebar_text_state1"),
                selectInput("map_year", "Select a Year:",
                            choices = as.character(min(visa_data$Year):max(visa_data$Year)),
                            selected = "2023"),
                selectInput("selected_state", "Select a State to deepdive:",
                            choices = unique(visa_data$State[visa_data$State != "AUS"]),
                            selected = NULL),
                uiOutput("sidebar_text_state2")
              )
          ),
          
          # Main content
          div(class = "main-content",
              conditionalPanel(
                condition = "input.tabs == 'National Trend'",
                shinycssloaders::withSpinner(plotlyOutput("national_trend"), type = 3, color = "#2c3e50", color.background = "#ffffff"),
                div(style = "margin-top: 30px;",
                    shinycssloaders::withSpinner(uiOutput("pr_stack_area"), type = 3, color = "#2c3e50", color.background = "#ffffff")),
                div(style = "margin-top: 35px;",
                    shinycssloaders::withSpinner(uiOutput("temp_stack_line"), type = 3, color = "#2c3e50", color.background = "#ffffff"))
              ),
              conditionalPanel(
                condition = "input.tabs == 'State Comparison'",
                shinycssloaders::withSpinner(leafletOutput("map"), type = 3, color = "#2c3e50", color.background = "#ffffff"),
                div(style = "margin-top: 20px;",
                    shinycssloaders::withSpinner(plotlyOutput("visa_bar"), type = 3, color = "#2c3e50", color.background = "#ffffff")),
                div(style = "margin-top: 20px;",
                    shinycssloaders::withSpinner(plotlyOutput("cob_treemap"), type = 3, color = "#2c3e50", color.background = "#ffffff"))
              )
          )
      )
  )
)





# Server
server <- function(input, output, session) {
  
  # UI notes markdown output
  output$sidebar_text_national1 <- renderUI({
    HTML("
        <p><strong>National Trend: </strong> Use the Year Range and State filters to explore migration inflows, outflows and net changes. Select flow to reveal further visa type breakdowns.</p>
         ")
  })
  
  output$sidebar_text_national2 <- renderUI({
    HTML("
        <p>These views help highlight major changes like the sharp decline during COVID-19 (2019–2021) and the rebound from late 2021 driven by student arrivals.</p>
         ")
  })
  
  output$sidebar_text_state1 <- renderUI({
    HTML("
        <p><strong>State Comparison: </strong> View state-level net migration, visa composition, and top countries of origin.</p>
         ")
  })
  
  output$sidebar_text_state2 <- renderUI({
    HTML("
        <p>These views reveal that NSW and VIC consistently attract most migratns, while QLD has overtaken WA as the 3rd most popular state for migrants since 2021. You may observe that India and China are top source countries across multiple states, while smaller contributions from countries like Nepal or UK offer cluers about regional diversity.</p>
         ")
  })
  
  
  # Reactive: Filtered visa data by year and state
  filtered_visa <- reactive({
    visa_data %>%
      filter(Year >= input$year[1],
             Year <= input$year[2],
             State == input$state)
  })
  
  #aggregate yearly total
  summary_by_year <- reactive({
    filtered_visa() %>%
      filter(Visa_Stream %in% c("Total", "AUS_Citizen", "NZ_Citizen")) %>%
      group_by(Year) %>%
      summarise(
        PR_Arr = sum(Arrival[Visa_Type == "PR" & Visa_Stream == "Total"]),
        Temporary_Arr = sum(Arrival[Visa_Type == "Temporary" & Visa_Stream == "Total"]),
        AUS_Citizen_Arr = sum(Arrival[Visa_Type == "AUS_Citizen" & Visa_Stream == "AUS_Citizen"]),
        NZ_Citizen_Arr = sum(Arrival[Visa_Type == "NZ_Citizen" & Visa_Stream == "NZ_Citizen"]),
        PR_Dep = sum(Departure[Visa_Type == "PR" & Visa_Stream == "Total"]),
        Temporary_Dep = sum(Departure[Visa_Type == "Temporary" & Visa_Stream == "Total"]),
        AUS_Citizen_Dep = sum(Departure[Visa_Type == "AUS_Citizen" & Visa_Stream == "AUS_Citizen"]),
        NZ_Citizen_Dep = sum(Departure[Visa_Type == "NZ_Citizen" & Visa_Stream == "NZ_Citizen"]),
        PR_Net = PR_Arr - PR_Dep,
        Temporary_Net = Temporary_Arr - Temporary_Dep,
        AUS_Citizen_Net = AUS_Citizen_Arr - AUS_Citizen_Dep,
        NZ_Citizen_Net = NZ_Citizen_Arr - NZ_Citizen_Dep,
        Arrival = PR_Arr + Temporary_Arr + AUS_Citizen_Arr + NZ_Citizen_Arr,
        Departure = PR_Dep + Temporary_Dep + AUS_Citizen_Dep + NZ_Citizen_Dep,
        Net = PR_Net + Temporary_Net + AUS_Citizen_Net + NZ_Citizen_Net
      ) %>%
      mutate(
        text_arr = paste0("Arrival: ", scales::comma(Arrival),
                          "<br>PR: ", scales::comma(PR_Arr),
                          "<br>Temporary: ", scales::comma(Temporary_Arr),
                          "<br>AUS: ", scales::comma(AUS_Citizen_Arr),
                          "<br>NZ: ", scales::comma(NZ_Citizen_Arr)),
        text_dep = paste0("Departure: ", scales::comma(Departure),
                          "<br>PR: ", scales::comma(PR_Dep),
                          "<br>Temporary: ", scales::comma(Temporary_Dep),
                          "<br>AUS: ", scales::comma(AUS_Citizen_Dep),
                          "<br>NZ: ", scales::comma(NZ_Citizen_Dep)),
        text_net = paste0("Net Migration: ", scales::comma(Net),
                          "<br>PR: ", scales::comma(PR_Net),
                          "<br>Temporary: ", scales::comma(Temporary_Net),
                          "<br>AUS: ", scales::comma(AUS_Citizen_Net),
                          "<br>NZ: ", scales::comma(NZ_Citizen_Net))
      )
  })
  
  # Output: Main line chart of total migration trends
  output$national_trend <- renderPlotly({
    plot_ly(summary_by_year(), x = ~Year, source ="main_plot") %>%
      add_trace(y = ~Arrival, name = "Arrival", type = 'scatter', mode = 'lines+markers',
                line = list(color = "#2ca02c"),
                marker = list(color = "#2ca02c"),
                text = ~text_arr, hoverinfo = 'text') %>%
      add_trace(y = ~Departure, name = "Departure", type = 'scatter', mode = 'lines+markers',
                line = list(color = "#d62728"),
                marker = list(color = "#d62728"),
                text = ~text_dep, hoverinfo = 'text') %>%
      add_trace(y = ~Net, name = "Net Migration", type = 'scatter', mode = 'lines+markers',
                line = list(color = "#1f77b4"),
                marker = list(color = "#1f77b4"),
                text = ~text_net, hoverinfo = 'text') %>%
      layout(
        title = paste0("<b>", input$state, " Overall Yearly Migration Trend (", input$year[1], "-", input$year[2], ")</b>"),
        yaxis = list(title = "Count"),
        xaxis = list(title = "Year", tickmode = "linear", dtick = 1,range = c(input$year[1], input$year[2])),
        legend = list(title = list(text = "<b>Migration Flow</b>")),  
        #add overlay for covid-19 impacted period
        shapes = list(
          list(
            type = "rect",
            x0 = 2019, x1 = 2021,
            y0 = 0, y1 = 1,
            yref = "paper",
            fillcolor = "rgba(255, 0, 0, 0.1)",
            line = list(width = 0)
          )
        ),
        annotations = list(
          list(
            x = 2020,
            y = 0.90,
            xref = "x",
            yref = "paper",
            text = "COVID-19 \n Impact Period",
            showarrow = FALSE,
            font = list(size = 12)
          )
        )
      )
  })
  # Sync dropdown with click and vice versa
  selected_line <- reactiveVal(NULL)
  
  observeEvent(input$line_choice, {
    if (!is.null(input$line_choice) && input$line_choice != "") {
      selected_line(input$line_choice)
    }
  })
  
  observeEvent(event_data("plotly_click", source = "main_plot"), {
    curve <- event_data("plotly_click", source = "main_plot")$curveNumber
    if (!is.null(curve)) {
      line_name <- c("Arrival", "Departure", "Net Migration")[curve + 1]
      selected_line(line_name)
      updateSelectInput(session, "line_choice", selected = line_name)
    }
  })
  
  
  #drill down to reveal secondary charts
  # Filter PR and Temporary by selected line type
  filtered_drill_data <- reactive({
    req(selected_line())
    filtered_visa() %>% filter(Visa_Type %in% c("PR", "Temporary"))
  })
  
  output$pr_stack_area <- renderUI({
    req(selected_line())
    plotlyOutput("pr_chart")
  })
  
  output$temp_stack_line <- renderUI({
    req(selected_line())
    plotlyOutput("temp_chart")
  })
  
  output$pr_chart <- renderPlotly({
    req(selected_line())
    yvar <- switch(selected_line(),
                   "Arrival" = "Arrival",
                   "Departure" = "Departure",
                   "Net Migration" = "Net")
    filtered_drill_data() %>%
      filter(Visa_Type == "PR") %>%
      plot_ly(x = ~Year, y = as.formula(paste0("~",yvar)) , color = ~Visa_Stream,
              type = 'scatter', mode = 'none', fill = 'tonexty') %>%
      layout(
        title = paste0("<b>", input$state, " ", selected_line(), " PR Stream Breakdown ", input$year[1], "-", input$year[2], "</b>"),
        yaxis = list(title = paste0(selected_line(), " Count")),
        legend = list(title = list(text = "<b>Visa Stream Type</b>"))
      )
  })
  
  output$temp_chart <- renderPlotly({
    req(selected_line())
    yvar <- switch(selected_line(),
                   "Arrival" = "Arrival",
                   "Departure" = "Departure",
                   "Net Migration" = "Net")
    filtered_drill_data() %>%
      filter(Visa_Type == "Temporary") %>%
      plot_ly(x = ~Year, y = as.formula(paste0("~", yvar)), color = ~Visa_Stream,
              type = 'scatter', mode = 'lines') %>%
      layout(title = paste0("<b>", input$state, " ", selected_line(), " Temporary Visa Breakdown ", input$year[1], "-", input$year[2], "</b>"),
             legend = list(title = list(text = "<b>Visa Stream Type</b>"))
      )
  })
  
  
  # Load and cache shapefile  
  australia_states_shapefile <- st_read("STE_2021_AUST_GDA2020.shp") %>%
    st_make_valid() %>%                           # Ensure all geometries are valid
    st_transform(crs = 4326)                      # standardize CRS to WGS84 (used by Leaflet)
  #this shape is extracted from  States and Territories-2021-Shapefile,ABS https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files
  
  # Filter only polygons and drop problematic geometries
  australia_states_shapefile <- australia_states_shapefile[st_geometry_type(australia_states_shapefile) %in% c("POLYGON", "MULTIPOLYGON"), ]
  
  # Create state name mapping
  state_name_map <- c(
    "New South Wales" = "NSW",
    "Victoria" = "VIC",
    "Queensland" = "QLD",
    "South Australia" = "SA",
    "Western Australia" = "WA",
    "Tasmania" = "TAS",
    "Northern Territory" = "NT",
    "Australian Capital Territory" = "ACT"
  )
  australia_states_shapefile$State <- state_name_map[australia_states_shapefile$STE_NAME21]
  
  # Reactive data: state-level data for selected year
  map_data <- reactive({
    visa_data %>%
      filter(Year == as.numeric(input$map_year),
             Visa_Stream %in% c("Total", "AUS_Citizen", "NZ_Citizen"),
             State != "AUS") %>%
      group_by(State) %>%
      summarise(
        PR_Net = sum(Arrival[Visa_Type == "PR" & Visa_Stream == "Total"] -
                       Departure[Visa_Type == "PR" & Visa_Stream == "Total"]),
        Temporary_Net = sum(Arrival[Visa_Type == "Temporary" & Visa_Stream == "Total"] -
                              Departure[Visa_Type == "Temporary" & Visa_Stream == "Total"]),
        AUS_Citizen_Net = sum(Arrival[Visa_Type == "AUS_Citizen" & Visa_Stream == "AUS_Citizen"] -
                                Departure[Visa_Type == "AUS_Citizen" & Visa_Stream == "AUS_Citizen"]),
        NZ_Citizen_Net = sum(Arrival[Visa_Type == "NZ_Citizen" & Visa_Stream == "NZ_Citizen"] -
                               Departure[Visa_Type == "NZ_Citizen" & Visa_Stream == "NZ_Citizen"]),
        Net = PR_Net + Temporary_Net + AUS_Citizen_Net + NZ_Citizen_Net
      )
  })
  
  # Use observeEvent to trigger heavy processing only on tab switch
  observeEvent(input$tabs, {
    if (input$tabs == "State Comparison") {
      map_data()
    }
  })
  
  # Render interactive choropleth map
  output$map <- renderLeaflet({
    merged_data <- left_join(australia_states_shapefile, map_data(), by = "State") %>%
      filter(!is.na(Net))
    
    #colout palette 
    pal <- colorNumeric(palette = c("#d7191c", "#fdae61", "#ffffbf", "#a6d96a", "#1a9641"), domain = range(merged_data$Net, na.rm = TRUE))
    
    centroids <- suppressWarnings(
      merged_data %>%
        group_by(State) %>%
        summarise(geometry = st_union(geometry), .groups = "drop") %>%
        st_centroid()
    )
    
    total_abs_net <- sum(abs(merged_data$Net), na.rm = TRUE)
    total_net_display <- sum(merged_data$Net, na.rm = TRUE)
    
    leaflet(merged_data) %>%
      addControl(
        htmltools::tags$div(
          style = "font-size:18px;font-weight:bold;padding:5px;",
          paste0("Net Migration Distribution Across Australian States In ", input$map_year)
        ),
        position = "topright"
      ) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addPolygons(
        fillColor = ~pal(Net),
        fillOpacity = 0.7,
        color = "white",
        weight = 1,
        layerId = ~State,
        label = ~lapply(seq_len(nrow(merged_data)), function(i) {
          htmltools::HTML(paste0(
            "<div style='line-height:1.5;'>",
            "<strong>State:</strong> ", merged_data$State[i], "<br>",
            "<strong>Year:</strong> ", input$map_year, "<br>",
            "<strong>Net Migration:</strong> ", scales::comma(merged_data$Net[i] / 1000), "k<br>",
            "<strong>% of AUS:</strong> ", round(abs(merged_data$Net[i]) / total_abs_net * 100, 1), "%",
            "</div>"
          ))
        }),
        highlightOptions = highlightOptions(weight = 2, color = "black", bringToFront = TRUE)
      ) %>%
      addLabelOnlyMarkers(
        data = centroids,
        lng = st_coordinates(centroids)[,1],
        lat = st_coordinates(centroids)[,2],
        label = ~State,
        labelOptions = labelOptions(noHide = TRUE, direction = 'center', textOnly = TRUE,
                                    style = list("font-weight" = "bold", "font-size" = "12px"))
      ) %>%
      addLegend("bottomright", pal = pal, values = merged_data$Net,
                title = paste0("Net Migration Total: ", round(total_net_display / 1000, 1), "k"),
                labFormat = labelFormat(suffix = "k", transform = function(x) round(x / 1000, 1)),
                opacity = 1)
  })
  
  observeEvent(input$map_shape_click, {
    state_clicked <- input$map_shape_click$id
    updateSelectInput(session, "selected_state", selected = state_clicked)
  })
  
  # Compute selected state data for bar chart
  selected_state_data <- reactive({
    req(input$selected_state, input$map_year)
    visa_data %>%
      filter(State == input$selected_state, Year == as.numeric(input$map_year), Visa_Stream %in% c("Total", "AUS_Citizen", "NZ_Citizen")) %>%
      group_by(Visa_Type) %>%
      summarise(Net = sum(Net))
  })
  
  # Render the group stacked bar chart for clicked state
  output$visa_bar <- renderPlotly({
    data <- selected_state_data()
    plot_ly(data, x = ~Visa_Type, y = ~Net, color = ~Visa_Type, type = 'bar') %>%
      layout(title = paste0("<b>", input$selected_state, " Net Migration by Visa Type in ", input$map_year, "</b>"),
             yaxis = list(title = "Net Migration Count"),
             xaxis = list(title = "Visa Type"),
             legend = list(title = list(text = "<b>Visa Type</b>"))
      )
  })
  
  output$cob_treemap <- renderPlotly({
    req(input$selected_state, input$map_year)
    
    df <- cob_data %>%
      filter(State == input$selected_state, Year == as.numeric(input$map_year)) %>%
      arrange(desc(Count)) %>%
      slice_head(n = 10) %>%
      mutate(share_label = paste0(round(share, 1), "%"),
             label = paste0("Country: ", country_of_birth,
                            "<br>Count: ", scales::comma(Count),
                            "<br>% of Total: ", share_label))
    
    plot_ly(
      type = "treemap",
      labels = df$country_of_birth,
      parents = rep("", nrow(df)),
      values = df$Count,
      textinfo = "label+value+percent entry",
      hoverinfo = "text",
      text = df$label
    ) %>%
      layout(title = paste0("<b>", input$selected_state, " Top 10 Migrant Origin (by Country of Birth) in ", input$map_year, "</b>"))
  })
  
}
# Run the app
shinyApp(ui, server)