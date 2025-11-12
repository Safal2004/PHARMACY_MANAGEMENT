CREATE DATABASE IF NOT EXISTS PharmacyManagement;
USE PharmacyManagement;

-- DROP old objects if present and reset
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoice_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS prescription_items;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS inventory_batches;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS medicines;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS customers;
SET FOREIGN_KEY_CHECKS=1;

-- 1️⃣ Customers
CREATE TABLE customers (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  phone VARCHAR(20),
  city VARCHAR(60),
  join_date DATE
) ENGINE=InnoDB;

-- 2️⃣ Doctors
CREATE TABLE doctors (
  doctor_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  specialization VARCHAR(80),
  clinic VARCHAR(120),
  city VARCHAR(60)
) ENGINE=InnoDB;

-- 3️⃣ Suppliers
CREATE TABLE suppliers (
  supplier_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120),
  city VARCHAR(60),
  phone VARCHAR(30)
) ENGINE=InnoDB;

-- 4️⃣ Medicines (master)
CREATE TABLE medicines (
  medicine_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(150),
  brand VARCHAR(80),
  category VARCHAR(60),
  unit_price DECIMAL(10,2),
  prescription_required TINYINT(1) DEFAULT 0
) ENGINE=InnoDB;

-- 5️⃣ Purchases (incoming orders from suppliers)
CREATE TABLE purchases (
  purchase_id INT PRIMARY KEY AUTO_INCREMENT,
  supplier_id INT,
  purchase_date DATE,
  total_amount DECIMAL(12,2),
  CONSTRAINT fk_purchases_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
) ENGINE=InnoDB;

-- 6️⃣ Inventory batches (batch-level expiry and qty)
CREATE TABLE inventory_batches (
  batch_id INT PRIMARY KEY AUTO_INCREMENT,
  medicine_id INT,
  batch_no VARCHAR(60),
  expiry DATE,
  qty_received INT,
  qty_available INT,
  purchase_id INT,
  CONSTRAINT fk_batches_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id),
  CONSTRAINT fk_batches_purchase FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id)
) ENGINE=InnoDB;

-- 7️⃣ Prescriptions (issued by doctors)
CREATE TABLE prescriptions (
  prescription_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT,
  doctor_id INT,
  prescription_date DATE,
  diagnosis VARCHAR(200),
  CONSTRAINT fk_prescriptions_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_prescriptions_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
) ENGINE=InnoDB;

-- 8️⃣ Prescription items (what was prescribed)
CREATE TABLE prescription_items (
  prescription_item_id INT PRIMARY KEY AUTO_INCREMENT,
  prescription_id INT,
  medicine_id INT,
  dosage VARCHAR(60),
  days INT,
  CONSTRAINT fk_pi_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id),
  CONSTRAINT fk_pi_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
) ENGINE=InnoDB;

-- 9️⃣ Invoices (sales to customers)
CREATE TABLE invoices (
  invoice_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT,
  invoice_date DATE,
  prescription_id INT,
  total_amount DECIMAL(12,2),
  CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_invoices_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
) ENGINE=InnoDB;

-- 🔟 Invoice items (line items sold, linked to batch)
CREATE TABLE invoice_items (
  invoice_item_id INT PRIMARY KEY AUTO_INCREMENT,
  invoice_id INT,
  medicine_id INT,
  batch_id INT,
  qty INT,
  unit_price DECIMAL(10,2),
  line_total DECIMAL(12,2),
  CONSTRAINT fk_ii_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
  CONSTRAINT fk_ii_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id),
  CONSTRAINT fk_ii_batch FOREIGN KEY (batch_id) REFERENCES inventory_batches(batch_id)
) ENGINE=InnoDB;

-- 11️⃣ Payments
CREATE TABLE payments (
  payment_id INT PRIMARY KEY AUTO_INCREMENT,
  invoice_id INT,
  payment_date DATE,
  method VARCHAR(40),
  amount DECIMAL(12,2),
  CONSTRAINT fk_pay_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
) ENGINE=InnoDB;

