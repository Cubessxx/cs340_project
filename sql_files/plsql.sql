/*
Group 73
Members: Gage Cox
         Brandon Connely
         Carlos Chirinos
*/

USE `sql3817488`;

-- Cleanup existing app objects before recreating.
DROP VIEW IF EXISTS v_browse_customers_page;
DROP VIEW IF EXISTS v_browse_orders_page;
DROP VIEW IF EXISTS v_browse_order_details_page;
DROP VIEW IF EXISTS v_browse_products_for_order_entry;
DROP VIEW IF EXISTS v_browse_customers_for_order_entry;
DROP VIEW IF EXISTS v_browse_employees_for_order_entry;
DROP VIEW IF EXISTS v_browse_products_page;
DROP VIEW IF EXISTS v_browse_product_types_page;
DROP VIEW IF EXISTS v_browse_product_types_for_product_entry;

DROP PROCEDURE IF EXISTS sp_delete_customer;
DROP PROCEDURE IF EXISTS sp_insert_customer;
DROP PROCEDURE IF EXISTS sp_select_one_customer;
DROP PROCEDURE IF EXISTS sp_update_customer;
DROP PROCEDURE IF EXISTS sp_delete_order;
DROP PROCEDURE IF EXISTS sp_insert_order;
DROP PROCEDURE IF EXISTS sp_insert_order_detail;
DROP PROCEDURE IF EXISTS sp_update_order_detail;
DROP PROCEDURE IF EXISTS sp_upsert_order_detail;
DROP PROCEDURE IF EXISTS sp_delete_product;
DROP PROCEDURE IF EXISTS sp_insert_product;
DROP PROCEDURE IF EXISTS sp_select_one_product;
DROP PROCEDURE IF EXISTS sp_update_product;
DROP PROCEDURE IF EXISTS sp_delete_product_type;
DROP PROCEDURE IF EXISTS sp_insert_product_type;
DROP PROCEDURE IF EXISTS sp_select_one_product_type;
DROP PROCEDURE IF EXISTS sp_update_product_type;
DROP PROCEDURE IF EXISTS sp_reset_database;

DELIMITER //

