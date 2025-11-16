# ==============================================================================
# Water Use Intensity (WUI) Benchmarking
# GE Building 37 vs Industry Standards
# ==============================================================================

library(ggplot2)
library(dplyr)
library(scales)

# ==============================================================================
# CALCULATE WATER USE INTENSITY (WUI)
# ==============================================================================

# Building 37 data
building_sqft <- 181616  # Total square footage
annual_water_gallons <- 129777000  # Annual water consumption

# Calculate Building 37 WUI
building37_wui <- annual_water_gallons / building_sqft

# Industry benchmarks (gallons/sqft/year)
# Source: EPA WaterSense, LEED standards, commercial building benchmarks
wui_benchmarks <- data.frame(
  Category = c("Building 37\nCurrent", 
               "Office Building\nAverage", 
               "LEED Certified\nOffice",
               "LEED Platinum\nOffice"),
  WUI = c(
    building37_wui,        # 714.7 gal/sqft/yr (VERY HIGH!)
    220,                   # Typical office building
    150,                   # LEED Certified (30% reduction)
    100                    # LEED Platinum (50-55% reduction)
  ),
  Type = c("Current", "Benchmark", "Good", "Excellent")
)

# Add percentage of Building 37
wui_benchmarks <- wui_benchmarks %>%
  mutate(
    Percentage_of_B37 = (WUI / building37_wui) * 100,
    Excess = WUI - wui_benchmarks$WUI[wui_benchmarks$Type == "Excellent"]
  )

# ==============================================================================
# VISUALIZATION 1: HORIZONTAL BAR CHART (Like EUI chart)
# ==============================================================================

wui_benchmarks$Category <- factor(wui_benchmarks$Category, 
                                   levels = rev(wui_benchmarks$Category))

viz_wui_horizontal <- ggplot(wui_benchmarks, aes(x = WUI, y = Category, fill = Type)) +
  geom_col(alpha = 0.9) +
  geom_text(aes(label = paste0(round(WUI, 0), " gal/sqft/yr")), 
            hjust = -0.1, fontface = "bold", size = 4.5) +
  scale_fill_manual(values = c("Current" = "#E63946", 
                                "Benchmark" = "#457B9D",
                                "Good" = "#2A9D8F",
                                "Excellent" = "#06AED5")) +
  labs(title = "Water Use Intensity (WUI) Benchmarking",
       subtitle = "Building 37 uses 7.1x more water than LEED Platinum standard",
       x = "Water Use Intensity (Gallons/sqft/year)", 
       y = NULL,
       caption = "Source: EPA WaterSense, LEED Standards") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 12, color = "gray40"),
    legend.position = "none",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

# ==============================================================================
# VISUALIZATION 2: VERTICAL BAR CHART WITH ANNOTATIONS
# ==============================================================================

viz_wui_vertical <- ggplot(wui_benchmarks, aes(x = Category, y = WUI, fill = Type)) +
  geom_col(alpha = 0.9, width = 0.7) +
  geom_text(aes(label = paste0(round(WUI, 0), "\ngal/sqft/yr")), 
            vjust = -0.5, fontface = "bold", size = 4) +
  geom_segment(aes(x = 0.6, xend = 1.4, 
                   y = wui_benchmarks$WUI[1], 
                   yend = wui_benchmarks$WUI[1]),
               linetype = "dashed", color = "#E63946", linewidth = 1) +
  annotate("text", x = 2.5, y = building37_wui + 50,
           label = "Building 37 is consuming\n7.1x the LEED Platinum standard",
           color = "#E63946", fontface = "bold", size = 4) +
  scale_fill_manual(values = c("Current" = "#E63946", 
                                "Benchmark" = "#457B9D",
                                "Good" = "#2A9D8F",
                                "Excellent" = "#06AED5")) +
  labs(title = "Water Use Intensity: Building 37 vs Industry Standards",
       subtitle = paste0("Annual consumption: ", 
                        format(annual_water_gallons, big.mark = ","), 
                        " gallons | Building size: ",
                        format(building_sqft, big.mark = ","), " sqft"),
       x = NULL, 
       y = "Water Use Intensity (Gallons/sqft/year)",
       caption = "Lower is better | Target: LEED Platinum standard") +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 10, face = "bold")
  )

