# ============================================================
# Can Fairy Recycling Experiment — Analysis Script (Python)
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
# Requirements: pip install pandas numpy statsmodels linearmodels
#               matplotlib scipy
# Data:        Place recycling_panel_merged.csv in the data/ folder
# Outputs:     Regression tables and figures saved to outputs/
# ============================================================


# ── 0. IMPORTS ───────────────────────────────────────────────────────────
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from scipy import stats
from linearmodels.panel import PanelOLS
import statsmodels.formula.api as smf
import warnings
warnings.filterwarnings("ignore")


# ── 1. PATHS ─────────────────────────────────────────────────────────────
data_path   = "data/recycling_panel_merged.csv"
output_path = "outputs/"
os.makedirs(output_path, exist_ok=True)


# ── 2. LOAD DATA ─────────────────────────────────────────────────────────
df = pd.read_csv(data_path)


# ── 3. QUICK CHECKS ──────────────────────────────────────────────────────
print(f"Rows: {len(df)} | Columns: {len(df.columns)}")
print(f"Unique households: {df['addr_clean'].nunique()}")
print(f"Weeks: {df['week'].nunique()}")

print("\nTreatment group sizes:")
print(
    df.dropna(subset=["treated"])
    .drop_duplicates(subset=["addr_clean", "treated"])
    .groupby("treated")
    .size()
    .reset_index(name="n")
)

print("\nPre/Post breakdown:")
print(
    df.dropna(subset=["treated"])
    .drop_duplicates(subset=["week", "post"])
    .groupby("post")
    .size()
    .reset_index(name="n")
)


# ── 4. PREPARE ANALYSIS SAMPLE ───────────────────────────────────────────
df_analysis = df.dropna(subset=["treated"]).copy()
df_analysis["treated"]    = df_analysis["treated"].astype(int)
df_analysis["post"]       = df_analysis["post"].astype(int)
df_analysis["treat_post"] = df_analysis["treated"] * df_analysis["post"]
df_analysis["week_start"] = pd.to_datetime(df_analysis["week_start"])

print(f"\nAnalysis sample:")
print(f"  Rows: {len(df_analysis)}")
print(f"  Households: {df_analysis['addr_clean'].nunique()}\n")


# ── 5. DiD HELPER FUNCTION ───────────────────────────────────────────────
def run_did_models(outcome, df):
    """
    Runs 4 DiD models for a given outcome variable.
    Returns a dict of fitted models.
    """
    # Model 1: Simple DiD
    m1 = smf.ols(
        f"{outcome} ~ treated + post + treat_post",
        data=df
    ).fit(cov_type="cluster", cov_kwds={"groups": df["addr_clean"]})

    # Model 2: DiD + week fixed effects
    m2 = smf.ols(
        f"{outcome} ~ treated + treat_post + C(week)",
        data=df
    ).fit(cov_type="cluster", cov_kwds={"groups": df["addr_clean"]})

    # Model 3: DiD + controls
    m3 = smf.ols(
        f"{outcome} ~ treated + post + treat_post + "
        f"avg_temp_c + bad_weather + osu_home_game + holiday_week",
        data=df
    ).fit(cov_type="cluster", cov_kwds={"groups": df["addr_clean"]})

    # Model 4: DiD + controls interacted with treatment
    m4 = smf.ols(
        f"{outcome} ~ treated + post + treat_post + "
        f"avg_temp_c + bad_weather + osu_home_game + holiday_week + "
        f"treat_post:avg_temp_c + treat_post:bad_weather + "
        f"treat_post:osu_home_game + treat_post:holiday_week",
        data=df
    ).fit(cov_type="cluster", cov_kwds={"groups": df["addr_clean"]})

    return {"Model 1": m1, "Model 2": m2, "Model 3": m3, "Model 4": m4}


def print_results(models, label):
    """Prints DiD coefficient table for treat_post across models."""
    print(f"\n── {label} ──────────────────────────────────")
    print(f"{'Model':<12} {'Coef':>10} {'SE':>10} {'p-value':>10} {'Sig':>5}")
    print("-" * 50)
    for name, m in models.items():
        if "treat_post" in m.params:
            coef = m.params["treat_post"]
            se   = m.bse["treat_post"]
            pval = m.pvalues["treat_post"]
            sig  = "***" if pval < 0.01 else "**" if pval < 0.05 else "*" if pval < 0.10 else ""
            print(f"{name:<12} {coef:>10.4f} {se:>10.4f} {pval:>10.4f} {sig:>5}")
    print(f"  N = {int(models['Model 1'].nobs)}")


def save_results(models, label, filename):
    """Saves full model summaries to a text file."""
    filepath = os.path.join(output_path, filename)
    with open(filepath, "w") as f:
        f.write(f"{'='*60}\n{label}\n{'='*60}\n\n")
        for name, m in models.items():
            f.write(f"\n{name}\n{'-'*40}\n")
            f.write(m.summary().as_text())
            f.write("\n\n")
    print(f"  Saved: {filepath}")


# ── 6. RUN DiD MODELS ────────────────────────────────────────────────────
fill_models = run_did_models("fill_level",   df_analysis)
part_models = run_did_models("participated", df_analysis)
cont_models = run_did_models("contaminated", df_analysis)