-- Resets the database schema and seed data to the default state defined in DDL.sql.
DROP PROCEDURE IF EXISTS sp_reset_database //
CREATE PROCEDURE sp_reset_database ()
BEGIN
    START TRANSACTION;

    SET FOREIGN_KEY_CHECKS = 0;

    DROP TABLE IF EXISTS EmployeeAnimals;
    DROP TABLE IF EXISTS OrderDetails;
    DROP TABLE IF EXISTS Animals;
    DROP TABLE IF EXISTS Orders;
    DROP TABLE IF EXISTS Products;
    DROP TABLE IF EXISTS ProductTypes;
    DROP TABLE IF EXISTS Employees;
    DROP TABLE IF EXISTS Customers;

    SET FOREIGN_KEY_CHECKS = 1;
    SET AUTOCOMMIT = 0;

    -- Customers Table
    -- Records information about customers who purchase products or animals from the store.
    CREATE TABLE Customers (
        customerID int NOT NULL AUTO_INCREMENT,
        firstName varchar(50) NOT NULL,
        lastName varchar(50) NOT NULL,
        email varchar(50) UNIQUE NOT NULL,
        phoneNumber varchar(20) UNIQUE NOT NULL,
        PRIMARY KEY (customerID)
    );

    -- Employees Table
    -- Represents a single employee, the transactions they make, and the animals they take care of
    CREATE TABLE Employees (
        employeeID int NOT NULL AUTO_INCREMENT,
        firstName varchar(50) NOT NULL,
        lastName varchar(50) NOT NULL,
        jobTitle varchar(100) NOT NULL,
        PRIMARY KEY (employeeID)
    );

    -- Orders Table
    -- Represents a transaction made by a customer. An order may include both products and animals of any quantity.
    CREATE TABLE Orders (
        orderID int NOT NULL AUTO_INCREMENT,
        orderDate date NOT NULL,
        orderTotal decimal(10,2) NOT NULL,
        customerID int,
        employeeID int,
        PRIMARY KEY (orderID),
        FOREIGN KEY (customerID) REFERENCES Customers(customerID) ON DELETE CASCADE,
        FOREIGN KEY (employeeID) REFERENCES Employees(employeeID) ON DELETE CASCADE
    );

    -- ProductTypes Table
    -- Definition table for product types to prevent redundancy.
    CREATE TABLE ProductTypes (
        productTypeCode varchar(50) NOT NULL,
        productTypeName varchar(50) NOT NULL,
        PRIMARY KEY (productTypeCode)
    );

    -- Products Table
    -- Represents non-living products sold in store.
    CREATE TABLE Products (
        productID int NOT NULL AUTO_INCREMENT,
        productName varchar(50) NOT NULL,
        productTypeCode varchar(50) NOT NULL,
        price decimal(10,2) NOT NULL,
        stock int NOT NULL,
        PRIMARY KEY (productID),
        FOREIGN KEY (productTypeCode) REFERENCES ProductTypes(productTypeCode)
    );

    -- Animals Table
    -- Represents a singular individual animal
    CREATE TABLE Animals (
        animalID int NOT NULL AUTO_INCREMENT,
        name varchar(50),
        species varchar(100) NOT NULL,
        age int NOT NULL,
        price decimal(10,2) NOT NULL,
        isAvailable tinyint(1) NOT NULL,
        orderID int,
        PRIMARY KEY (animalID),
        FOREIGN KEY (orderID) REFERENCES Orders(orderID) ON DELETE CASCADE
    );

    -- Intersection of Orders and Products
    CREATE TABLE OrderDetails (
        orderDetailsID int NOT NULL AUTO_INCREMENT,
        orderID int NOT NULL,
        productID int NOT NULL,
        quantity int NOT NULL,
        unitPrice decimal(10,2) NOT NULL,
        PRIMARY KEY (orderDetailsID),
        FOREIGN KEY (orderID) REFERENCES Orders(orderID) ON DELETE CASCADE,
        FOREIGN KEY (productID) REFERENCES Products(productID) ON DELETE CASCADE
    );

    -- Intersection of Animals and Employees
    CREATE TABLE EmployeeAnimals (
        animalDetailsID int NOT NULL AUTO_INCREMENT,
        animalID int NOT NULL,
        employeeID int NOT NULL,
        PRIMARY KEY (animalDetailsID),
        FOREIGN KEY (animalID) REFERENCES Animals(animalID) ON DELETE CASCADE,
        FOREIGN KEY (employeeID) REFERENCES Employees(employeeID) ON DELETE CASCADE
    );

    -- Customers
    INSERT INTO Customers (firstName, lastName, email, phoneNumber)
    VALUES ('Alex', 'Rivera', 'alex.rivera@email.com', '541-555-0101'),
           ('Jamie', 'Chen', 'jamie.chen@email.com', '541-555-0102'),
           ('Morgan', 'Patel', 'morgan.patel@email.com', '541-555-0103');

    -- ProductTypes
    INSERT INTO ProductTypes (productTypeCode, productTypeName)
    VALUES ('ENC', 'Enclosure'),
           ('LGT', 'Lighting'),
           ('FOD', 'Food');

    -- Products
    INSERT INTO Products (productName, productTypeCode, price, stock)
    VALUES ('40-Gallon Terrarium', 'ENC', 199.99, 10),
           ('Heat Lamp', 'LGT', 29.99, 25),
           ('Calcium Supplement', 'FOD', 9.99, 50);

    -- Employees
    INSERT INTO Employees (firstName, lastName, jobTitle)
    VALUES ('Taylor', 'Morgan', 'Store Manager'),
           ('Jordan', 'Lee', 'Animal Care Specialist'),
           ('Casey', 'Smith', 'Sales Associate');

    -- Orders
    INSERT INTO Orders (orderDate, orderTotal, customerID, employeeID)
    VALUES ('2026-01-15', 239.97, 1, 3),
           ('2026-01-18', 59.98, 2, 3),
           ('2026-01-20', 229.96, 1, 1);

    -- Animals
    INSERT INTO Animals (name, species, age, price, isAvailable, orderID)
    VALUES ('Lacey', 'Leopard Gecko', 2, 149.99, 0, 1),
           ('Spike', 'Bearded Dragon', 1, 199.99, 0, 3),
           ('Sly', 'Corn Snake', 3, 129.99, 1, NULL);

    -- OrderDetails
    INSERT INTO OrderDetails (orderID, productID, quantity, unitPrice)
    VALUES (1, 1, 1, 199.99),
           (1, 2, 1, 29.99),
           (1, 3, 1, 9.99),
           (2, 2, 2, 29.99),
           (3, 1, 1, 199.99),
           (3, 3, 3, 9.99);

    -- EmployeeAnimals
    INSERT INTO EmployeeAnimals (animalID, employeeID)
    VALUES (1, (SELECT employeeID FROM Employees WHERE jobTitle = 'Animal Care Specialist')),
           (2, (SELECT employeeID FROM Employees WHERE jobTitle = 'Animal Care Specialist')),
           (3, (SELECT employeeID FROM Employees WHERE jobTitle = 'Animal Care Specialist'));

    SET FOREIGN_KEY_CHECKS = 1;
    COMMIT;
