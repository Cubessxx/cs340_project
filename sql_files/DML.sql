/*
Group 73
Members: Gage Cox
         Brandon Connely
         Carlos Chirinos
*/


-- 1. Home Page  (NO SQL)



-- 2. Animals Page
-- "Browse Animals" tab displays "Name", "Species", "Age", "Price", "Available", and "Order ID".
SELECT Animals.animalID AS "Animal ID",
       Animals.name AS "Name",
       Animals.species AS "Species",
       Animals.age AS "Age",
       Animals.price AS "Price",
       CASE WHEN Animals.isAvailable = 1 THEN 'Yes' ELSE 'No' END AS "Available",
       Animals.orderID AS "Order ID"
FROM Animals
ORDER BY Animals.animalID;

-- "Create Animal" tab: Inputs: "Name", "Species", "Age", "Price", "Available" Button: "Create Animal" (orderID defaults to NULL).
INSERT INTO Animals (name, species, age, price, isAvailable, orderID)
VALUES (:nameInput, :speciesInput, :ageInput, :priceInput, :isAvailableInput, NULL);

-- "Update Animal" tab:  Selectbox: "Select Animal", Inputs: "Age", "Price", "Available", Button: "Update Animal".
UPDATE Animals
SET Animals.age = :ageInput,
    Animals.price = :priceInput,
    Animals.isAvailable = :isAvailableInput
WHERE Animals.animalID = :animalID_from_update_animal_form;

-- "Delete Animal" tab: Selectbox: "Select Animal" Button: "Delete Animal".
DELETE FROM Animals
WHERE Animals.animalID = :animalID_selected_from_browse_animals_page;

-- "Employee Assignments" tab displays "Assignment ID", "Animal Name", "Employee Name" and "Job Title".
SELECT EmployeeAnimals.animalDetailsID AS "Assignment ID",
       Animals.name AS "Animal Name",
       CONCAT(Employees.firstName, ' ', Employees.lastName) AS "Employee Name",
       Employees.jobTitle AS "Job Title"
FROM EmployeeAnimals
JOIN Animals
  ON EmployeeAnimals.animalID = Animals.animalID
JOIN Employees
  ON EmployeeAnimals.employeeID = Employees.employeeID
ORDER BY EmployeeAnimals.animalDetailsID;



-- 3. Customers Page
-- "Browse Customers" tab displays "Customer ID", "First Name", "Last Name", "Email", "Phone Number", and "Active Orders".
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

-- "Create Customer" tab: Inputs: "First Name", "Last Name", "Email", "Phone Number" Button: "Create Customer".
INSERT INTO Customers (firstName, lastName, email, phoneNumber)
VALUES (:firstNameInput, :lastNameInput, :emailInput, :phoneNumberInput);

-- "Update Customer" tab: Selectbox: "Select Customer" loads current values for "Email" and "Phone Number".
SELECT Customers.customerID AS "Customer ID",
       Customers.firstName AS "First Name",
       Customers.lastName AS "Last Name",
       Customers.email AS "Email",
       Customers.phoneNumber AS "Phone Number"
FROM Customers
WHERE Customers.customerID = :customerID_selected_from_browse_customers_page;

-- "Update Customer" tab: Inputs: "New Email", "New Phone Number" Button: "Update Customer".
UPDATE Customers
SET Customers.email = :emailInput,
    Customers.phoneNumber = :phoneNumberInput
WHERE Customers.customerID = :customerID_from_update_customer_form;

-- "Delete Customer" tab: Selectbox: "Select Customer" Button: "Delete Customer".
DELETE FROM Customers
WHERE Customers.customerID = :customerID_selected_from_browse_customers_page;



-- 4. Employees Page
-- "Browse Employees" tab displays "Employee ID", "First Name", "Last Name", and "Job Title".
SELECT Employees.employeeID AS "Employee ID",
       Employees.firstName AS "First Name",
       Employees.lastName AS "Last Name",
       Employees.jobTitle AS "Job Title"
