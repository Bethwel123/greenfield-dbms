-- Greenfield High School Store Database Schema
-- Simple, well-commented SQL file for MySQL (InnoDB)
-- Includes PKs, FKs, NOT NULL, UNIQUE, and examples of 1-1, 1-M, M-M
-- Run with: mysql -u user -p < school_store_schema.sql

-- Use a specific database
CREATE DATABASE IF NOT EXISTS greenfield_school_store;
USE greenfield_school_store;

-- -----------------------------
-- Categories (1-M to Products)
-- -----------------------------
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

-- -----------------------------
-- Products
-- -----------------------------
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  category_id INT NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  cost DECIMAL(10,2) DEFAULT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id)
    REFERENCES categories(category_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Suppliers
-- -----------------------------
CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  contact_name VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  UNIQUE KEY uq_supplier_name_email (name, email)
) ENGINE=InnoDB;

-- -----------------------------
-- Product-Suppliers (M-M)
-- -----------------------------
CREATE TABLE product_suppliers (
  product_id INT NOT NULL,
  supplier_id INT NOT NULL,
  supplier_sku VARCHAR(100),
  lead_time_days INT DEFAULT 0,
  PRIMARY KEY (product_id, supplier_id),
  CONSTRAINT fk_ps_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_ps_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Inventory (1-1-ish with product for stock tracking)
-- -----------------------------
CREATE TABLE inventory (
  product_id INT PRIMARY KEY,
  qty_on_hand INT NOT NULL DEFAULT 0,
  reorder_level INT NOT NULL DEFAULT 5,
  last_restock_at TIMESTAMP NULL,
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Customers
-- -----------------------------
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(30),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------
-- Employees (store staff)
-- -----------------------------
CREATE TABLE employees (
  employee_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  role VARCHAR(50),
  email VARCHAR(150) UNIQUE,
  hired_at DATE
) ENGINE=InnoDB;

-- -----------------------------
-- Orders (1-M to OrderItems)
-- -----------------------------
CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  employee_id INT, -- who processed the sale
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('pending','paid','cancelled','refunded') NOT NULL DEFAULT 'pending',
  total DECIMAL(12,2) GENERATED ALWAYS AS (
    COALESCE((SELECT SUM(oi.quantity * oi.unit_price) FROM order_items oi WHERE oi.order_id = orders.order_id),0)
  ) STORED,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_orders_employee FOREIGN KEY (employee_id)
    REFERENCES employees(employee_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Order Items (composite PK) - each row is one product in an order
-- -----------------------------
CREATE TABLE order_items (
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (order_id, product_id),
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_oi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Payments (1-1 with orders) - one payment per order
-- -----------------------------
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL UNIQUE, -- enforces 1-1: one payment per order
  paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('cash','card','mobile') NOT NULL,
  confirmation_code VARCHAR(100),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Sample indexes to speed queries
-- -----------------------------
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_inventory_qty ON inventory(qty_on_hand);

-- -----------------------------
-- Small sample data (optional)
-- -----------------------------
-- INSERT INTO categories (name, description) VALUES ('Stationery','Pens, notebooks'), ('Electronics','Calculators, headphones');
-- INSERT INTO products (sku, name, category_id, price, cost) VALUES ('PEN-001','Ballpoint Pen',1,0.50,0.10),('CALC-100','Scientific Calculator',2,15.00,9.00);
-- INSERT INTO suppliers (name, contact_name, phone, email) VALUES ('OfficeSupply Ltd','Alice','+254700000000','alice@office.sup');
-- INSERT INTO product_suppliers (product_id, supplier_id, supplier_sku, lead_time_days) VALUES (1,1,'OS-PEN-01',7);