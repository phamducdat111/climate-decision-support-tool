# Climate Decision Support Tool for CO2 Emissions and Policy Scenario Analysis

## Overview
This project is an interactive decision-support tool developed in R Shiny to simulate future CO2 emissions for USA and Russia under different policy scenarios.

## Why this project matters
Climate decision-making requires understanding how emissions evolve under different socio-economic and policy scenarios. This tool provides an accessible way to explore these dynamics and support evidence-based planning.

## Key Insights
- Emissions trajectories vary significantly under different policy pathways;
- Decarbonization plays a critical role in reducing long-term emissions;
- Socio-economic drivers (GDP, population, energy use) strongly influence emission trends.

## Data Sources
The project uses publicly available datasets:
- CO2 emissions data
- World Bank socio-economic data (GDP, population, energy use)

## Key Features
- Scenario-based modelling (Net Zero, Current Policy, High Emission)
- Integration of socio-economic drivers (GDP, population, energy use)
- CO2 emissions forecasting from 2020 to 2050
- Interactive visualization for policy analysis

## Methodology
- Applied linear regression model to estimate CO2 emissions
- Scenario simulation based on different growth assumptions
- Decarbonization factors with 1% reduce per year applied over time due to new technologies, new policies

## Packages Used
- R (dplyr, ggplot2)
- R Shiny
- Data visualization

## Live Demo on R Shiny
https://phamducdat.shinyapps.io/project1/

## Use Case
This tool supports climate policy analysis and decision-making by allowing users to explore different emission pathways.