END //

DELIMITER ;

/* 1. Home Page (NO SQL) */


/* 2. Customers Page */

-- Displays all customers with contact info and a computed column for how many orders each customer is associated with.
CREATE OR REPLACE VIEW v_browse_customers_page AS
SELECT Customers.customerID AS "Customer ID",
       Customers.firstName AS "First Name",
       Customers.lastName AS "Last Name",
       Customers.email AS "Email",
       Customers.phoneNumber AS "Phone Number",
       COUNT(Orders.orderID) AS "Active Orders"
FROM Customers
LEFT JOIN Orders
       ON Orders.customerID = Customers.customerID
GROUP BY Customers.customerID,
         Customers.firstName,
         Customers.lastName,
         Customers.email,
         Customers.phoneNumber
ORDER BY Customers.customerID;


DELIMITER //

-- Deletes a customer by the selected customerID from the browse customers page.
DROP PROCEDURE IF EXISTS sp_delete_customer //
CREATE PROCEDURE sp_delete_customer (
    IN customerID_selected_from_browse_customers_page INT
)
BEGIN
    DELETE FROM Customers
    WHERE Customers.customerID = customerID_selected_from_browse_customers_page;
END //

-- Inserts a new customer using the provided first name, last name, email, and phone number inputs.
DROP PROCEDURE IF EXISTS sp_insert_customer //
CREATE PROCEDURE sp_insert_customer (
    IN firstNameInput   VARCHAR(255),
    IN lastNameInput    VARCHAR(255),
    IN emailInput       VARCHAR(255),
    IN phoneNumberInput VARCHAR(50)
)
BEGIN
    INSERT INTO Customers (firstName, lastName, email, phoneNumber)
    VALUES (firstNameInput, lastNameInput, emailInput, phoneNumberInput);
END //

-- Selects one customers details by the selected customerID from the browse customers page.
DROP PROCEDURE IF EXISTS sp_select_one_customer //
CREATE PROCEDURE sp_select_one_customer (
    IN customerID_selected_from_browse_customers_page INT
)
BEGIN
    SELECT Customers.customerID AS "Customer ID",
           Customers.firstName AS "First Name",
           Customers.lastName AS "Last Name",
           Customers.email AS "Email",
           Customers.phoneNumber AS "Phone Number"
    FROM Customers
    WHERE Customers.customerID = customerID_selected_from_browse_customers_page;
END //

