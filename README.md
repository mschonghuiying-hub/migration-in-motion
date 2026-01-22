## Migration in Motion

### Interactive migration intelligence for Australia (2014–2023)

🔗 Live demo: https://mschonghuiying.shinyapps.io/migration-in-motion/

## Overview

Migration in Motion is an interactive R Shiny dashboard designed to help analysts, policymakers, and strategy teams explore how Australian migration patterns evolved before, during, and after COVID-19. Rather than static tables, the app enables overview → drill-down → comparison across time, visa type, state, and country of birth—supporting exploratory analysis and decision-oriented insights.

## What problem this solves
Australian migration data is:
- multi-dimensional (time × visa × geography × origin),
- fragmented across tables, and
- difficult for non-technical users to explore interactively.

This dashboard translates complex ABS migration data into a decision-grade exploratory tool, allowing users to quickly identify:
- structural breaks (e.g. COVID-era shocks),
- changes in visa composition,
- state-level divergence and recovery patterns.

## Decisions this supports
- Understand how migration shocks impact state-level labour supply
- Compare reliance on temporary vs permanent visa streams by state
- Identify structural vs cyclical changes post-COVID

## Key features
- National migration trends: Interactive time series of arrivals, departures, and net migration (2014–2023), highlighting COVID disruption and recovery.
- Visa composition drill-down: Stacked and line views separating permanent vs temporary visa streams and sub-categories.
- State-level comparison: Choropleth map of net migration by state/territory with click-to-filter interactions.
- Country of birth analysis: Dynamic treemap showing top source countries by state, enabling geographic and demographic comparison.
- Linked interactions: Selecting a year or state updates all relevant charts simultaneously for fast exploration.

## Insights
- Net overseas migration turned sharply negative during COVID, with uneven recovery across states.
- Temporary visa streams were more volatile than permanent migration.
- NSW and VIC experienced larger swings compared to relatively resilient states such as QLD.
- Country-of-birth composition varies materially by state, reflecting different economic and labour profiles.
(Insights are exploratory, not causal.)

## Tech stack
- R Shiny – application framework
- Plotly – interactive charts
- Leaflet + sf – spatial visualisation
- tidyverse – data manipulation
- shinycssloaders – UI feedback

## Data sources
Australian Bureau of Statistics (ABS):
- Overseas migration statistics
- State/Territory boundary files (2021, GDA2020)

All data is aggregated and used for analytical demonstration purposes.

## How to run locally
1. Clone the repository
git clone https://mschonghuiying.shinyapps.io/migration-in-motion/ 

2. Open the project in RStudio and Restore dependencies (if using renv)
renv::restore()

3. Run the app
shiny::runApp()


## Limitations
- Data is aggregated; individual migrant outcomes are not observable.
- Performance may degrade with very large spatial or temporal extensions.
- Visual exploration supports hypothesis generation, not causal inference.

## Potential extensions
- Annotate timelines with policy changes and border controls
- Add caching/pre-aggregation for scalability
- Extend to migrant outcomes (employment, income, housing stress)
- Enable data export for downstream analysis
