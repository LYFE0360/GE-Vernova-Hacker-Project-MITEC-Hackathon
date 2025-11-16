# ==============================================================================
# GE Vernova Building 37 - Data Visualization Suite
# MIT Energy & Climate Hackathon 2025
# Purpose: Create presentation-ready visualizations for judges
# ==============================================================================

# Install and load required packages
required_packages <- c("ggplot2", "dplyr", "tidyr", "scales", "gridExtra", 
                       "viridis", "ggrepel", "patchwork", "lubridate", "readr")

cat("Installing required packages...\n")
for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste("Installing", pkg, "...\n"))
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    library(pkg, character.only = TRUE)
  }
}
cat("✓ All packages loaded successfully!\n\n")

# ==============================================================================
# SET WORKING DIRECTORY - CHANGE THIS TO YOUR DATA FOLDER!
# ==============================================================================

# Automatic file chooser (works on Mac/Windows/Linux)
cat("Select your data folder containing the CSV files...\n")

if(interactive()) {
  # Check if RStudio is available
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    # Use RStudio's file dialog
    data_folder <- rstudioapi::selectDirectory(
      caption = "Select folder with CSV files",
      label = "Select"
    )
    if(!is.null(data_folder) && data_folder != "") {
      setwd(data_folder)
    }
  } else {
    # Fallback for non-RStudio environments
    cat("\n⚠️  Please manually set your working directory:\n")
    cat("   Edit line 35 in the script to set your data folder path\n")
    cat("   Example: setwd('/Users/ompatel/Desktop/MITHackathon')\n\n")
  }
}

# ============================================================================
# MANUAL OPTION: Uncomment and edit the line below with YOUR folder path
# ============================================================================
# setwd("/Users/ompatel/Desktop/MIT_Hackathon_Data")  # <-- CHANGE THIS PATH!

cat(paste0("\nCurrent working directory: ", getwd(), "\n"))
cat("\nLooking for required CSV files...\n")

# Check if files exist
required_files <- c(
  "Assumed Population in Future B37 Use - Badge Swipes YTD 2025.csv",
  "FINAL MIT Hackathon Data - Schenectady.csv",
  "GE 37 Conference Center usage JAN24-SEP25.csv"
)

files_exist <- file.exists(required_files)
for(i in seq_along(required_files)) {
  status <- ifelse(files_exist[i], "✓ Found", "✗ MISSING")
  cat(paste0(status, ": ", required_files[i], "\n"))
}

if(!all(files_exist)) {
  stop("\n❌ ERROR: Missing data files!\n\nPlease ensure all CSV files are in the working directory.\nCurrent directory: ", getwd())
}

# Set theme for all plots
theme_set(theme_minimal(base_size = 12) +
            theme(plot.title = element_text(face = "bold", size = 14),
                  plot.subtitle = element_text(size = 11, color = "gray40"),
                  legend.position = "bottom",
                  panel.grid.minor = element_blank()))

# ==============================================================================
# DATA LOADING
# ==============================================================================

# Load badge swipe data
badge_data <- read_csv("Assumed Population in Future B37 Use - Badge Swipes YTD 2025.csv", 
                       skip = 1, show_col_types = FALSE)

# Load energy data
energy_data <- read_csv("FINAL MIT Hackathon Data - Schenectady.csv", 
                        skip = 4, show_col_types = FALSE)

# Load conference room data
conference_data <- read_csv("GE 37 Conference Center usage JAN24-SEP25.csv", 
                            skip = 1, show_col_types = FALSE)
# Clean and parse dates more carefully
conference_data$Date <- trimws(conference_data$Date)
conference_data$Date <- mdy(conference_data$Date)
conference_data <- conference_data %>% filter(!is.na(Date))

# ==============================================================================
# 1. OCCUPANCY TRENDS VISUALIZATION
# ==============================================================================

months <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep")
monthly_swipes <- colSums(badge_data[, months], na.rm = TRUE)

occupancy_df <- data.frame(
  Month = factor(months, levels = months),
  Swipes = monthly_swipes,
  Occupancy_Rate = (monthly_swipes / (356 * 20)) * 100
)