-- Updates a customers email and phone number using the provided inputs for the specified customerID from the update form.
DROP PROCEDURE IF EXISTS sp_update_customer //
CREATE PROCEDURE sp_update_customer (
    IN emailInput VARCHAR(255),
    IN phoneNumberInput VARCHAR(50),
    IN customerID_from_update_customer_form INT
)
BEGIN
    UPDATE Customers
    SET Customers.email = emailInput,
        Customers.phoneNumber = phoneNumberInput
    WHERE Customers.customerID = customerID_from_update_customer_form;
END //

DELIMITER ;



/* 3. Orders Page */

-- Displays all orders with customer and employee name fields for browsing in the Orders page.
CREATE OR REPLACE VIEW v_browse_orders_page AS
SELECT Orders.orderID AS "Order ID",
       Orders.orderDate AS "Order Date",
       Orders.orderTotal AS "Order Total",
       Customers.customerID AS "Customer ID",
       Customers.firstName AS "First Name",
       Customers.lastName AS "Last Name",
       Employees.employeeID AS "Employee ID",
       Employees.firstName AS "Employee First Name",
       Employees.lastName AS "Employee Last Name"
FROM Orders
LEFT JOIN Customers
       ON Orders.customerID = Customers.customerID
LEFT JOIN Employees
       ON Orders.employeeID = Employees.employeeID
ORDER BY Orders.orderID;


-- Displays all order line items for a selected order with product name and computed line total.
CREATE OR REPLACE VIEW v_browse_order_details_page AS
SELECT OrderDetails.orderDetailsID AS "Order Details ID",
       OrderDetails.orderID AS "Order ID",
       Products.productID AS "Product ID",
       Products.productName AS "Product Name",
       OrderDetails.quantity AS "Quantity",
       OrderDetails.unitPrice AS "Unit Price",
       (OrderDetails.quantity * OrderDetails.unitPrice) AS "Line Total"
FROM OrderDetails
LEFT JOIN Products
       ON OrderDetails.productID = Products.productID
ORDER BY OrderDetails.orderID,
         OrderDetails.orderDetailsID;


-- Displays all products for creating an order (unit price comes from Products.price).
CREATE OR REPLACE VIEW v_browse_products_for_order_entry AS
SELECT Products.productID AS "Product ID",
       Products.productName AS "Product Name",
       Products.price AS "Unit Price",
       Products.stock AS "Stock"
FROM Products
ORDER BY Products.productName;


-- Displays all customers for the customer dropdown when creating a new order.
CREATE OR REPLACE VIEW v_browse_customers_for_order_entry AS
SELECT Customers.customerID AS "Customer ID",
       Customers.firstName AS "First Name",
       Customers.lastName AS "Last Name"
FROM Customers
ORDER BY Customers.lastName,
         Customers.firstName;


-- Displays all employees for the employee dropdown when creating a new order.
CREATE OR REPLACE VIEW v_browse_employees_for_order_entry AS
SELECT Employees.employeeID AS "Employee ID",
       Employees.firstName AS "First Name",
       Employees.lastName AS "Last Name",
       Employees.jobTitle AS "Job Title"
FROM Employees
ORDER BY Employees.lastName,
         Employees.firstName;


DELIMITER //

-- Deletes an order by the selected orderID from the browse orders page.
DROP PROCEDURE IF EXISTS sp_delete_order //
CREATE PROCEDURE sp_delete_order (
    IN orderID_selected_from_browse_orders_page INT
)
BEGIN
    DELETE FROM Orders
    WHERE Orders.orderID = orderID_selected_from_browse_orders_page;
END //

-- Inserts a new order using the selected customer and employee IDs and sets the orderDate automatically to the current date.
DROP PROCEDURE IF EXISTS sp_insert_order //
CREATE PROCEDURE sp_insert_order (
    IN customerID_selected_from_create_order_form INT,
    IN employeeID_selected_from_create_order_form INT
)
BEGIN
    INSERT INTO Orders (orderDate, orderTotal, customerID, employeeID)
    VALUES (CURDATE(), 0.00, customerID_selected_from_create_order_form, employeeID_selected_from_create_order_form);

    SELECT LAST_INSERT_ID() AS orderID;