-- Indexes for common joins
CREATE INDEX idx_purchases_supplier ON purchases(supplier_id);
CREATE INDEX idx_batches_med ON inventory_batches(medicine_id);
CREATE INDEX idx_batches_purchase ON inventory_batches(purchase_id);
CREATE INDEX idx_prescriptions_customer ON prescriptions(customer_id);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id);
CREATE INDEX idx_pi_prescription ON prescription_items(prescription_id);
CREATE INDEX idx_pi_medicine ON prescription_items(medicine_id);
CREATE INDEX idx_invoices_customer ON invoices(customer_id);
CREATE INDEX idx_invoices_prescription ON invoices(prescription_id);
CREATE INDEX idx_ii_invoice ON invoice_items(invoice_id);
CREATE INDEX idx_ii_medicine ON invoice_items(medicine_id);
CREATE INDEX idx_ii_batch ON invoice_items(batch_id);
CREATE INDEX idx_pay_invoice ON payments(invoice_id);

-- Seed data: customers
INSERT INTO customers (name, phone, city, join_date) VALUES
('Aman Verma','9876543210','Nagpur','2025-01-04'),
('Neha Singh','9876500001','Pune','2025-02-15'),
('Rahul Patil','9876500002','Mumbai','2025-03-20'),
('Pooja Rao','9876500003','Nagpur','2025-04-12'),
('Kunal Shah','9876500004','Pune','2025-05-02'),
('Sara Khan','9876500005','Mumbai','2025-06-10'),
('Vikram Joshi','9876500006','Nagpur','2025-07-01'),
('Isha Kulkarni','9876500007','Pune','2025-07-20');

-- Seed data: doctors
INSERT INTO doctors (name, specialization, clinic, city) VALUES
('Dr. Mehta','General Physician','City Clinic','Nagpur'),
('Dr. Nair','Cardiologist','Heart Care','Pune'),
('Dr. Sharma','Pediatrician','Child Care','Mumbai'),
('Dr. Iyer','Dermatologist','Skin Plus','Nagpur');

-- Seed data: suppliers
INSERT INTO suppliers (name, city, phone) VALUES
('Sun Pharma Dist','Mumbai','022-111111'),
('Cipla Wholesale','Pune','020-222222'),
('Lupin Supply','Nagpur','0712-333333');

-- Seed data: medicines
INSERT INTO medicines (name, brand, category, unit_price, prescription_required) VALUES
('Paracetamol 500mg','Cipla','Analgesic',2.50,0),
('Amoxicillin 250mg','Sun Pharma','Antibiotic',6.00,1),
('Cetirizine 10mg','Lupin','Antihistamine',3.00,0),
('Pantoprazole 40mg','Sun Pharma','PPI',7.50,0),
('Atorvastatin 10mg','Cipla','Statin',9.00,1),
('Metformin 500mg','Lupin','Antidiabetic',4.50,1),
('Azithromycin 500mg','Cipla','Antibiotic',12.00,1),
('ORS Sachet','Lupin','Electrolyte',5.00,0),
('Ibuprofen 400mg','Sun Pharma','NSAID',4.00,0),
('Insulin 10ml','Sun Pharma','Hormone',120.00,1);

-- Seed data: purchases
INSERT INTO purchases (supplier_id, purchase_date, total_amount) VALUES
(1,'2025-01-10',1500.00),
(2,'2025-02-05',1200.00),
(3,'2025-03-12',1800.00),
(1,'2025-06-18',2200.00);

-- Seed data: inventory_batches
INSERT INTO inventory_batches (medicine_id, batch_no, expiry, qty_received, qty_available, purchase_id) VALUES
(1,'B1','2026-01-31',500,500,1),
(2,'B2','2025-12-31',300,300,1),
(3,'B3','2026-03-31',400,400,2),
(4,'B4','2026-02-28',300,300,2),
(5,'B5','2026-06-30',200,200,3),
(6,'B6','2026-05-31',350,350,3),
(7,'B7','2025-12-15',250,250,3),
(8,'B8','2026-08-31',500,500,4),
(9,'B9','2026-04-30',300,300,4),
(10,'B10','2025-11-30',100,100,4);

-- Seed data: prescriptions
INSERT INTO prescriptions (customer_id, doctor_id, prescription_date, diagnosis) VALUES
(1,1,'2025-07-10','Fever'),
(2,2,'2025-07-12','Cholesterol'),
(3,3,'2025-07-13','Allergy'),
(4,4,'2025-07-14','Acidity'),
(5,1,'2025-07-15','Diabetes'),
(6,2,'2025-07-16','Infection'),
(7,3,'2025-07-18','Dehydration'),
(8,4,'2025-07-19','Infection');