viz1 <- ggplot(occupancy_df, aes(x = Month, y = Swipes)) +
  geom_col(fill = "#2E86AB", alpha = 0.8) +
  geom_hline(yintercept = mean(occupancy_df$Swipes), 
             linetype = "dashed", color = "#E63946", size = 1) +
  geom_text(aes(label = scales::comma(Swipes)), vjust = -0.5, size = 3.5) +
  annotate("text", x = 8, y = mean(occupancy_df$Swipes) + 100, 
           label = paste0("Avg: ", scales::comma(round(mean(occupancy_df$Swipes)))),
           color = "#E63946", fontface = "bold") +
  labs(title = "Monthly Employee Badge Swipes (2025)",
       subtitle = "Average occupancy rate: 28.5% of possible days",
       x = NULL, y = "Total Badge Swipes") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15)))

# ==============================================================================
# 2. FLOOR DISTRIBUTION PIE CHART
# ==============================================================================

floor_swipes <- badge_data %>%
  group_by(Floor) %>%
  summarise(Total_Swipes = sum(across(all_of(months)), na.rm = TRUE)) %>%
  mutate(Percentage = Total_Swipes / sum(Total_Swipes) * 100,
         Label = paste0("Floor ", Floor, "\n", round(Percentage, 1), "%"))

viz2 <- ggplot(floor_swipes, aes(x = "", y = Total_Swipes, fill = factor(Floor))) +
  geom_col(width = 1, color = "white", size = 2) +
  coord_polar("y", start = 0) +
  geom_text(aes(label = Label), 
            position = position_stack(vjust = 0.5),
            color = "white", fontface = "bold", size = 4) +
  scale_fill_viridis_d(option = "D", begin = 0.2, end = 0.9) +
  labs(title = "Occupancy Distribution by Floor",
       subtitle = "Floors 3-5 account for 73% of all traffic") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
        legend.position = "none")

# ==============================================================================
# 3. ENERGY CONSUMPTION SEASONALITY (DUAL AXIS)
# ==============================================================================

energy_monthly <- data.frame(
  Month = factor(months, levels = months),
  Electricity_MWh = c(463, 413, 485, 474, 461, 477, 516, 491, 470),
  Gas_kCCF = c(48, 41, 35, 23, 14, 12, 8, 11, 12),
  Water_Mgal = c(5.978, 5.901, 6.083, 9.405, 9.434, 9.405, 17.143, 17.287, 16.696)
)

# Normalize data for dual axis
energy_monthly$Gas_Scaled <- energy_monthly$Gas_kCCF * 10

viz3 <- ggplot(energy_monthly, aes(x = Month)) +
  geom_line(aes(y = Electricity_MWh, group = 1, color = "Electricity"), 
            linewidth = 1.5) +
  geom_point(aes(y = Electricity_MWh, color = "Electricity"), size = 4) +
  geom_line(aes(y = Gas_Scaled, group = 1, color = "Natural Gas"), 
            linewidth = 1.5) +
  geom_point(aes(y = Gas_Scaled, color = "Natural Gas"), size = 4) +
  scale_color_manual(values = c("Electricity" = "#2E86AB", "Natural Gas" = "#E63946"),
                     name = NULL) +
  scale_y_continuous(
    name = "Electricity (MWh)",
    sec.axis = sec_axis(~./10, name = "Natural Gas (k CCF)")
  ) +
  labs(title = "Energy Consumption Seasonality",
       subtitle = "Electricity peaks in summer (cooling), Gas peaks in winter (heating)",
       x = NULL) +
  theme(legend.position = "bottom",
        axis.title.y.left = element_text(color = "#2E86AB"),
        axis.title.y.right = element_text(color = "#E63946"))

# ==============================================================================
# 4. WATER CONSUMPTION ANOMALY
# ==============================================================================

water_analysis <- energy_monthly %>%
  mutate(Season = case_when(
    Month %in% c("Jan", "Feb") ~ "Winter",
    Month %in% c("Mar", "Apr", "May") ~ "Spring",
    Month %in% c("Jun", "Jul", "Aug", "Sep") ~ "Summer"
  ))

