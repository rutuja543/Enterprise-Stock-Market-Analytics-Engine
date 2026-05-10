CREATE DATABASE stock_market_analytics;
USE stock_market_analytics;
CREATE TABLE stocks (
    stock_id INT PRIMARY KEY AUTO_INCREMENT,
    symbol VARCHAR(10) UNIQUE NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(50),
    market_cap BIGINT
);
CREATE TABLE investors (
    investor_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    city VARCHAR(50),
    join_date DATE
);
CREATE TABLE stock_prices (
    price_id INT PRIMARY KEY AUTO_INCREMENT,
    stock_id INT,
    trade_date DATE,
    open_price DECIMAL(10,2),
    close_price DECIMAL(10,2),
    high_price DECIMAL(10,2),
    low_price DECIMAL(10,2),
    volume BIGINT,

    FOREIGN KEY (stock_id)
    REFERENCES stocks(stock_id)
    ON DELETE CASCADE
);
CREATE TABLE portfolio (
    portfolio_id INT PRIMARY KEY AUTO_INCREMENT,
    investor_id INT,
    stock_id INT,
    quantity INT,
    purchase_price DECIMAL(10,2),
    purchase_date DATE,

    FOREIGN KEY (investor_id)
    REFERENCES investors(investor_id)
    ON DELETE CASCADE,

    FOREIGN KEY (stock_id)
    REFERENCES stocks(stock_id)
    ON DELETE CASCADE
);
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    investor_id INT,
    stock_id INT,
    transaction_type VARCHAR(10),
    quantity INT,
    transaction_price DECIMAL(10,2),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (investor_id)
    REFERENCES investors(investor_id),

    FOREIGN KEY (stock_id)
    REFERENCES stocks(stock_id)
);
INSERT INTO stocks(symbol, company_name, sector, market_cap)
VALUES
('AAPL', 'Apple Inc', 'Technology', 3000000000),
('GOOGL', 'Alphabet Inc', 'Technology', 2500000000),
('TSLA', 'Tesla Inc', 'Automobile', 1500000000),
('AMZN', 'Amazon', 'E-Commerce', 2000000000),
('MSFT', 'Microsoft', 'Technology', 2800000000);

INSERT INTO investors(full_name, email, city, join_date)
VALUES
('Rahul Sharma', 'rahul@gmail.com', 'Mumbai', '2025-01-10'),
('Sneha Patil', 'sneha@gmail.com', 'Pune', '2025-02-11'),
('Amit Joshi', 'amit@gmail.com', 'Nagpur', '2025-03-15');

INSERT INTO stock_prices
(stock_id, trade_date, open_price, close_price, high_price, low_price, volume)
VALUES
(1, '2026-01-01', 180, 185, 188, 178, 1000000),
(2, '2026-01-01', 2700, 2725, 2750, 2680, 500000),
(3, '2026-01-01', 700, 730, 740, 690, 1200000),
(4, '2026-01-01', 3200, 3250, 3270, 3180, 600000),
(5, '2026-01-01', 350, 360, 365, 345, 900000);

INSERT INTO portfolio
(investor_id, stock_id, quantity, purchase_price, purchase_date)
VALUES
(1, 1, 20, 170, '2026-01-01'),
(1, 3, 15, 650, '2026-01-02'),
(2, 2, 5, 2600, '2026-01-03'),
(3, 5, 25, 300, '2026-01-05');

INSERT INTO transactions
(investor_id, stock_id, transaction_type, quantity, transaction_price)
VALUES
(1, 1, 'BUY', 20, 170),
(1, 3, 'BUY', 15, 650),
(2, 2, 'BUY', 5, 2600),
(3, 5, 'BUY', 25, 300);