-- Seed data: prescription_items
INSERT INTO prescription_items (prescription_id, medicine_id, dosage, days) VALUES
(1,1,'1-0-1',3),
(1,3,'0-0-1',5),
(2,5,'1-0-0',30),
(3,3,'1-0-0',10),
(4,4,'1-0-0',7),
(5,6,'1-1-1',60),
(6,7,'1-0-0',3),
(7,8,'when needed',2),
(8,2,'1-0-1',5);

-- Seed data: invoices (initially zeros for total_amount, will compute below)
INSERT INTO invoices (customer_id, invoice_date, prescription_id, total_amount) VALUES
(1,'2025-07-10',1,0.00),
(2,'2025-07-12',2,0.00),
(3,'2025-07-13',3,0.00),
(4,'2025-07-14',4,0.00),
(5,'2025-07-15',5,0.00),
(6,'2025-07-16',6,0.00),
(7,'2025-07-18',7,0.00),
(8,'2025-07-19',8,0.00);

-- Seed data: invoice_items (linking to batches)
INSERT INTO invoice_items (invoice_id, medicine_id, batch_id, qty, unit_price, line_total) VALUES
(1,1,1,6,2.50,15.00),
(1,3,3,5,3.00,15.00),
(2,5,5,30,9.00,270.00),
(3,3,3,10,3.00,30.00),
(4,4,4,7,7.50,52.50),
(5,6,6,60,4.50,270.00),
(6,7,7,3,12.00,36.00),
(7,8,8,2,5.00,10.00),
(8,2,2,10,6.00,60.00);

-- Seed data: payments
INSERT INTO payments (invoice_id, payment_date, method, amount) VALUES
(1,'2025-07-10','UPI',30.00),
(2,'2025-07-12','Card',270.00),
(3,'2025-07-13','Cash',30.00),
(4,'2025-07-14','UPI',52.50),
(5,'2025-07-15','Card',270.00),
(6,'2025-07-16','Cash',36.00),
(7,'2025-07-18','UPI',10.00),
(8,'2025-07-19','UPI',60.00);

-- Update qty_available in inventory_batches based on sales (invoice_items)
UPDATE inventory_batches b
LEFT JOIN (
  SELECT batch_id, SUM(qty) AS sold
  FROM invoice_items
  GROUP BY batch_id
) s ON s.batch_id = b.batch_id
SET b.qty_available = b.qty_received - COALESCE(s.sold,0);

-- Update invoice totals
UPDATE invoices i
JOIN (
  SELECT invoice_id, SUM(line_total) AS tot
  FROM invoice_items
  GROUP BY invoice_id
) t ON t.invoice_id = i.invoice_id
SET i.total_amount = t.tot;

-- Quick checks
SELECT * FROM customers;
SELECT * FROM doctors;
SELECT * FROM suppliers;
SELECT * FROM medicines;
SELECT * FROM purchases;
SELECT * FROM inventory_batches;
SELECT * FROM prescriptions;
SELECT * FROM prescription_items;
SELECT * FROM invoices;
SELECT * FROM invoice_items;
SELECT * FROM payments;




-- Q01 Top-selling medicines by quantity
WITH x AS (
  SELECT medicine_id, SUM(qty) AS total_qty
  FROM invoice_items
  GROUP BY medicine_id
)
SELECT m.medicine_id, m.name, x.total_qty
FROM x JOIN medicines m USING(medicine_id)
ORDER BY x.total_qty DESC, m.name
LIMIT 5;

-- Q02 Revenue by category
SELECT m.category, ROUND(SUM(ii.line_total),2) AS revenue
FROM invoice_items ii
JOIN medicines m ON m.medicine_id = ii.medicine_id
GROUP BY m.category
ORDER BY revenue DESC;

-- Q03 Customers with prescriptions but no purchase on the same day
SELECT c.customer_id, c.name, p.prescription_date
FROM prescriptions p
JOIN customers c ON c.customer_id = p.customer_id
WHERE NOT EXISTS (
  SELECT 1 FROM invoices i
  WHERE i.customer_id = p.customer_id
    AND i.prescription_id = p.prescription_id
    AND i.invoice_date = p.prescription_date
);

-- Q04 Expiring batches within 60 days from '2025-11-12'
SELECT b.batch_id, m.name, b.batch_no, b.expiry, b.qty_available
FROM inventory_batches b
JOIN medicines m ON m.medicine_id = b.medicine_id
WHERE '2025-11-12' >= DATE_SUB(b.expiry, INTERVAL 60 DAY)
ORDER BY b.expiry;