END //

-- Adds an item to an order or updates it if it already exists, then refreshes order total.
DROP PROCEDURE IF EXISTS sp_upsert_order_detail //
CREATE PROCEDURE sp_upsert_order_detail (
    IN orderID_from_create_order_form INT,
    IN productIDInput INT,
    IN quantityInput INT
)
BEGIN
    DECLARE unitPriceCalculated DECIMAL(10,2);
    DECLARE existingOrderDetailsID INT DEFAULT NULL;

    SELECT Products.price
    INTO unitPriceCalculated
    FROM Products
    WHERE Products.productID = productIDInput;

    SELECT OrderDetails.orderDetailsID
    INTO existingOrderDetailsID
    FROM OrderDetails
    WHERE OrderDetails.orderID = orderID_from_create_order_form
      AND OrderDetails.productID = productIDInput
    LIMIT 1;

    IF existingOrderDetailsID IS NULL THEN
        INSERT INTO OrderDetails (orderID, productID, quantity, unitPrice)
        VALUES (orderID_from_create_order_form, productIDInput, quantityInput, unitPriceCalculated);
    ELSE
        UPDATE OrderDetails
        SET OrderDetails.quantity = quantityInput,
            OrderDetails.unitPrice = unitPriceCalculated
        WHERE OrderDetails.orderDetailsID = existingOrderDetailsID;
    END IF;

    UPDATE Orders
    SET Orders.orderTotal = (
        SELECT COALESCE(SUM(OrderDetails.quantity * OrderDetails.unitPrice), 0.00)
        FROM OrderDetails
        WHERE OrderDetails.orderID = orderID_from_create_order_form
    )
    WHERE Orders.orderID = orderID_from_create_order_form;
END //

DELIMITER ;



/* 4. Products Page */

-- Displays all products with product type details and a computed column for total units sold.
CREATE OR REPLACE VIEW v_browse_products_page AS
SELECT Products.productID AS "Product ID",
       Products.productName AS "Product Name",
       ProductTypes.productTypeCode AS "Product Type Code",
       ProductTypes.productTypeName AS "Product Type Name",
       Products.price AS "Price",
       Products.stock AS "Stock",
       COALESCE(SUM(OrderDetails.quantity), 0) AS "Units Sold"
FROM Products
LEFT JOIN ProductTypes
       ON Products.productTypeCode = ProductTypes.productTypeCode
LEFT JOIN OrderDetails
       ON OrderDetails.productID = Products.productID
GROUP BY Products.productID,
         Products.productName,
         ProductTypes.productTypeCode,
         ProductTypes.productTypeName,
         Products.price,
         Products.stock
ORDER BY Products.productID;


-- Displays all product types with a computed column for how many products currently use each type.
CREATE OR REPLACE VIEW v_browse_product_types_page AS
SELECT ProductTypes.productTypeCode AS "Product Type Code",
       ProductTypes.productTypeName AS "Product Type Name",
       COUNT(Products.productID) AS "Products Using Type"
FROM ProductTypes
LEFT JOIN Products
       ON Products.productTypeCode = ProductTypes.productTypeCode
GROUP BY ProductTypes.productTypeCode,
         ProductTypes.productTypeName
ORDER BY ProductTypes.productTypeCode;


-- Displays all product type codes and names for product create and update form dropdowns.
CREATE OR REPLACE VIEW v_browse_product_types_for_product_entry AS
SELECT ProductTypes.productTypeCode AS "Product Type Code",
       ProductTypes.productTypeName AS "Product Type Name"
FROM ProductTypes
ORDER BY ProductTypes.productTypeCode;


DELIMITER //

-- Deletes a product by the selected productID from the browse products page.
DROP PROCEDURE IF EXISTS sp_delete_product //
CREATE PROCEDURE sp_delete_product (
    IN productID_selected_from_browse_products_page INT
)
BEGIN
    DELETE FROM Products
    WHERE Products.productID = productID_selected_from_browse_products_page;