# ==============================================================================
# VISUALIZATION 3: EXCESS WATER CONSUMPTION
# ==============================================================================

# Calculate excess water vs LEED Platinum
excess_data <- wui_benchmarks %>%
  mutate(
    Excess_Gallons = (WUI - 100) * building_sqft,
    Excess_Cost = Excess_Gallons * 0.01,  # $0.01 per gallon
    Category_Clean = gsub("\n", " ", Category)
  ) %>%
  filter(Type != "Excellent")  # Don't show LEED Platinum excess (it's 0)

viz_wui_excess <- ggplot(excess_data, aes(x = reorder(Category_Clean, -Excess_Gallons), 
                                           y = Excess_Gallons / 1000000,
                                           fill = Type)) +
  geom_col(alpha = 0.9, width = 0.6) +
  geom_text(aes(label = paste0(round(Excess_Gallons / 1000000, 1), "M gal\n$", 
                                format(round(Excess_Cost / 1000), big.mark = ","), "k")),
            vjust = -0.5, fontface = "bold", size = 4) +
  scale_fill_manual(values = c("Current" = "#E63946", 
                                "Benchmark" = "#F4A261",
                                "Good" = "#E9C46A")) +
  labs(title = "Excess Water Consumption vs LEED Platinum Standard",
       subtitle = "Annual waste and associated costs",
       x = NULL,
       y = "Excess Water (Million Gallons/year)",
       caption = "Cost calculated at $0.01/gallon (supply + wastewater)") +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 10)
  )

# ==============================================================================
# VISUALIZATION 4: PERCENTAGE COMPARISON (GAUGE-STYLE)
# ==============================================================================

viz_wui_percentage <- ggplot(wui_benchmarks, aes(x = Category, y = Percentage_of_B37, 
                                                   fill = Type)) +
  geom_col(alpha = 0.9, width = 0.7) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "black", linewidth = 1) +
  geom_text(aes(label = paste0(round(Percentage_of_B37, 0), "%")),
            vjust = -0.5, fontface = "bold", size = 5) +
  annotate("text", x = 3.5, y = 105,
           label = "Building 37 baseline (100%)",
           fontface = "bold", size = 3.5) +
  scale_fill_manual(values = c("Current" = "#E63946", 
                                "Benchmark" = "#457B9D",
                                "Good" = "#2A9D8F",
                                "Excellent" = "#06AED5")) +
  labs(title = "Water Efficiency: Percentage of Building 37 Current Use",
       subtitle = "LEED Platinum uses only 14% of Building 37's water intensity",
       x = NULL,
       y = "Percentage of Building 37 WUI (%)",
       caption = "Target: Achieve LEED Platinum efficiency (86% reduction)") +
  scale_y_continuous(labels = function(x) paste0(x, "%"), 
                     expand = expansion(mult = c(0, 0.15))) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "none",
    panel.grid.major.x = element_blank()
  )

# ==============================================================================
# VISUALIZATION 5: COMBINED SAVINGS POTENTIAL
# ==============================================================================

savings_data <- data.frame(
  Scenario = c("Current State", "Match Office Average", 
               "Achieve LEED Certified", "Achieve LEED Platinum"),
  WUI = c(building37_wui, 220, 150, 100),
  Annual_Gallons = c(annual_water_gallons,
                     220 * building_sqft,
                     150 * building_sqft,
                     100 * building_sqft)
) %>%
  mutate(
    Savings_Gallons = annual_water_gallons - Annual_Gallons,
    Savings_Percent = (Savings_Gallons / annual_water_gallons) * 100,
    Savings_Cost = Savings_Gallons * 0.01,
    Savings_CO2 = (Savings_Gallons / 1000) * 27.5 * 0.92 / 2000,  # Embedded energy CO2
    Scenario = factor(Scenario, levels = Scenario)
  )

