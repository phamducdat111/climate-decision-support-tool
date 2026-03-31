library(dplyr)
library(ggplot2)
library(shinythemes)
library(shiny)


# Data từ file
co2_data <- read.csv("Ru&Us_ghg_data.csv")

co2_data <- co2_data %>%
  rename(
    country = Country,
    year = Year,
    CO2 = co2_data
  )

# data WB

wb_data <- read.csv("wb_data.csv")

# Chuẩn hóa country name
wb_data$country <- recode(wb_data$country,
                          "United States" = "USA",
                          "Russian Federation" = "RUS")

# Select + rename (thực ra không cần rename nữa)
wb_data <- wb_data %>%
  select(country, year, GDP, population, energy_use)


# merge data

df <- co2_data %>%
  inner_join(wb_data, by = c("country", "year")) %>%
  arrange(country, year)


# build model

model <- lm(CO2 ~ GDP + population + energy_use, data = df)

df$pred <- predict(model, df)

# ==============================
# VISUALIZATION (Actual vs Predicted)
# ==============================

library(ggplot2)

# Actual vs Predicted
ggplot(df, aes(x = year)) +
  geom_line(aes(y = CO2, color = "Actual")) +
  geom_line(aes(y = pred, color = "Predicted")) +
  facet_wrap(~country) +
  labs(title = "Actual vs Predicted CO2 Emissions")

#FORECAST DATA (2021–2050)

library(dplyr)

# Lấy giá trị cuối cùng (2020)
last_data <- df %>%
  group_by(country) %>%
  filter(year == max(year)) %>%
  ungroup()

# Tạo future years
future_years <- 2021:2050

generate_future <- function(data, gdp_growth, pop_growth, energy_growth) {
  
  future_list <- list()
  
  for (i in 1:nrow(data)) {
    
    country_data <- data[i, ]
    
    GDP <- as.numeric(country_data$GDP)
    population <- as.numeric(country_data$population)
    energy_use <- as.numeric(country_data$energy_use)
    country <- as.character(country_data$country)
    
    temp <- data.frame()
    
    for (year in 2021:2050) {
      
      GDP <- GDP * (1 + gdp_growth)
      population <- population * (1 + pop_growth)
      energy_use <- energy_use * (1 + energy_growth)
      
      temp <- rbind(temp, data.frame(
        country = country_data$country,
        year = year,
        GDP = GDP,
        population = population,
        energy_use = energy_use
      ))
    }
    
    future_list[[i]] <- temp
  }
  
  bind_rows(future_list)
}


#SCENARIO ANALYSIS

low$scenario <- "Net Zero"
medium$scenario <- "Current Policy"
high$scenario <- "High Emission"

# Combine all
future_all <- bind_rows(low, medium, high)

#predict CO2
future_all$pred <- predict(model, future_all)

future_all$pred <- future_all$pred *
  case_when(
    future_all$scenario == "Net Zero" ~ (1 - 0.02 * (future_all$year - 2020)),
    future_all$scenario == "Current Policy" ~ (1 - 0.01 * (future_all$year - 2020)),
    future_all$scenario == "High Emission" ~ (1 - 0.005 * (future_all$year - 2020))
  )


#VISUALIZE FORECAST
ggplot(future_all, aes(x = year, y = pred, color = scenario)) +
  geom_line() +
  facet_wrap(~country) +
  labs(title = "CO2 Forecast under Different Scenarios")

#COMBINE HISTORICAL + FUTURE
df$scenario <- "Historical"

combined <- bind_rows(
  df %>% select(country, year, pred, scenario),
  future_all %>% select(country, year, pred, scenario)
)

ggplot(combined, aes(x = year, y = pred, color = scenario)) +
  geom_line() +
  facet_wrap(~country) +
  labs(title = "CO2 Emissions: Historical and Forecast")


#giao diện người dùng
ui <- fluidPage(
  theme = shinytheme("flatly"),  # Chọn theme Flatly cho app nhìn chuyên nghiệp
  
  titlePanel("CO2 Emissions Decision Tool"),  # Tiêu đề chính
  
  sidebarLayout(
    sidebarPanel(
      # Slider để người dùng nhập tốc độ tăng trưởng GDP (%)
      sliderInput("gdp_growth", "GDP Growth (%)", min = 0, max = 5, value = 2, step = 0.1),
      
      # Slider để nhập tốc độ tăng trưởng dân số (%)
      sliderInput("pop_growth", "Population Growth (%)", min = 0, max = 2, value = 1, step = 0.1),
      
      # Slider để nhập tốc độ tăng trưởng sử dụng năng lượng (%)
      sliderInput("energy_growth", "Energy Growth (%)", min = 0, max = 5, value = 1, step = 0.1),
      
      # Cho phép người dùng chọn quốc gia để focus
      selectInput("country_select", "Select Country",
                  choices = unique(df$country),
                  selected = unique(df$country)[1])
    ),
    
    mainPanel(
      plotOutput("plot"),    # Biểu đồ CO2 dự báo
      br(),                  # Xuống dòng
      h3("Key Insights"),    # Tiêu đề nhỏ
      verbatimTextOutput("summary")  # Hiển thị các KPI, insight
    )
  )
)