SELECT * FROM stocks;
SELECT
    s.company_name,
    SUM(sp.volume) AS total_volume
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id
GROUP BY s.company_name
ORDER BY total_volume DESC
LIMIT 3;
SELECT
    s.company_name,
    sp.trade_date,
    (sp.close_price - sp.open_price) AS daily_profit
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id;
SELECT *
FROM stocks
WHERE sector = 'Technology';
SELECT
    i.full_name,
    s.company_name,
    p.quantity,
    p.purchase_price,
    sp.close_price,
    (p.quantity * sp.close_price) AS current_value,
    ((sp.close_price - p.purchase_price) * p.quantity) AS profit_loss
FROM portfolio p
JOIN investors i
ON p.investor_id = i.investor_id
JOIN stocks s
ON p.stock_id = s.stock_id
JOIN stock_prices sp
ON p.stock_id = sp.stock_id;
SELECT
    s.company_name,
    AVG(sp.close_price) AS average_price
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id
GROUP BY s.company_name;
SELECT
    s.company_name,
    MAX(sp.close_price - sp.open_price) AS highest_gain
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id
GROUP BY s.company_name
ORDER BY highest_gain DESC
LIMIT 1;
SELECT
    s.company_name,
    sp.close_price,
    RANK() OVER(ORDER BY sp.close_price DESC) AS stock_rank
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id;
SELECT
    company_name,
    sector,
    ROW_NUMBER() OVER(PARTITION BY sector ORDER BY market_cap DESC) AS row_num