END //

-- Inserts a new product using the provided product name, selected product type code, price, and stock.
DROP PROCEDURE IF EXISTS sp_insert_product //
CREATE PROCEDURE sp_insert_product (
    IN productNameInput VARCHAR(255),
    IN productTypeCode_selected_from_create_product_form VARCHAR(50),
    IN priceInput DECIMAL(10,2),
    IN stockInput INT
)
BEGIN
    INSERT INTO Products (productName, productTypeCode, price, stock)
    VALUES (productNameInput, productTypeCode_selected_from_create_product_form, priceInput, stockInput);
END //

-- Selects one products details by the selected productID from the browse products page.
DROP PROCEDURE IF EXISTS sp_select_one_product //
CREATE PROCEDURE sp_select_one_product (
    IN productID_selected_from_browse_products_page INT
)
BEGIN
    SELECT Products.productID AS "Product ID",
           Products.productName AS "Product Name",
           Products.productTypeCode AS "Product Type Code",
           Products.price AS "Price",
           Products.stock AS "Stock"
    FROM Products
    WHERE Products.productID = productID_selected_from_browse_products_page;
END //

-- Updates a products name, product type code, price, and stock using the provided inputs for the specified productID from the update form.
DROP PROCEDURE IF EXISTS sp_update_product //
CREATE PROCEDURE sp_update_product (
    IN productNameInput VARCHAR(255),
    IN productTypeCode_selected_from_update_product_form VARCHAR(50),
    IN priceInput DECIMAL(10,2),
    IN stockInput INT,
    IN productID_from_update_product_form INT
)
BEGIN
    UPDATE Products
    SET Products.productName = productNameInput,
        Products.productTypeCode = productTypeCode_selected_from_update_product_form,
        Products.price = priceInput,
        Products.stock = stockInput
    WHERE Products.productID = productID_from_update_product_form;
END //

-- Deletes a product type by the selected productTypeCode from the browse product types section.
DROP PROCEDURE IF EXISTS sp_delete_product_type //
CREATE PROCEDURE sp_delete_product_type (
    IN productTypeCode_selected_from_browse_product_types_page VARCHAR(50)
)
BEGIN
    DELETE FROM ProductTypes
    WHERE ProductTypes.productTypeCode = productTypeCode_selected_from_browse_product_types_page;
END //

-- Inserts a new product type using the provided product type code and product type name inputs.
DROP PROCEDURE IF EXISTS sp_insert_product_type //
CREATE PROCEDURE sp_insert_product_type (
    IN productTypeCodeInput VARCHAR(50),
    IN productTypeNameInput VARCHAR(50)
)
BEGIN
    INSERT INTO ProductTypes (productTypeCode, productTypeName)
    VALUES (productTypeCodeInput, productTypeNameInput);
END //

-- Selects one product types details by the selected productTypeCode from the browse product types section.
DROP PROCEDURE IF EXISTS sp_select_one_product_type //
CREATE PROCEDURE sp_select_one_product_type (
    IN productTypeCode_selected_from_browse_product_types_page VARCHAR(50)
)
BEGIN
    SELECT ProductTypes.productTypeCode AS "Product Type Code",
           ProductTypes.productTypeName AS "Product Type Name"
    FROM ProductTypes
    WHERE ProductTypes.productTypeCode = productTypeCode_selected_from_browse_product_types_page;
END //

-- Updates a product types name using the provided input for the specified productTypeCode from the update form.
DROP PROCEDURE IF EXISTS sp_update_product_type //
CREATE PROCEDURE sp_update_product_type (
    IN productTypeNameInput VARCHAR(50),
    IN productTypeCode_from_update_product_type_form VARCHAR(50)
)
BEGIN
    UPDATE ProductTypes
    SET ProductTypes.productTypeName = productTypeNameInput
    WHERE ProductTypes.productTypeCode = productTypeCode_from_update_product_type_form;
END //

DELIMITER ;