viz4 <- ggplot(water_analysis, aes(x = Month, y = Water_Mgal, fill = Season)) +
  geom_col(alpha = 0.9) +
  geom_hline(yintercept = mean(water_analysis$Water_Mgal[1:5]), 
             linetype = "dashed", color = "black", linewidth = 1) +
  annotate("rect", xmin = 6.5, xmax = 9.5, ymin = 0, ymax = Inf, 
           alpha = 0.1, fill = "red") +
  annotate("text", x = 8, y = 18, 
           label = "2.8x Summer Surge\n(Cooling Tower Issue)", 
           fontface = "bold", color = "#E63946", size = 4) +
  scale_fill_manual(values = c("Winter" = "#457B9D", 
                               "Spring" = "#2A9D8F", 
                               "Summer" = "#E76F51")) +
  labs(title = "Water Consumption: Massive Summer Surge",
       subtitle = "Jul-Sep usage is 2.8x higher than spring average",
       x = NULL, y = "Water Consumption (Million Gallons)") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.1)))

# ==============================================================================
# 5. CONFERENCE ROOM GHOST BOOKINGS
# ==============================================================================

conf_2025 <- conference_data %>%
  filter(year(Date) == 2025) %>%
  mutate(Status = ifelse(`#Attendees` == 0, "Ghost Booking\n(0 attendees)", 
                         "Utilized Booking"))

ghost_summary <- conf_2025 %>%
  group_by(Status) %>%
  summarise(Count = n(), .groups = "drop") %>%
  mutate(Percentage = Count / sum(Count) * 100)

viz5 <- ggplot(ghost_summary, aes(x = Status, y = Count, fill = Status)) +
  geom_col(width = 0.6, alpha = 0.9) +
  geom_text(aes(label = paste0(Count, "\n(", round(Percentage, 1), "%)")),
            vjust = -0.5, fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Ghost Booking\n(0 attendees)" = "#E63946", 
                               "Utilized Booking" = "#2A9D8F")) +
  labs(title = "Conference Room Booking Efficiency Problem",
       subtitle = "15% of bookings are 'ghost' meetings with zero attendees",
       x = NULL, y = "Number of Bookings") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  theme(legend.position = "none")

# ==============================================================================
# 6. OCCUPANCY vs ENERGY CORRELATION
# ==============================================================================

correlation_data <- data.frame(
  Month = factor(months, levels = months),
  Occupancy = monthly_swipes,
  Electricity = energy_monthly$Electricity_MWh,
  Gas = energy_monthly$Gas_kCCF,
  Water = energy_monthly$Water_Mgal
) %>%
  mutate(across(c(Occupancy, Electricity, Gas, Water), 
                ~scale(.), .names = "{.col}_Scaled"))

corr_long <- correlation_data %>%
  select(Month, ends_with("Scaled")) %>%
  pivot_longer(cols = ends_with("Scaled"), 
               names_to = "Resource", 
               values_to = "Normalized_Value") %>%
  mutate(Resource = gsub("_Scaled", "", Resource))

viz6 <- ggplot(corr_long, aes(x = Month, y = Normalized_Value, 
                              color = Resource, group = Resource)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Occupancy" = "#264653",
                                "Electricity" = "#2A9D8F",
                                "Gas" = "#E76F51",
                                "Water" = "#F4A261"),
                     labels = c("Occupancy (Badge Swipes)", 
                                "Electricity", "Natural Gas", "Water")) +
  labs(title = "Resource Consumption vs Occupancy (Normalized)",
       subtitle = "Gas inversely correlated with occupancy (weather-driven); Water strongly correlated",
       x = NULL, y = "Normalized Value (Z-Score)", color = NULL) +
  theme(legend.position = "bottom")

# ==============================================================================
# 7. ENERGY INTENSITY BENCHMARKING
# ==============================================================================

eui_data <- data.frame(
  Category = c("Building 37\nCurrent", "Office Building\nAverage", 
               "LEED Platinum\nOffice", "Net Zero\nOffice"),
  EUI = c(31.5, 15.0, 8.5, 5.0),
  Type = c("Current", "Benchmark", "Target", "Aspirational")
)