FROM stocks;
SELECT
    stock_id,
    trade_date,
    close_price,
    AVG(close_price)
    OVER(
        PARTITION BY stock_id
        ORDER BY trade_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_average
FROM stock_prices;
CREATE VIEW market_summary AS
SELECT
    s.company_name,
    s.sector,
    sp.trade_date,
    sp.close_price,
    sp.volume
FROM stocks s
JOIN stock_prices sp
ON s.stock_id = sp.stock_id;
SELECT * FROM market_summary;

DELIMITER //

CREATE PROCEDURE GetStockDetails(IN stockSymbol VARCHAR(10))
BEGIN
    SELECT *
    FROM stocks
    WHERE symbol = stockSymbol;
END //

DELIMITER ;
CALL GetStockDetails('AAPL');
CREATE TABLE transaction_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id INT,
    action_type VARCHAR(20),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DELIMITER //

CREATE TRIGGER after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO transaction_audit
    (transaction_id, action_type)
    VALUES
    (NEW.transaction_id, 'INSERT');
END //

DELIMITER ;
CREATE INDEX idx_stock_symbol
ON stocks(symbol);
CREATE INDEX idx_trade_date
ON stock_prices(trade_date);
SELECT
    i.full_name,
    SUM(p.quantity * sp.close_price) AS total_portfolio_value
FROM portfolio p
JOIN investors i
ON p.investor_id = i.investor_id
JOIN stock_prices sp
ON p.stock_id = sp.stock_id
GROUP BY i.full_name
ORDER BY total_portfolio_value DESC;
SELECT
    s.sector,
    AVG(sp.close_price - sp.open_price) AS avg_growth
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id
GROUP BY s.sector;
SELECT
    s.company_name,
    AVG(sp.high_price - sp.low_price) AS volatility
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id
GROUP BY s.company_name
ORDER BY volatility DESC
LIMIT 1;
CREATE TABLE realtime_stock_prices (
    realtime_id INT PRIMARY KEY AUTO_INCREMENT,
    stock_id INT,
    current_price DECIMAL(10,2),
    price_change DECIMAL(10,2),
    percentage_change DECIMAL(10,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (stock_id)
    REFERENCES stocks(stock_id)
    ON DELETE CASCADE
);
CREATE TABLE watchlist (
    watchlist_id INT PRIMARY KEY AUTO_INCREMENT,
    investor_id INT,
    stock_id INT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (investor_id)
    REFERENCES investors(investor_id),

    FOREIGN KEY (stock_id)
    REFERENCES stocks(stock_id)
);
CREATE TABLE dividends (
    dividend_id INT PRIMARY KEY AUTO_INCREMENT,
    stock_id INT,
    dividend_amount DECIMAL(10,2),
    dividend_date DATE,

    FOREIGN KEY (stock_id)
    REFERENCES stocks(stock_id)
    ON DELETE CASCADE
);
CREATE TABLE audit_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    action_performed VARCHAR(20),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DELIMITER //

CREATE PROCEDURE CalculatePortfolioValue(IN investorId INT)
BEGIN
    SELECT
        i.full_name,
        SUM(p.quantity * sp.close_price) AS portfolio_value
    FROM portfolio p
    JOIN investors i
    ON p.investor_id = i.investor_id
    JOIN stock_prices sp
    ON p.stock_id = sp.stock_id
    WHERE i.investor_id = investorId
    GROUP BY i.full_name;
END //

DELIMITER ;
SELECT
    s.company_name,
    AVG(sp.high_price - sp.low_price) AS volatility,
    
    CASE
        WHEN AVG(sp.high_price - sp.low_price) > 100 THEN 'HIGH RISK'
        WHEN AVG(sp.high_price - sp.low_price) > 50 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_level

FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id

GROUP BY s.company_name
ORDER BY volatility DESC;
SELECT
    stock_id,
    trade_date,
    volume,

    AVG(volume)
    OVER(
        PARTITION BY stock_id
    ) AS avg_volume,

    CASE
        WHEN volume >
             AVG(volume)
             OVER(PARTITION BY stock_id) * 2
        THEN 'UNUSUAL ACTIVITY'

        ELSE 'NORMAL'
    END AS activity_status

FROM stock_prices;
SELECT
    i.full_name,

    SUM(p.quantity * sp.close_price)
    AS portfolio_value,

    DENSE_RANK()
    OVER(
        ORDER BY
        SUM(p.quantity * sp.close_price) DESC
    ) AS investor_rank

FROM portfolio p

JOIN investors i
ON p.investor_id = i.investor_id

JOIN stock_prices sp
ON p.stock_id = sp.stock_id

GROUP BY i.full_name;
SELECT
    MONTH(trade_date) AS month_number,

    AVG(close_price) AS avg_market_price,

    SUM(volume) AS total_volume

FROM stock_prices

GROUP BY MONTH(trade_date)

ORDER BY month_number;
SELECT
    i.full_name,

    COUNT(DISTINCT p.stock_id)
    AS unique_stocks,

    CASE
        WHEN COUNT(DISTINCT p.stock_id) >= 5
        THEN 'WELL DIVERSIFIED'

        ELSE 'LOW DIVERSIFICATION'
    END AS diversification_status

FROM portfolio p

JOIN investors i
ON p.investor_id = i.investor_id

GROUP BY i.full_name;
CREATE INDEX idx_stock_trade
ON stock_prices(stock_id, trade_date);
CREATE INDEX idx_transaction_analysis
ON transactions(investor_id, stock_id);
SELECT
    s.company_name,
    SUM(sp.volume)
FROM stock_prices sp
JOIN stocks s
ON sp.stock_id = s.stock_id
GROUP BY s.company_name;
SELECT
    investor_id,
    COUNT(*) AS transaction_count,

    SUM(quantity * transaction_price)
    AS total_amount

FROM transactions

GROUP BY investor_id

HAVING COUNT(*) > 100
OR SUM(quantity * transaction_price) > 1000000;
CREATE VIEW executive_dashboard AS

SELECT
    s.company_name,
    s.sector,

    AVG(sp.close_price) AS avg_price,

    SUM(sp.volume) AS total_volume,

    MAX(sp.high_price) AS highest_price,

    MIN(sp.low_price) AS lowest_price

FROM stocks s

JOIN stock_prices sp
ON s.stock_id = sp.stock_id

GROUP BY s.company_name, s.sector;
INSERT INTO stocks(symbol, company_name, sector, market_cap)
VALUES
('NVDA', 'NVIDIA', 'Technology', 2200000000),
('META', 'Meta', 'Technology', 1800000000),
('NFLX', 'Netflix', 'Entertainment', 900000000),
('IBM', 'IBM', 'Technology', 850000000),
('AMD', 'AMD', 'Semiconductor', 1100000000),
('ORCL', 'Oracle', 'Technology', 950000000),
('SAP', 'SAP', 'Software', 750000000),
('INTC', 'Intel', 'Semiconductor', 980000000),
('UBER', 'Uber', 'Transportation', 650000000),
('ADBE', 'Adobe', 'Software', 890000000),
('PYPL', 'PayPal', 'FinTech', 780000000),
('CRM', 'Salesforce', 'Cloud Computing', 990000000),
('CSCO', 'Cisco', 'Networking', 860000000),
('QCOM', 'Qualcomm', 'Semiconductor', 920000000),
('SHOP', 'Shopify', 'E-Commerce', 710000000);

INSERT INTO investors(full_name, email, city, join_date)
VALUES
('Priya Deshmukh', 'priya@gmail.com', 'Mumbai', '2025-04-12'),
('Rohan Kulkarni', 'rohan@gmail.com', 'Pune', '2025-05-20'),
('Neha Verma', 'neha@gmail.com', 'Delhi', '2025-06-01'),
('Arjun Mehta', 'arjun@gmail.com', 'Bangalore', '2025-06-15'),
('Karan Shah', 'karan@gmail.com', 'Ahmedabad', '2025-07-10'),
('Pooja Nair', 'pooja@gmail.com', 'Chennai', '2025-07-21'),
('Vikram Singh', 'vikram@gmail.com', 'Jaipur', '2025-08-05'),
('Ananya Rao', 'ananya@gmail.com', 'Hyderabad', '2025-08-18'),
('Siddharth Jain', 'sid@gmail.com', 'Indore', '2025-09-01'),
('Meera Kapoor', 'meera@gmail.com', 'Kolkata', '2025-09-12');

INSERT INTO stocks(symbol, company_name, sector, market_cap)
VALUES
('NVDA', 'NVIDIA', 'Technology', 2200000000),
('META', 'Meta', 'Technology', 1800000000),
('NFLX', 'Netflix', 'Entertainment', 900000000),
('IBM', 'IBM', 'Technology', 850000000),
('AMD', 'AMD', 'Semiconductor', 1100000000),
('ORCL', 'Oracle', 'Technology', 950000000),
('SAP', 'SAP', 'Software', 750000000),
('INTC', 'Intel', 'Semiconductor', 980000000),
('UBER', 'Uber', 'Transportation', 650000000),
('ADBE', 'Adobe', 'Software', 890000000);
SELECT stock_id, symbol
FROM stocks;
INSERT INTO stock_prices
(stock_id, trade_date, open_price, close_price, high_price, low_price, volume)
VALUES
(6, '2026-01-02', 900, 950, 970, 890, 1500000),
(7, '2026-01-02', 320, 340, 350, 315, 850000),
(8, '2026-01-02', 140, 150, 155, 138, 780000),
(9, '2026-01-02', 420, 430, 440, 410, 920000),
(10, '2026-01-02', 500, 540, 550, 490, 1250000),
(11, '2026-01-02', 180, 190, 195, 175, 610000),
(12, '2026-01-02', 260, 275, 280, 255, 700000),
(13, '2026-01-02', 75, 82, 85, 72, 990000),
(14, '2026-01-02', 145, 155, 160, 140, 890000),
(15, '2026-01-02', 600, 630, 640, 590, 1350000);
SELECT
    COUNT(DISTINCT investor_id) AS total_investors,

    COUNT(DISTINCT stock_id) AS total_stocks,

    SUM(quantity * transaction_price) AS total_market_value

FROM transactions;
SELECT
    s.company_name,

    AVG(sp.close_price - sp.open_price)
    AS avg_gain

FROM stock_prices sp

JOIN stocks s
ON sp.stock_id = s.stock_id

GROUP BY s.company_name

ORDER BY avg_gain DESC

LIMIT 5;