server <- function(input, output) {
  
  # Reactive: tạo dữ liệu dự báo
  forecast_data <- reactive({
    
    # Lấy input từ slider
    gdp_g <- input$gdp_growth / 100
    pop_g <- input$pop_growth / 100
    energy_g <- input$energy_growth / 100
    
    # BASE từ slider
    gdp_base <- gdp_g
    pop_base <- pop_g
    energy_base <- energy_g
    
    # --- 3 SCENARIOS (Policy-based) ---
    # Base từ slider
    gdp_base <- gdp_g
    pop_base <- pop_g
    energy_base <- energy_g
    
    # Net Zero (giảm energy)
    low <- generate_future(last_data,
                           gdp_base * 0.8,
                           pop_base * 0.9,
                           -0.005)
    
    # Current Policy (baseline)
    medium <- generate_future(last_data,
                              gdp_base,
                              pop_base,
                              energy_base)
    
    # High Emission (tăng mạnh)
    high <- generate_future(last_data,
                            gdp_base * 1.2,
                            pop_base * 1.1,
                            energy_base * 1.5)
    
    # Gán scenario
    low$scenario <- "Net Zero"
    medium$scenario <- "Current Policy"
    high$scenario <- "High Emission"
    
    # Combine
    future_all <- bind_rows(low, medium, high)
    
    # Predict
    future_all$pred <- predict(model, future_all)
    
    # Decarbonization (policy-based)
    future_all$pred <- future_all$pred *
      case_when(
        future_all$scenario == "Net Zero" ~ (1 - 0.02 * (future_all$year - 2020)),
        future_all$scenario == "Current Policy" ~ (1 - 0.01 * (future_all$year - 2020)),
        future_all$scenario == "High Emission" ~ (1 - 0.005 * (future_all$year - 2020))
      )
    
    # Historical
    historical <- df %>%
      filter(country == input$country_select) %>%
      select(country, year, pred) %>%
      mutate(scenario = "Historical")
    
    # Combine all
    combined <- bind_rows(
      historical,
      future_all %>%
        filter(country == input$country_select) %>%
        select(country, year, pred, scenario)
    )
    
    combined
  })
  
  # 🔹 Plot
  output$plot <- renderPlot({
    ggplot(forecast_data(),
           aes(x = year, y = pred, color = scenario)) +
      
      geom_line(linewidth = 1.2) +
      
      scale_color_manual(values = c(
        "Historical" = "black",
        "Net Zero" = "green",
        "Current Policy" = "orange",
        "High Emission" = "red"
      )) +
      
      labs(title = paste("CO2 Emissions Forecast -", input$country_select),
           x = "Year",
           y = "CO2 Emissions (MtCO2)",
           color = "Scenario") +
      
      scale_y_continuous(labels = scales::comma) +
      
      theme_minimal(base_size = 14)
  })
  
  # Hiển thị insight 
  output$summary <- renderText({
    
    df_plot <- forecast_data()
    
    df_future <- df_plot %>%
      filter(scenario != "Historical")
    
    target_year <- max(df_future$year)
    
    co2_target <- df_future %>%
      filter(year == target_year)
    
    # --- Insight từng scenario ---
    insight <- paste0(
      co2_target$scenario, ": ",
      round(co2_target$pred, 2), " MtCO2"
    )
    
    # --- SO SÁNH (đổi tên đúng scenario) ---
    co2_low <- co2_target$pred[co2_target$scenario == "Net Zero"]
    co2_high <- co2_target$pred[co2_target$scenario == "High Emission"]
    
    diff_pct <- (co2_high - co2_low) / co2_low * 100
    
    comparison <- paste0(
      "High Emission emits ",
      round(diff_pct, 1),
      "% more CO2 than Net Zero by ",
      target_year
    )
    
    paste0(
      "Projected CO2 in ", target_year, ":\n",
      paste(insight, collapse = "\n"),
      "\n\n",
      comparison
    )
  })
  
}

shinyApp(ui = ui, server = server)
    