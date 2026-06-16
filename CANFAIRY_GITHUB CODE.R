# ============================================================
# Can Fairy Recycling Experiment — Analysis Script
# ============================================================
# Project:     Can Fairy Program Field Experiment
# Author:      Suraksha Baral
#              PhD Candidate, Agricultural, Environmental &
#              Development Economics (AEDE)
#              The Ohio State University
# Advisor:     Dr. Brian Roe
# Date:        2026
#
# Description: Difference-in-Differences (DiD) analysis
#              comparing norm-based vs. educational messaging
#              on household recycling behavior in Columbus, OH.
#              Outcomes: fill level, participation, contamination.
#              N = 200 households, 29 weeks.
#
# Data:        Place recycling_panel_merged.csv in the data/ folder
# Outputs:     Regression tables and figures saved to outputs/
# ============================================================


# ── 0. PACKAGES ──────────────────────────────────────────────────────────
library(tidyverse)
library(fixest)
library(modelsummary)
library(ggplot2)
library(patchwork)
library(scales)


# ── 1. PATHS (edit only this section if needed) ──────────────────────────
data_path   <- "data/recycling_panel_merged.csv"
output_path <- "outputs/"
dir.create(output_path, showWarnings = FALSE)


# ── 2. LOAD DATA ─────────────────────────────────────────────────────────
df <- read_csv(data_path)


# ── 3. QUICK CHECKS ──────────────────────────────────────────────────────
cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n")
cat("Unique households:", n_distinct(df$addr_clean), "\n")
cat("Weeks:", n_distinct(df$week), "\n")

cat("\nTreatment group sizes:\n")
df %>%
  filter(!is.na(treated)) %>%
  distinct(addr_clean, treated) %>%
  count(treated) %>%
  print()

cat("\nPre/Post breakdown:\n")
df %>%
  filter(!is.na(treated)) %>%
  distinct(week, post) %>%
  count(post) %>%
  print()


# ── 4. PREPARE ANALYSIS SAMPLE ───────────────────────────────────────────
df_analysis <- df %>%
  filter(!is.na(treated)) %>%
  mutate(
    treated    = as.integer(treated),
    post       = as.integer(post),
    treat_post = treated * post
  )

cat("\nAnalysis sample:\n")
cat("  Rows:", nrow(df_analysis), "\n")
cat("  Households:", n_distinct(df_analysis$addr_clean), "\n\n")


# ── 5. SIGNIFICANCE CODES ────────────────────────────────────────────────
# *** p < 0.01  |  ** p < 0.05  |  * p < 0.10
my_signif <- c("***" = 0.01, "**" = 0.05, "*" = 0.10)


# ── 6. DiD MODELS ────────────────────────────────────────────────────────
# Model 1: Simple DiD (treated, post, interaction only)
# Model 2: DiD + week fixed effects
# Model 3: DiD + controls (no fixed effects)
# Model 4: DiD + controls interacted with treatment
# All models use household-clustered standard errors

# ── 6a. FILL LEVEL ───────────────────────────────────────────────────────
fill_1 <- feols(
  fill_level ~ treated + post + treat_post,
  data    = df_analysis,
  cluster = ~addr_clean
)

fill_2 <- feols(
  fill_level ~ treated + treat_post | week,
  data    = df_analysis,
  cluster = ~addr_clean
)

fill_3 <- feols(
  fill_level ~ treated + post + treat_post +
    avg_temp_c + bad_weather + osu_home_game + holiday_week,
  data    = df_analysis,
  cluster = ~addr_clean
)

fill_4 <- feols(
  fill_level ~ treated + post + treat_post +
    avg_temp_c + bad_weather + osu_home_game + holiday_week +
    treat_post:avg_temp_c + treat_post:bad_weather +
    treat_post:osu_home_game + treat_post:holiday_week,
  data    = df_analysis,
  cluster = ~addr_clean
)

# ── 6b. PARTICIPATION ────────────────────────────────────────────────────
part_1 <- feols(
  participated ~ treated + post + treat_post,
  data    = df_analysis,
  cluster = ~addr_clean
)

part_2 <- feols(
  participated ~ treated + treat_post | week,
  data    = df_analysis,
  cluster = ~addr_clean
)

part_3 <- feols(
  participated ~ treated + post + treat_post +
    avg_temp_c + bad_weather + osu_home_game + holiday_week,
  data    = df_analysis,
  cluster = ~addr_clean
)

part_4 <- feols(
  participated ~ treated + post + treat_post +
    avg_temp_c + bad_weather + osu_home_game + holiday_week +
    treat_post:avg_temp_c + treat_post:bad_weather +
    treat_post:osu_home_game + treat_post:holiday_week,
  data    = df_analysis,
  cluster = ~addr_clean
)

# ── 6c. CONTAMINATION ────────────────────────────────────────────────────
cont_1 <- feols(
  contaminated ~ treated + post + treat_post,
  data    = df_analysis,
  cluster = ~addr_clean
)

cont_2 <- feols(
  contaminated ~ treated + treat_post | week,
  data    = df_analysis,
  cluster = ~addr_clean
)

cont_3 <- feols(
  contaminated ~ treated + post + treat_post +
    avg_temp_c + bad_weather + osu_home_game + holiday_week,
  data    = df_analysis,
  cluster = ~addr_clean
)

cont_4 <- feols(
  contaminated ~ treated + post + treat_post +
    avg_temp_c + bad_weather + osu_home_game + holiday_week +
    treat_post:avg_temp_c + treat_post:bad_weather +
    treat_post:osu_home_game + treat_post:holiday_week,
  data    = df_analysis,
  cluster = ~addr_clean
)


