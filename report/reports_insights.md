# Quick-Commerce Retention Analysis — Insights Report

## 1. What this project does
This project analyzes user retention on a quick-commerce delivery app by grouping 
users into monthly signup cohorts and tracking how many of them continued placing 
orders in the months following signup. It also compares retention across signup 
channels and defines a churn rule for identifying inactive users.

## 2. Methodology
- Cohorts were grouped by month of signup using DATE_TRUNC. Weekly grouping was 
  tried first but abandoned — cohort sizes were too small (often under 15 users), 
  causing retention percentages to swing wildly from just one or two users' behavior.
- period_number (how many months after signup an order occurred) was calculated 
  using AGE() and EXTRACT(), not simple date subtraction — months have variable 
  day counts (28-31 days), so a fixed day-based division would have produced 
  incorrect period numbers.
- Churn was defined as: a user with no order placed within the 1 month leading up 
  to the most recent order date in the entire dataset.

## 3. Retention curve findings
The retention heatmap shows a triangular shape — earlier cohorts (e.g., March 2025) 
have data across many periods, while recent cohorts only show early periods, since 
they haven't had time to reach later months yet (right-censoring).
Within individual cohorts, retention percentage generally declines as period_number 
increases, though not perfectly smoothly — likely due to the underlying dataset's 
order timing being randomly distributed across a user's lifetime rather than 
following a realistic decay pattern.
[INSERT POWER BI HEATMAP SCREENSHOT HERE]

## 4. Channel comparison findings
Pooling users by signup channel (rather than splitting by month, which made sample 
sizes too small) gave reliable comparisons:
- Organic (341 users): started around 38% retention at period 0, declining fairly 
  steadily to single digits by period 8+.
- Paid_ad (217 users): started around 36% at period 0, peaked slightly higher 
  (~46%) at period 1, then declined similarly to organic by later periods.
Both channels show a genuine downward trend once pooled to large enough sample 
sizes — unlike the noisy month-level view.

## 5. Churn rate
[TBD — run: SELECT churn_status, COUNT(*) FROM (churn query) GROUP BY churn_status; 
 to get exact churned vs active counts and percentage]

## 6. Limitations
- Small sample sizes (weekly cohorts, or month+channel combined) produced 
  unreliable, noisy retention percentages — fixed by aggregating to larger buckets.
- Right-censoring: newer cohorts haven't existed long enough to show later-period 
  data, producing the heatmap's triangular shape.
- The underlying dataset was synthetically generated with order timing distributed 
  uniformly at random across each user's tenure, rather than a realistic decay 
  pattern — so some retention volatility reflects this rather than genuine user 
  behavior.