-- Average invoice value and customer ranking
WITH cust_sales AS (
  SELECT i.customer_id, SUM(i.total_amount) AS total_spent, COUNT(*) AS invoices_count
  FROM invoices i
  GROUP BY i.customer_id
)
SELECT c.customer_id, c.name, cs.total_spent, cs.invoices_count,
       (SELECT ROUND(AVG(total_amount),2) FROM invoices) AS avg_invoice_all,
       RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
FROM cust_sales cs
JOIN customers c ON c.customer_id = cs.customer_id
ORDER BY spend_rank;

-- Q06 Prescription-only medicines sold
SELECT m.name, SUM(ii.qty) AS qty_sold
FROM invoice_items ii
JOIN medicines m ON m.medicine_id = ii.medicine_id
WHERE m.prescription_required = 1
GROUP BY m.name
ORDER BY qty_sold DESC;

-- Q07 Stock valuation and low stock flag
SELECT m.medicine_id, m.name, COALESCE(SUM(b.qty_available),0) AS qty_avl,
       ROUND(COALESCE(SUM(b.qty_available),0)*m.unit_price,2) AS stock_value,
       CASE WHEN COALESCE(SUM(b.qty_available),0) < 50 THEN 'LOW' ELSE 'OK' END AS status
FROM medicines m
LEFT JOIN inventory_batches b ON b.medicine_id = m.medicine_id
GROUP BY m.medicine_id, m.name, m.unit_price
ORDER BY stock_value DESC;

-- Q08 Supplier performance by received vs sold
WITH sold AS (
  SELECT b.purchase_id, b.medicine_id, SUM(ii.qty) AS qty_sold
  FROM inventory_batches b
  LEFT JOIN invoice_items ii ON ii.batch_id = b.batch_id
  GROUP BY b.purchase_id, b.medicine_id
)
SELECT s.supplier_id, s.name,
       ROUND(SUM(b.qty_received),0) AS qty_received,
       ROUND(SUM(COALESCE(sold.qty_sold,0)),0) AS qty_sold
FROM purchases p
JOIN suppliers s ON s.supplier_id = p.supplier_id
JOIN inventory_batches b ON b.purchase_id = p.purchase_id
LEFT JOIN sold ON sold.purchase_id = b.purchase_id AND sold.medicine_id = b.medicine_id
GROUP BY s.supplier_id, s.name
ORDER BY qty_sold DESC;

-- Q09 Best-selling brands by revenue
SELECT m.brand, ROUND(SUM(ii.line_total),2) AS revenue
FROM invoice_items ii
JOIN medicines m ON m.medicine_id = ii.medicine_id
GROUP BY m.brand
ORDER BY revenue DESC;