# ── 7. PRINT RESULTS ─────────────────────────────────────────────────────
cat("\n── Fill Level ──────────────────────────────────\n")
etable(fill_1, fill_2, fill_3, fill_4,
       digits      = 4,
       signif.code = my_signif)

cat("\n── Participation ───────────────────────────────\n")
etable(part_1, part_2, part_3, part_4,
       digits      = 4,
       signif.code = my_signif)

cat("\n── Contamination ───────────────────────────────\n")
etable(cont_1, cont_2, cont_3, cont_4,
       digits      = 4,
       signif.code = my_signif)


# ── 8. SAVE REGRESSION TABLES ────────────────────────────────────────────
etable(fill_1, fill_2, fill_3, fill_4,
       digits      = 4,
       signif.code = my_signif,
       file        = file.path(output_path, "table_fill_level.tex"))

etable(part_1, part_2, part_3, part_4,
       digits      = 4,
       signif.code = my_signif,
       file        = file.path(output_path, "table_participation.tex"))

etable(cont_1, cont_2, cont_3, cont_4,
       digits      = 4,
       signif.code = my_signif,
       file        = file.path(output_path, "table_contamination.tex"))


# ── 9. WEEKLY MEANS BY TREATMENT ARM ─────────────────────────────────────
weekly_means <- df_analysis %>%
  filter(!is.na(treated)) %>%
  group_by(week, week_start, treated) %>%
  summarise(
    mean_fill         = mean(fill_level,   na.rm = TRUE),
    mean_participated = mean(participated, na.rm = TRUE),
    mean_contaminated = mean(contaminated, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(arm = if_else(treated == 1, "Norm-based", "Educational"))

print(weekly_means, n = 60)


# ── 10. FIGURES ───────────────────────────────────────────────────────────
intervention_date <- as.Date("2025-11-01")

colors <- c("Educational" = "#1D9E75", "Norm-based" = "#7F77DD")

theme_clean <- theme_classic(base_size = 13) +
  theme(
    panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
    panel.grid.major.x = element_blank(),
    legend.position    = "bottom",
    legend.title       = element_blank(),
    strip.background   = element_blank(),
    axis.text.x        = element_text(angle = 45, hjust = 1, size = 10),
    axis.title         = element_text(size = 11),
    plot.title         = element_text(size = 12, face = "bold", hjust = 0.5)
  )

# Panel A: Fill level
p1 <- ggplot(weekly_means, aes(x = week_start, y = mean_fill,
                               color = arm, group = arm)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = intervention_date,
             linetype = "dashed", color = "black", linewidth = 0.6) +
  annotate("text", x = intervention_date + 4, y = 0.95,
           label = "Intervention start", hjust = 0, size = 3.2) +
  scale_color_manual(values = colors) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(title = "Panel A: Fill level",
       x = NULL, y = "Mean fill level (0-1)") +
  theme_clean

# Panel B: Participation
p2 <- ggplot(weekly_means, aes(x = week_start, y = mean_participated,
                               color = arm, group = arm)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = intervention_date,
             linetype = "dashed", color = "black", linewidth = 0.6) +
  scale_color_manual(values = colors) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(title = "Panel B: Participation",
       x = NULL, y = "Mean participation rate") +
  theme_clean

# Panel C: Contamination
p3 <- ggplot(weekly_means, aes(x = week_start, y = mean_contaminated,
                               color = arm, group = arm)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = intervention_date,
             linetype = "dashed", color = "black", linewidth = 0.6) +
  scale_color_manual(values = colors) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +
  scale_y_continuous(limits = c(0, 0.25), breaks = seq(0, 0.25, 0.05)) +
  labs(title = "Panel C: Contamination",
       x = NULL, y = "Mean contamination rate") +
  theme_clean

# Combined 3-panel figure
combined <- p1 / p2 / p3 +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave(file.path(output_path, "can_fairy_weekly_trends.pdf"),
       combined, width = 8, height = 10, dpi = 300)
ggsave(file.path(output_path, "can_fairy_weekly_trends.png"),
       combined, width = 8, height = 10, dpi = 300)

# Fill level only
p_fill <- ggplot(weekly_means, aes(x = week_start, y = mean_fill,
                                   color = arm, group = arm)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  geom_vline(xintercept = intervention_date,
             linetype = "dashed", color = "black", linewidth = 0.6) +
  annotate("text", x = intervention_date + 4, y = 0.95,
           label = "Intervention start", hjust = 0, size = 3.5) +
  scale_color_manual(values = colors) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(x = NULL, y = "Mean fill level (0-1)", color = NULL) +
  theme_classic(base_size = 13) +
  theme(
    panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
    legend.position    = "bottom",
    axis.text.x        = element_text(angle = 45, hjust = 1, size = 10)
  )

ggsave(file.path(output_path, "can_fairy_fill_level_trend.pdf"),
       p_fill, width = 8, height = 5, dpi = 300)
ggsave(file.path(output_path, "can_fairy_fill_level_trend.png"),
       p_fill, width = 8, height = 5, dpi = 300)


# ── 11. PRE-TREND TESTS ──────────────────────────────────────────────────
pre_df <- df_analysis %>% filter(post == 0)

# Regression-based pre-trend test (fill level)
pretrend_fill <- feols(
  fill_level ~ treated * week,
  data    = pre_df,
  cluster = ~addr_clean
)
summary(pretrend_fill)

# Balance checks: t-tests on pre-period means
cat("\nPre-period balance tests:\n")
cat("Fill level:\n");      print(t.test(fill_level    ~ treated, data = pre_df))
cat("Participation:\n");   print(t.test(participated  ~ treated, data = pre_df))
cat("Contamination:\n");   print(t.test(contaminated  ~ treated, data = pre_df))

cat("\nAll outputs saved to:", output_path, "\n")