# ── 7. PRINT RESULTS ─────────────────────────────────────────────────────
print_results(fill_models, "Fill Level")
print_results(part_models, "Participation")
print_results(cont_models, "Contamination")


# ── 8. SAVE REGRESSION TABLES ────────────────────────────────────────────
save_results(fill_models, "Fill Level",   "table_fill_level.txt")
save_results(part_models, "Participation","table_participation.txt")
save_results(cont_models, "Contamination","table_contamination.txt")


# ── 9. WEEKLY MEANS BY TREATMENT ARM ─────────────────────────────────────
weekly_means = (
    df_analysis.dropna(subset=["treated"])
    .groupby(["week", "week_start", "treated"])
    .agg(
        mean_fill         = ("fill_level",   "mean"),
        mean_participated = ("participated", "mean"),
        mean_contaminated = ("contaminated", "mean"),
    )
    .reset_index()
)
weekly_means["arm"] = weekly_means["treated"].map({1: "Norm-based", 0: "Educational"})
weekly_means["week_start"] = pd.to_datetime(weekly_means["week_start"])

print("\nWeekly means by arm:")
print(weekly_means.to_string())


# ── 10. FIGURES ───────────────────────────────────────────────────────────
intervention_date = pd.Timestamp("2025-11-01")

colors = {"Educational": "#1D9E75", "Norm-based": "#7F77DD"}

def style_ax(ax):
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
    ax.xaxis.set_major_locator(mdates.MonthLocator(interval=2))
    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right", fontsize=10)
    ax.yaxis.grid(True, color="gray", alpha=0.3, linewidth=0.5)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.axvline(intervention_date, color="black", linestyle="--", linewidth=0.8)

# Combined 3-panel figure
fig, axes = plt.subplots(3, 1, figsize=(8, 10), sharex=True)

panels = [
    ("mean_fill",         "Mean fill level (0–1)",    "Panel A: Fill level",      (0, 1)),
    ("mean_participated", "Mean participation rate",   "Panel B: Participation",   (0, 1)),
    ("mean_contaminated", "Mean contamination rate",   "Panel C: Contamination",   (0, 0.25)),
]

for ax, (col, ylabel, title, ylim) in zip(axes, panels):
    for arm, grp in weekly_means.groupby("arm"):
        grp = grp.sort_values("week_start")
        ax.plot(grp["week_start"], grp[col],
                label=arm, color=colors[arm], linewidth=0.9, marker="o", markersize=3)
    style_ax(ax)
    ax.set_ylim(ylim)
    ax.set_ylabel(ylabel, fontsize=11)
    ax.set_title(title, fontsize=12, fontweight="bold")

axes[0].annotate("Intervention start",
                 xy=(intervention_date, 0.95),
                 xytext=(intervention_date + pd.Timedelta(days=4), 0.95),
                 fontsize=9)

handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="lower center", ncol=2,
           frameon=False, fontsize=11, bbox_to_anchor=(0.5, -0.02))

plt.tight_layout(rect=[0, 0.03, 1, 1])
fig.savefig(os.path.join(output_path, "can_fairy_weekly_trends.pdf"), dpi=300, bbox_inches="tight")
fig.savefig(os.path.join(output_path, "can_fairy_weekly_trends.png"), dpi=300, bbox_inches="tight")
plt.close()

# Fill level only
fig2, ax2 = plt.subplots(figsize=(8, 5))
for arm, grp in weekly_means.groupby("arm"):
    grp = grp.sort_values("week_start")
    ax2.plot(grp["week_start"], grp["mean_fill"],
             label=arm, color=colors[arm], linewidth=0.9, marker="o", markersize=4)
style_ax(ax2)
ax2.set_ylim(0, 1)
ax2.set_ylabel("Mean fill level (0–1)", fontsize=11)
ax2.annotate("Intervention start",
             xy=(intervention_date, 0.95),
             xytext=(intervention_date + pd.Timedelta(days=4), 0.95),
             fontsize=9)
ax2.legend(loc="lower right", frameon=False)
plt.tight_layout()
fig2.savefig(os.path.join(output_path, "can_fairy_fill_level_trend.pdf"), dpi=300, bbox_inches="tight")
fig2.savefig(os.path.join(output_path, "can_fairy_fill_level_trend.png"), dpi=300, bbox_inches="tight")
plt.close()


# ── 11. PRE-TREND TESTS ──────────────────────────────────────────────────
pre_df = df_analysis[df_analysis["post"] == 0].copy()

# Regression-based pre-trend test
pretrend = smf.ols(
    "fill_level ~ treated * week", data=pre_df
).fit(cov_type="cluster", cov_kwds={"groups": pre_df["addr_clean"]})
print("\nPre-trend test (fill level):")
print(pretrend.summary())

# Balance t-tests
print("\nPre-period balance tests:")
for outcome in ["fill_level", "participated", "contaminated"]:
    grp0 = pre_df[pre_df["treated"] == 0][outcome].dropna()
    grp1 = pre_df[pre_df["treated"] == 1][outcome].dropna()
    t, p = stats.ttest_ind(grp0, grp1)
    print(f"  {outcome:<20} t={t:.4f}  p={p:.4f}")

print(f"\nAll outputs saved to: {output_path}")