-- =============================================================================
-- SuperMarket Q1 Retail Operations, Basket Economics & Customer Experience Audit
-- SQLite Analytical Warehouse Schema & Executive Views
-- Database: SuperMarket_Analysis.db
-- Scope: 1,000 Transactions | Q1 2019 (Jan 1 – Mar 30, 2019) | 3 Branches
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CORE TABLES
-- -----------------------------------------------------------------------------

-- Raw ingested dataset (1,000 rows x 17 columns)
CREATE TABLE IF NOT EXISTS "raw_invoices" (
    "Invoice ID" TEXT,
    "Branch" TEXT,
    "City" TEXT,
    "Customer type" TEXT,
    "Gender" TEXT,
    "Product line" TEXT,
    "Unit price" REAL,
    "Quantity" INTEGER,
    "Tax 5%" REAL,
    "Sales" REAL,
    "Date" TEXT,
    "Time" TEXT,
    "Payment" TEXT,
    "cogs" REAL,
    "gross margin percentage" REAL,
    "gross income" REAL,
    "Rating" REAL
);

-- Cleaned & feature-engineered analytical dataset (1,000 rows x 37 columns in DB)
CREATE TABLE IF NOT EXISTS "clean_invoices" (
    "Invoice ID" TEXT,
    "Branch" TEXT,
    "City" TEXT,
    "Customer type" TEXT,
    "Gender" TEXT,
    "Product line" TEXT,
    "Unit price" REAL,
    "Quantity" INTEGER,
    "Tax 5%" REAL,
    "Sales" REAL,
    "Date" TEXT,
    "Time" TEXT,
    "Payment" TEXT,
    "cogs" REAL,
    "gross margin percentage" REAL,
    "gross income" REAL,
    "Rating" REAL,
    "Legacy_City" TEXT,
    "Order Date" TEXT,
    "Order Year" INTEGER,
    "Order Month Num" INTEGER,
    "Order Month" TEXT,
    "Day of Month" INTEGER,
    "Day of Week" TEXT,
    "Day Type" TEXT,
    "Is Weekend" TEXT,
    "Hour 24" INTEGER,
    "Time 24H" TEXT,
    "Store Shift" TEXT,
    "Net Sales (Excl Tax)" REAL,
    "Gross Profit" REAL,
    "Gross Margin %" REAL,
    "Basket Size Tier" TEXT,
    "Ticket Value Tier" TEXT,
    "Unit Price Tier" TEXT,
    "Satisfaction Tier" TEXT,
    "Customer Persona" TEXT
);

-- -----------------------------------------------------------------------------
-- 2. ANALYTICAL VIEWS FOR BI & EXECUTIVE REPORTING
-- -----------------------------------------------------------------------------

-- View 1: Branch-Level Executive KPIs & NPS Sentiment Share
DROP VIEW IF EXISTS vw_branch_executive_kpis;
CREATE VIEW vw_branch_executive_kpis AS
SELECT 
    "Branch",
    "City",
    COUNT("Invoice ID") AS total_invoices,
    SUM("Quantity") AS total_units_sold,
    ROUND(SUM("Sales"), 2) AS total_revenue,
    ROUND(SUM("cogs"), 2) AS total_cogs,
    ROUND(SUM("gross income"), 2) AS total_gross_profit,
    ROUND(AVG("Sales"), 2) AS avg_ticket_size,
    ROUND(AVG("Quantity"), 2) AS avg_basket_units,
    ROUND(AVG("Rating"), 2) AS avg_customer_rating,
    ROUND(SUM(CASE WHEN "Satisfaction Tier" = 'Promoter (8.5-10.0)' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS promoter_share_pct,
    ROUND(SUM(CASE WHEN "Satisfaction Tier" = 'Detractor (4.0-6.4)' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS detractor_share_pct
FROM clean_invoices
GROUP BY "Branch", "City"
ORDER BY total_revenue DESC;

-- View 2: Product Line Performance & Gender Revenue Share
DROP VIEW IF EXISTS vw_product_line_performance;
CREATE VIEW vw_product_line_performance AS
SELECT 
    "Product line",
    COUNT("Invoice ID") AS transactions,
    SUM("Quantity") AS units_sold,
    ROUND(AVG("Unit price"), 2) AS avg_unit_price,
    ROUND(SUM("Sales"), 2) AS total_revenue,
    ROUND(SUM("gross income"), 2) AS total_gross_profit,
    ROUND(AVG("Sales"), 2) AS avg_ticket_size,
    ROUND(AVG("Rating"), 2) AS avg_rating,
    ROUND(SUM(CASE WHEN "Gender" = 'Female' THEN "Sales" ELSE 0 END) * 100.0 / SUM("Sales"), 2) AS female_revenue_share_pct
FROM clean_invoices
GROUP BY "Product line"
ORDER BY total_revenue DESC;

-- View 3: Branch x Product Line Revenue & Rating Matrix
DROP VIEW IF EXISTS vw_branch_product_matrix;
CREATE VIEW vw_branch_product_matrix AS
SELECT 
    "Branch",
    "Product line",
    COUNT("Invoice ID") AS transactions,
    SUM("Quantity") AS units_sold,
    ROUND(SUM("Sales"), 2) AS total_revenue,
    ROUND(SUM("gross income"), 2) AS gross_profit,
    ROUND(AVG("Rating"), 2) AS avg_rating
FROM clean_invoices
GROUP BY "Branch", "Product line"
ORDER BY "Branch", total_revenue DESC;

-- View 4: Customer Persona Economics (Membership x Gender)
DROP VIEW IF EXISTS vw_customer_persona_analytics;
CREATE VIEW vw_customer_persona_analytics AS
SELECT 
    "Customer Persona",
    "Customer type",
    "Gender",
    COUNT("Invoice ID") AS transactions,
    SUM("Quantity") AS total_units,
    ROUND(SUM("Sales"), 2) AS total_revenue,
    ROUND(SUM("gross income"), 2) AS total_gross_profit,
    ROUND(AVG("Sales"), 2) AS avg_ticket_size,
    ROUND(AVG("Rating"), 2) AS avg_rating
FROM clean_invoices
GROUP BY "Customer Persona", "Customer type", "Gender"
ORDER BY total_revenue DESC;

-- View 5: Hourly Footfall & Store Shift Operations
DROP VIEW IF EXISTS vw_hourly_shift_operations;
CREATE VIEW vw_hourly_shift_operations AS
SELECT 
    "Store Shift",
    "Hour 24" AS hour_of_day,
    COUNT("Invoice ID") AS transactions,
    ROUND(SUM("Sales"), 2) AS total_revenue,
    ROUND(AVG("Sales"), 2) AS avg_ticket_size,
    ROUND(AVG("Quantity"), 2) AS avg_units_per_basket,
    ROUND(AVG("Rating"), 2) AS avg_rating
FROM clean_invoices
GROUP BY "Store Shift", "Hour 24"
ORDER BY "Hour 24" ASC;

-- View 6: Payment Channel Preferences by Branch
DROP VIEW IF EXISTS vw_payment_channel_insights;
CREATE VIEW vw_payment_channel_insights AS
SELECT 
    "Payment",
    "Branch",
    COUNT("Invoice ID") AS transactions,
    ROUND(SUM("Sales"), 2) AS total_revenue,
    ROUND(AVG("Sales"), 2) AS avg_ticket_size,
    ROUND(AVG("Rating"), 2) AS avg_rating
FROM clean_invoices
GROUP BY "Payment", "Branch"
ORDER BY "Payment", total_revenue DESC;