-- Q10 Daily sales summary with 3-day moving average
WITH daily AS (
  SELECT invoice_date AS d, SUM(total_amount) AS sales
  FROM invoices
  GROUP BY invoice_date
)
SELECT d, sales,
       ROUND(AVG(sales) OVER (ORDER BY d ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS ma3
FROM daily
ORDER BY d;

-- Q11 Top doctor by prescriptions and revenue contribution
WITH pres AS (
  SELECT doctor_id, COUNT(*) AS pres_count
  FROM prescriptions
  GROUP BY doctor_id
),
rev AS (
  SELECT p.doctor_id, SUM(i.total_amount) AS revenue
  FROM invoices i
  JOIN prescriptions p ON p.prescription_id = i.prescription_id
  GROUP BY p.doctor_id
)
SELECT d.doctor_id, d.name, COALESCE(pres.pres_count,0) AS pres_count, COALESCE(rev.revenue,0) AS revenue
FROM doctors d
LEFT JOIN pres ON pres.doctor_id = d.doctor_id
LEFT JOIN rev ON rev.doctor_id = d.doctor_id
ORDER BY revenue DESC, pres_count DESC;

-- Q12 Customer basket size and distinct items
SELECT c.customer_id, c.name,
       ROUND(AVG(ii.qty),2) AS avg_qty_per_line,
       COUNT(DISTINCT ii.medicine_id) AS distinct_items
FROM customers c
JOIN invoices i ON i.customer_id = c.customer_id
JOIN invoice_items ii ON ii.invoice_id = i.invoice_id
GROUP BY c.customer_id, c.name
ORDER BY distinct_items DESC;

-- Q13 Medicines never sold
SELECT m.medicine_id, m.name
FROM medicines m
WHERE NOT EXISTS (
  SELECT 1 FROM invoice_items ii WHERE ii.medicine_id = m.medicine_id
)
ORDER BY m.medicine_id;

-- Q14 City-wise revenue split with percent
WITH city_rev AS (
  SELECT c.city, SUM(i.total_amount) AS revenue
  FROM invoices i
  JOIN customers c ON c.customer_id = i.customer_id
  GROUP BY c.city
),
total AS (
  SELECT SUM(revenue) AS t FROM city_rev
)
SELECT cr.city, ROUND(cr.revenue,2) AS revenue,
       ROUND(cr.revenue*100.0/(SELECT t FROM total),2) AS pct
FROM city_rev cr
ORDER BY revenue DESC;

-- Q15 Most frequent diagnosis and mapped medicine
SELECT p.diagnosis, m.name, COUNT(*) AS times_prescribed
FROM prescriptions pr
JOIN prescription_items pi ON pi.prescription_id = pr.prescription_id
JOIN medicines m ON m.medicine_id = pi.medicine_id
JOIN prescriptions p ON p.prescription_id = pr.prescription_id
GROUP BY p.diagnosis, m.name
ORDER BY times_prescribed DESC
LIMIT 5;

-- Q16 Outstanding balance per invoice
SELECT i.invoice_id, i.total_amount,
       COALESCE((SELECT SUM(amount) FROM payments p WHERE p.invoice_id = i.invoice_id),0) AS paid,
       ROUND(i.total_amount - COALESCE((SELECT SUM(amount) FROM payments p WHERE p.invoice_id = i.invoice_id),0),2) AS balance
FROM invoices i
ORDER BY balance DESC;

-- Q17 Price vs sold quantity dataset
SELECT m.medicine_id, m.name, m.unit_price,
       COALESCE((SELECT SUM(ii.qty) FROM invoice_items ii WHERE ii.medicine_id = m.medicine_id),0) AS qty_sold
FROM medicines m
ORDER BY qty_sold DESC;

-- Q18 Top 3 invoices by value with customer and doctor
SELECT i.invoice_id, c.name AS customer, d.name AS doctor, i.total_amount
FROM invoices i
LEFT JOIN customers c ON c.customer_id = i.customer_id
LEFT JOIN prescriptions p ON p.prescription_id = i.prescription_id
LEFT JOIN doctors d ON d.doctor_id = p.doctor_id
ORDER BY i.total_amount DESC
LIMIT 3;

-- Q19 Days-of-supply per medicine using available qty and average daily sales
WITH daily_sales AS (
  SELECT ii.medicine_id, i.invoice_date AS d, SUM(ii.qty) AS qty
  FROM invoice_items ii
  JOIN invoices i ON i.invoice_id = ii.invoice_id
  GROUP BY ii.medicine_id, i.invoice_date
),
avg_daily AS (
  SELECT medicine_id, AVG(qty) AS avg_qty_per_day
  FROM daily_sales
  GROUP BY medicine_id
),
stock AS (
  SELECT m.medicine_id, COALESCE(SUM(b.qty_available),0) AS qty_avl
  FROM medicines m
  LEFT JOIN inventory_batches b ON b.medicine_id = m.medicine_id
  GROUP BY m.medicine_id
)
SELECT m.medicine_id, m.name, s.qty_avl,
       ROUND(s.qty_avl/NULLIF(a.avg_qty_per_day,0),2) AS days_of_supply
FROM medicines m
LEFT JOIN stock s ON s.medicine_id = m.medicine_id
LEFT JOIN avg_daily a ON a.medicine_id = m.medicine_id
ORDER BY days_of_supply DESC;

-- Q20 Batches with negative or zero available quantity
SELECT batch_id, batch_no, qty_available
FROM inventory_batches
WHERE qty_available <= 0
ORDER BY qty_available ASC;

-- Q21 Customers buying without prescription-required items on that invoice
SELECT DISTINCT c.customer_id, c.name
FROM customers c
JOIN invoices i ON i.customer_id = c.customer_id
WHERE NOT EXISTS (
  SELECT 1
  FROM invoice_items ii
  JOIN medicines m ON m.medicine_id = ii.medicine_id
  WHERE ii.invoice_id = i.invoice_id AND m.prescription_required = 1
)
ORDER BY c.customer_id;