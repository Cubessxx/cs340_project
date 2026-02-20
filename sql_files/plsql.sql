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

DROP PROCEDURE IF EXISTS sp_delete_customer;
DROP PROCEDURE IF EXISTS sp_insert_customer;
DROP PROCEDURE IF EXISTS sp_select_one_customer;
DROP PROCEDURE IF EXISTS sp_update_customer;
DROP PROCEDURE IF EXISTS sp_delete_order;
DROP PROCEDURE IF EXISTS sp_insert_order;
DROP PROCEDURE IF EXISTS sp_insert_order_detail;
DROP PROCEDURE IF EXISTS sp_update_order_detail;
DROP PROCEDURE IF EXISTS sp_upsert_order_detail;

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
       Customers.firstName AS "Customer First Name",
       Customers.lastName AS "Customer Last Name",
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