FROM Employees
ORDER BY Employees.employeeID;

-- "Create Employee" tab: Inputs: "First Name", "Last Name", "Job Title" Button: "Create Employee".
INSERT INTO Employees (firstName, lastName, jobTitle)
VALUES (:firstNameInput, :lastNameInput, :jobTitleInput);

-- "Delete Employee" tab: Selectbox: "Select Employee" Button: "Delete Employee".
DELETE FROM Employees
WHERE Employees.employeeID = :employeeID_selected_from_browse_employees_page;



-- 5. Orders Page
-- "Browse Orders" tab displays "Order ID", "Order Date", "Order Total", "Customer ID", "First Name", "Last Name", "Employee ID", "Employee First Name", and "Employee Last Name".
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

-- "View or Update Order Details" tab displays "Order Details ID", "Order ID", "Product ID", "Product Name", "Quantity", "Unit Price", and "Line Total" for selected "Order".
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
WHERE OrderDetails.orderID = :orderID_selected_from_browse_orders_page
ORDER BY OrderDetails.orderID,
         OrderDetails.orderDetailsID;

-- "View or Update Order Details" tab: Selectbox: "Select Item" data source displays "Product ID", "Product Name", "Unit Price", and "Stock".
SELECT Products.productID AS "Product ID",
       Products.productName AS "Product Name",
       Products.price AS "Unit Price",
       Products.stock AS "Stock"
FROM Products
ORDER BY Products.productName;

-- "View or Update Order Details" tab: Button: "Update or Add Item" looks up selected "Select Item" price.
SELECT Products.price AS unitPriceCalculated
FROM Products
WHERE Products.productID = :productIDInput;

-- "View or Update Order Details" tab: Button: "Update or Add Item" checks if selected "Order" already has selected "Select Item".
SELECT OrderDetails.orderDetailsID
FROM OrderDetails
WHERE OrderDetails.orderID = :orderID_from_create_order_form
  AND OrderDetails.productID = :productIDInput
LIMIT 1;

-- "View or Update Order Details" tab: Button: "Update or Add Item" inserts new line item when order/product pair does not exist.
INSERT INTO OrderDetails (orderID, productID, quantity, unitPrice)
VALUES (:orderID_from_create_order_form, :productIDInput, :quantityInput, :unitPriceCalculated);

-- "View or Update Order Details" tab: Button: "Update or Add Item" updates line item when order/product pair exists.
UPDATE OrderDetails
SET OrderDetails.quantity = :quantityInput,
    OrderDetails.unitPrice = :unitPriceCalculated
WHERE OrderDetails.orderDetailsID = :existingOrderDetailsID;

-- "View or Update Order Details" tab: Button: "Update or Add Item" recalculates selected "Order Total".
UPDATE Orders
SET Orders.orderTotal = (
    SELECT COALESCE(SUM(OrderDetails.quantity * OrderDetails.unitPrice), 0.00)
    FROM OrderDetails
    WHERE OrderDetails.orderID = :orderID_from_create_order_form
)
WHERE Orders.orderID = :orderID_from_create_order_form;

-- "Create or Delete Order" tab: Selectbox: "Customer" data source displays "Customer ID", "First Name", and "Last Name".
SELECT Customers.customerID AS "Customer ID",
       Customers.firstName AS "First Name",
       Customers.lastName AS "Last Name"
FROM Customers
ORDER BY Customers.lastName,
         Customers.firstName;

-- "Create or Delete Order" tab: Selectbox: "Assigned Employee" data source displays "Employee ID", "First Name", "Last Name", and "Job Title".
SELECT Employees.employeeID AS "Employee ID",
       Employees.firstName AS "First Name",
       Employees.lastName AS "Last Name",
       Employees.jobTitle AS "Job Title"
FROM Employees
ORDER BY Employees.lastName,
         Employees.firstName;

