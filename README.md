# Can Fairy Recycling Experiment

This repository contains the data and analysis code for a field experiment studying recycling behavior among households in Columbus, Ohio.

## What This Study Does

The Can Fairy Program is a community recycling initiative in Columbus, Ohio. We randomly assigned 200 participating households into two groups:

- **Norm-based messaging** – messages showing what neighbors in the community are doing
- **Educational messaging** – messages with recycling tips and information

We tracked three outcomes every week for 29 weeks:
- How full recycling bins were (fill level)
- Whether households participated each week
- Whether bins had contamination (wrong items)

We use a Difference-in-Differences (DiD) approach to estimate the effect of messaging type on recycling behavior.

## Files in This Repository

```
can-fairy-recycling-experiment/
├── data/
│   └── recycling_panel_merged.xlsx     # Cleaned panel dataset
├── CANFAIRY_GITHUB CODE.R              # Analysis code in R
├── CAN FAIRY_GITHUB ANALYSIS (PYTHON).py  # Analysis code in Python
├── README.md
└── LICENSE
```

## Data

The dataset has around 5,800 rows — one row per household per week. Key variables:

| Variable | Description |
|---|---|
| `treated` | 1 = Norm-based, 0 = Educational |
| `post` | 1 = After intervention, 0 = Before |
| `fill_level` | Bin fill level (0 to 1) |
| `participated` | 1 = Participated that week |
| `contaminated` | 1 = Bin had contamination |
| `avg_temp_c` | Average temperature that week |
| `bad_weather` | 1 = Bad weather week |
| `osu_home_game` | 1 = OSU football home game week |
| `holiday_week` | 1 = Holiday week |

No personally identifiable information is included in the data.

## How to Run

### R
```r
install.packages(c("tidyverse", "readxl", "fixest",
                   "modelsummary", "ggplot2", "patchwork", "scales"))
source("CANFAIRY_GITHUB CODE.R")
```

### Python
```bash
pip install pandas numpy statsmodels linearmodels matplotlib scipy openpyxl
python "CAN FAIRY_GITHUB ANALYSIS (PYTHON).py"
```

Outputs (tables and figures) are saved automatically to an `outputs/` folder.

## Authors

**Suraksha Baral**  
PhD Student, Agricultural, Environmental & Development Economics  
The Ohio State University  
Advisor: Dr. Brian Roe

## License

MIT License