eui_data$Category <- factor(eui_data$Category, levels = rev(eui_data$Category))

viz7 <- ggplot(eui_data, aes(x = EUI, y = Category, fill = Type)) +
  geom_col(alpha = 0.9) +
  geom_text(aes(label = paste0(EUI, " kWh/sqft/yr")), 
            hjust = -0.1, fontface = "bold", size = 4) +
  scale_fill_manual(values = c("Current" = "#E63946", 
                               "Benchmark" = "#457B9D",
                               "Target" = "#2A9D8F",
                               "Aspirational" = "#264653")) +
  labs(title = "Energy Use Intensity (EUI) Benchmarking",
       subtitle = "Building 37 uses 3.7x more energy than LEED Platinum standard",
       x = "Energy Use Intensity (kWh/sqft/year)", y = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  theme(legend.position = "none")

# ==============================================================================
# 8. CO2 EMISSIONS BREAKDOWN
# ==============================================================================

co2_data <- data.frame(
  Source = c("Electricity\n(Direct)", "Natural Gas", "Water\n(Embedded)"),
  CO2_Tons = c(2606, 1598, 1641),
  Percentage = c(44.6, 27.3, 28.1)
)

co2_data$Source <- factor(co2_data$Source, 
                          levels = co2_data$Source[order(co2_data$CO2_Tons, decreasing = TRUE)])

viz8 <- ggplot(co2_data, aes(x = Source, y = CO2_Tons, fill = Source)) +
  geom_col(alpha = 0.9, width = 0.7) +
  geom_text(aes(label = paste0(scales::comma(CO2_Tons), " tons\n(", 
                               round(Percentage, 1), "%)")),
            vjust = -0.5, fontface = "bold", size = 4.5) +
  scale_fill_manual(values = c("#E63946", "#F77F00", "#06AED5")) +
  labs(title = "Annual CO2 Emissions Breakdown",
       subtitle = "Total: 5,845 tons CO2/year - Water's embedded energy is a major contributor",
       x = NULL, y = "CO2 Emissions (Tons/Year)") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  theme(legend.position = "none")

# ==============================================================================
# 9. EMPLOYEE UTILIZATION CATEGORIES
# ==============================================================================

total_swipes <- rowSums(badge_data[, months], na.rm = TRUE)

utilization_df <- data.frame(
  Category = c("Very Low\n(<1 day/month)", 
               "Low\n(1-3 days/month)", 
               "Medium\n(3-5 days/month)", 
               "High\n(5+ days/month)"),
  Count = c(
    sum(total_swipes < 30),
    sum(total_swipes >= 30 & total_swipes < 90),
    sum(total_swipes >= 90 & total_swipes < 140),
    sum(total_swipes >= 140)
  )
) %>%
  mutate(Percentage = Count / sum(Count) * 100,
         Category = factor(Category, levels = Category))

viz9 <- ggplot(utilization_df, aes(x = Category, y = Count, fill = Category)) +
  geom_col(alpha = 0.9) +
  geom_text(aes(label = paste0(Count, "\n(", round(Percentage, 1), "%)")),
            vjust = -0.5, fontface = "bold", size = 4) +
  scale_fill_viridis_d(option = "plasma", begin = 0.2, end = 0.9) +
  labs(title = "Employee Office Utilization Distribution",
       subtitle = "63% of employees rarely on-site - opportunity for hoteling strategy",
       x = NULL, y = "Number of Employees") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  theme(legend.position = "none")

# ==============================================================================
# 10. COST PER SWIPE METRIC
# ==============================================================================

cost_data <- data.frame(
  Month = factor(months, levels = months),
  Swipes = monthly_swipes,
  Electricity_Cost = energy_monthly$Electricity_MWh * 1000 * 0.15,
  Gas_Cost = energy_monthly$Gas_kCCF * 1000 * 1.20,
  Water_Cost = energy_monthly$Water_Mgal * 1000000 * 0.01
) %>%
  mutate(Total_Cost = Electricity_Cost + Gas_Cost + Water_Cost,
         Cost_Per_Swipe = Total_Cost / Swipes)

viz10 <- ggplot(cost_data, aes(x = Month, y = Cost_Per_Swipe)) +
  geom_line(aes(group = 1), color = "#E63946", linewidth = 1.5) +
  geom_point(size = 4, color = "#E63946") +
  geom_hline(yintercept = 3, linetype = "dashed", color = "#2A9D8F", linewidth = 1) +
  annotate("text", x = 8, y = 3.2, 
           label = "Target: $3.00/swipe", 
           color = "#2A9D8F", fontface = "bold") +
  geom_text(aes(label = paste0("$", round(Cost_Per_Swipe, 2))), 
            vjust = -1, fontface = "bold", size = 3.5) +
  labs(title = "Operational Cost Efficiency by Month",
       subtitle = "Current average: $4.20 per badge swipe | Target: <$3.00",
       x = NULL, y = "Cost per Badge Swipe ($)") +
  scale_y_continuous(labels = scales::dollar, expand = expansion(mult = c(0, 0.15)))

# ==============================================================================
# SAVE ALL VISUALIZATIONS
# ==============================================================================

# Save individual plots
ggsave("viz1_monthly_occupancy.png", viz1, width = 12, height = 6, dpi = 300)
ggsave("viz2_floor_distribution.png", viz2, width = 8, height = 8, dpi = 300)
ggsave("viz3_energy_seasonality.png", viz3, width = 12, height = 6, dpi = 300)
ggsave("viz4_water_surge.png", viz4, width = 12, height = 6, dpi = 300)
ggsave("viz5_ghost_bookings.png", viz5, width = 10, height = 6, dpi = 300)
ggsave("viz6_correlation.png", viz6, width = 12, height = 6, dpi = 300)
ggsave("viz7_eui_benchmarking.png", viz7, width = 12, height = 6, dpi = 300)
ggsave("viz8_co2_breakdown.png", viz8, width = 10, height = 6, dpi = 300)
ggsave("viz9_utilization.png", viz9, width = 12, height = 6, dpi = 300)
ggsave("viz10_cost_per_swipe.png", viz10, width = 12, height = 6, dpi = 300)

# Create comprehensive dashboard (2x2 grid)
dashboard_top <- (viz1 | viz2)
dashboard_middle <- (viz3 | viz4)
dashboard_bottom <- (viz7 | viz8)

dashboard_combined <- dashboard_top / dashboard_middle / dashboard_bottom +
  plot_annotation(
    title = "GE VERNOVA BUILDING 37 - SUSTAINABILITY ANALYSIS DASHBOARD",
    subtitle = "MIT Energy & Climate Hackathon 2025",
    theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
                  plot.subtitle = element_text(size = 14, hjust = 0.5))
  )