-- "Create or Delete Order" tab: "Create Order" section: Inputs: "Customer", "Assigned Employee" Button: "Create Order".
INSERT INTO Orders (orderDate, orderTotal, customerID, employeeID)
VALUES (CURDATE(), 0.00, :customerID_selected_from_create_order_form, :employeeID_selected_from_create_order_form);

SELECT LAST_INSERT_ID() AS orderID;

-- "Create or Delete Order" tab: "Delete Order" section: Selectbox: "Order" Button: "Delete Order".
DELETE FROM Orders
WHERE Orders.orderID = :orderID_selected_from_browse_orders_page;



-- 6. Products Page
-- "Browse Products" tab displays "Product ID", "Product Name", "Product Type Code", "Product Type Name", "Price", "Stock", and "Units Sold".
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

-- "Create Product" and "Update Product" tabs: Selectbox: "Product Type" data source displays "Product Type Code" and "Product Type Name".
SELECT ProductTypes.productTypeCode AS "Product Type Code",
       ProductTypes.productTypeName AS "Product Type Name"
FROM ProductTypes
ORDER BY ProductTypes.productTypeCode;

-- "Create Product" tab: Inputs: "Product Name", "Product Type", "Price", "Stock" Button: "Create Product".
INSERT INTO Products (productName, productTypeCode, price, stock)
VALUES (:productNameInput,
        :productTypeCode_selected_from_create_product_form,
        :priceInput,
        :stockInput);

-- "Update Product" tab: Selectbox: "Select Product" loads current values for "Product Name", "Product Type", "Price", and "Stock".
SELECT Products.productID AS "Product ID",
       Products.productName AS "Product Name",
       Products.productTypeCode AS "Product Type Code",
       Products.price AS "Price",
       Products.stock AS "Stock"
FROM Products
WHERE Products.productID = :productID_selected_from_browse_products_page;

-- "Update Product" tab: Inputs: "Product Name", "Product Type", "Price", "Stock" Button: "Update Product".
UPDATE Products
SET Products.productName = :productNameInput,
    Products.productTypeCode = :productTypeCode_selected_from_update_product_form,
    Products.price = :priceInput,
    Products.stock = :stockInput
WHERE Products.productID = :productID_from_update_product_form;

-- "Delete Product" tab: Selectbox: "Select Product" Button: "Delete Product".
DELETE FROM Products
WHERE Products.productID = :productID_selected_from_browse_products_page;



-- 7. Product Types Page
-- "Browse Product Types" tab displays "Product Type Code", "Product Type Name", and "Products Using Type".
SELECT ProductTypes.productTypeCode AS "Product Type Code",
       ProductTypes.productTypeName AS "Product Type Name",
       COUNT(Products.productID) AS "Products Using Type"
FROM ProductTypes
LEFT JOIN Products
       ON Products.productTypeCode = ProductTypes.productTypeCode
GROUP BY ProductTypes.productTypeCode,
         ProductTypes.productTypeName
ORDER BY ProductTypes.productTypeCode;

-- "Create Product Type" tab: Inputs: "Product Type Code", "Product Type Name" Button: "Create Product Type".
INSERT INTO ProductTypes (productTypeCode, productTypeName)
VALUES (:productTypeCodeInput, :productTypeNameInput);

-- "Update Product Type" tab: Selectbox: "Select Product Type" loads current value for "Product Type Name".
SELECT ProductTypes.productTypeCode AS "Product Type Code",
       ProductTypes.productTypeName AS "Product Type Name"
FROM ProductTypes
WHERE ProductTypes.productTypeCode = :productTypeCode_selected_from_browse_product_types_page;

-- "Update Product Type" tab: Inputs: "Product Type Name" Button: "Update Product Type".
UPDATE ProductTypes
SET ProductTypes.productTypeName = :productTypeNameInput
WHERE ProductTypes.productTypeCode = :productTypeCode_from_update_product_type_form;

-- "Delete Product Type" tab: Selectbox: "Select Product Type" Button: "Delete Product Type".
DELETE FROM ProductTypes
WHERE ProductTypes.productTypeCode = :productTypeCode_selected_from_browse_product_types_page;