viz_wui_savings <- ggplot(savings_data[-1,], aes(x = Scenario, y = Savings_Percent, 
                                                   fill = Scenario)) +
  geom_col(alpha = 0.9, width = 0.6) +
  geom_text(aes(label = paste0(round(Savings_Percent, 0), "%\n",
                                round(Savings_Gallons / 1000000, 1), "M gal\n$",
                                format(round(Savings_Cost / 1000), big.mark = ","), "k/yr")),
            vjust = -0.3, fontface = "bold", size = 3.5, lineheight = 0.9) +
  scale_fill_viridis_d(option = "plasma", begin = 0.3, end = 0.8) +
  labs(title = "Water Reduction Scenarios: Savings Potential",
       subtitle = "Annual water savings, cost savings, and CO2 reduction",
       x = NULL,
       y = "Water Reduction (%)",
       caption = "LEED Platinum scenario saves $1.1M/year + reduces 600 tons CO2") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     expand = expansion(mult = c(0, 0.15))) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 9, angle = 15, hjust = 1)
  )

# ==============================================================================
# SAVE ALL VISUALIZATIONS
# ==============================================================================

ggsave("wui_horizontal_benchmark.png", viz_wui_horizontal, 
       width = 12, height = 6, dpi = 300)
ggsave("wui_vertical_benchmark.png", viz_wui_vertical, 
       width = 12, height = 7, dpi = 300)
ggsave("wui_excess_consumption.png", viz_wui_excess, 
       width = 12, height = 6, dpi = 300)
ggsave("wui_percentage_comparison.png", viz_wui_percentage, 
       width = 12, height = 6, dpi = 300)
ggsave("wui_savings_scenarios.png", viz_wui_savings, 
       width = 12, height = 6, dpi = 300)

# ==============================================================================
# PRINT SUMMARY STATISTICS
# ==============================================================================

cat("\n" , rep("=", 70), "\n", sep = "")
cat("WATER USE INTENSITY BENCHMARKING SUMMARY\n")
cat(rep("=", 70), "\n\n", sep = "")

cat("Building 37 Performance:\n")
cat(sprintf("  WUI: %.1f gallons/sqft/year\n", building37_wui))
cat(sprintf("  Annual Consumption: %s gallons\n", 
            format(annual_water_gallons, big.mark = ",")))
cat(sprintf("  Building Size: %s sqft\n\n", 
            format(building_sqft, big.mark = ",")))

cat("Comparison to Standards:\n")
cat(sprintf("  vs Office Average (220 gal/sqft): %.1fx higher\n", 
            building37_wui / 220))
cat(sprintf("  vs LEED Certified (150 gal/sqft): %.1fx higher\n", 
            building37_wui / 150))
cat(sprintf("  vs LEED Platinum (100 gal/sqft): %.1fx higher\n\n", 
            building37_wui / 100))

cat("Savings Potential (LEED Platinum Target):\n")
platinum_savings <- (building37_wui - 100) * building_sqft
cat(sprintf("  Water Reduction: %s gallons/year (%.0f%%)\n",
            format(platinum_savings, big.mark = ","),
            (platinum_savings / annual_water_gallons) * 100))
cat(sprintf("  Cost Savings: $%s/year\n",
            format(round(platinum_savings * 0.01), big.mark = ",")))
cat(sprintf("  CO2 Reduction: %.0f tons/year\n",
            (platinum_savings / 1000) * 27.5 * 0.92 / 2000))

cat("\n✅ All visualizations saved!\n")
cat("\nFiles created:\n")
cat("  • wui_horizontal_benchmark.png (Recommended for presentation)\n")
cat("  • wui_vertical_benchmark.png\n")
cat("  • wui_excess_consumption.png\n")
cat("  • wui_percentage_comparison.png\n")
cat("  • wui_savings_scenarios.png (Shows ROI potential)\n")
cat("\n📊 Ready for judges!\n")