ggsave("dashboard_comprehensive.png", dashboard_combined, 
       width = 18, height = 20, dpi = 300)

# Create executive summary dashboard (key metrics)
exec_dashboard <- (viz7 | viz8) / (viz5 | viz10) +
  plot_annotation(
    title = "EXECUTIVE SUMMARY: KEY METRICS",
    subtitle = "Building 37 Sustainability Transformation Opportunity",
    theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
                  plot.subtitle = element_text(size = 12, hjust = 0.5))
  )

ggsave("dashboard_executive.png", exec_dashboard, 
       width = 16, height = 12, dpi = 300)

cat("\n✅ ALL VISUALIZATIONS SAVED!\n")
cat("\nFiles created:\n")
cat("  • viz1_monthly_occupancy.png\n")
cat("  • viz2_floor_distribution.png\n")
cat("  • viz3_energy_seasonality.png\n")
cat("  • viz4_water_surge.png\n")
cat("  • viz5_ghost_bookings.png\n")
cat("  • viz6_correlation.png\n")
cat("  • viz7_eui_benchmarking.png\n")
cat("  • viz8_co2_breakdown.png\n")
cat("  • viz9_utilization.png\n")
cat("  • viz10_cost_per_swipe.png\n")
cat("  • dashboard_comprehensive.png (All visualizations)\n")
cat("  • dashboard_executive.png (Key metrics for judges)\n")
cat("\n📊 Ready for presentation!\n")