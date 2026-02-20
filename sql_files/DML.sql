/*
Group 73
Members: Gage Cox
         Brandon Connely
         Carlos Chirinos
*/


-- 1. Home Page  (NO SQL)



--2. Customers Page
-- Displays Customers along with their first name, last name, email and phone number.
-- Additional Column  "activeOrders" that displays how many enteries from the "Orders" table a given customer is associated with.
SELECT Customers.customerID,
       Customers.firstName,
       Customers.lastName,
       Customers.email,
       Customers.phoneNumber,
       COUNT(Orders.orderID) AS activeOrders
FROM Customers
LEFT JOIN Orders
       ON Orders.customerID = Customers.customerID
GROUP BY Customers.customerID,
         Customers.firstName,
         Customers.lastName,
         Customers.email,
         Customers.phoneNumber
ORDER BY Customers.customerID;

--Delete button next to each individual customer
DELETE FROM Customers
WHERE Customers.customerID = :customerID_selected_from_browse_customers_page;

--'Create a Customer' form with entry information for Customers First Name, Last Name, Email, Phone Number.
INSERT INTO Customers (firstName, lastName, email, phoneNumber)
VALUES (:firstNameInput, :lastNameInput, :emailInput, :phoneNumberInput);

--'Update a Customer' form where a customer is selected and new information may be entered for there Email and Phone Number. 
SELECT Customers.customerID,
       Customers.firstName,
       Customers.lastName,
       Customers.email,
       Customers.phoneNumber
FROM Customers
WHERE Customers.customerID = :customerID_selected_from_browse_customers_page;

UPDATE Customers
SET Customers.email = :emailInput,
    Customers.phoneNumber = :phoneNumberInput
WHERE Customers.customerID = :customerID_from_update_customer_form;



--3. Orders Page
--Displays Orders along with their date, associated customer, associated employee and total amount.
SELECT Orders.orderID,
       Orders.orderDate,
       Orders.customerID,
       Orders.employeeID,
       Orders.orderTotal,
FROM Orders
ORDER BY Orders.orderID;

--Delete button next to each Order
DELETE FROM Orders
WHERE Orders.orderID = :orderID_selected_from_browse_orders_page;




--4. Order Details page
-- Simply displays the 'OrderDetails' table fully.
SELECT *
FROM OrderDetails
ORDER BY OrderDetails.orderID;




--5. New Order Page
--Displays the current catalog of products along with input for quantity for each item that can be selectd 0-10. An associated customer and employee is chosen, and the 'Create Order' button generates the correlating order. 
SELECT Products.productID,
       Products.productName,
       Products.productTypeCode,
       Products.price,
       Products.stock
FROM Products
ORDER BY Products.productID;

INSERT INTO Orders (orderDate, customerID, employeeID, orderTotal)
VALUES (CURDATE(), :customerID_from_dropdown_Input, :employeeID_from_dropdown_Input, 0.00);

SELECT LAST_INSERT_ID() AS newOrderID;

INSERT INTO OrderDetails (orderID, productID, quantity)
VALUES (:newOrderID_from_previous_step, :productID_selected_from_products_table, :quantityInput_1_to_10);

UPDATE Products
SET Products.stock = Products.stock - :quantityInput_1_to_10
WHERE Products.productID = :productID_selected_from_products_table;

UPDATE Orders
SET Orders.orderTotal =
(
    SELECT IFNULL(SUM(OrderDetails.quantity * Products.price), 0.00)
    FROM OrderDetails
    INNER JOIN Products
            ON Products.productID = OrderDetails.productID
    WHERE OrderDetails.orderID = Orders.orderID
)
WHERE Orders.orderID = :newOrderID_from_previous_step;

-- Citation for use of AI Tools:
--    # Date: 02/12/26
--      # Prompts used to assist with coding SQL for 'New Order Page'
--     # "Based on the following specification of the desired SQL page, how could I write DML sql code similar to previous pages? walk through the solution step by step"
--     # AI Source URL: https://chatgpt.com/
    

Links to an external site. 


--6. Products Page
--Displays products alongside their name, type code, price and current stock.
SELECT Products.productID,
       Products.productName,
       Products.productTypeCode,
       Products.price,
       Products.stock
FROM Products
ORDER BY Products.productID;

--'Create a Product' Form where a new product is created with a name, type, price and current amount of stock.
SELECT ProductTypes.productTypeCode,
       ProductTypes.productTypeName
FROM ProductTypes
ORDER BY ProductTypes.productTypeCode;

INSERT INTO Products (productName, productTypeCode, price, stock)
VALUES (:productNameInput, :productTypeCode_from_dropdown_Input, :priceInput, :stockInput);

--'Update Product Stock Form' where a preexisting product can be chosen and the associated stock is changed.
SELECT Products.productID,
       Products.productName
FROM Products
ORDER BY Products.productID;

UPDATE Products
SET Products.stock = :newStockInput
WHERE Products.productID = :productID_from_dropdown_Input;




--7. ProductTypes Page
-- Simply displays the "PrdouctTypes" table.
SELECT *
FROM ProductTypes
ORDER BY ProductTypes.productTypeCode;




--8. Employees Page
-- Displays Employees along with their respective employeeID and jobTitle.
SELECT Employees.employeeID,
       Employees.firstName,
       Employees.lastName,
       Employees.jobTitle
FROM Employees
ORDER BY Employees.employeeID;

--Delete button next to each individual employee 
DELETE FROM Employees
WHERE Employees.employeeID = :employeeID_selected_from_browse_employees_page;

--'New Employee' Form where a new employee is created with a first name, last name and job title.
INSERT INTO Employees (firstName, lastName, jobTitle)
VALUES (:firstNameInput, :lastNameInput, :jobTitleInput);




--9. EmployeesAnimal Page
--Simply displays the EmployeesAnimal table.
SELECT *
FROM EmployeesAnimal
ORDER BY EmployeesAnimal.employeeID, EmployeesAnimal.animalID;




--10. Animals Page
-- Displays the individual animals alongside their current age, price, and avalability status. It also displays their respective order if their associated with one.
SELECT Animals.animalID,
       Animals.species,
       Animals.age,
       Animals.price,
       Animals.isAvailable,
       Animals.orderID
FROM Animals
ORDER BY Animals.animalID;

--Delete button next to each individual animal
DELETE FROM Animals
WHERE Animals.animalID = :animalID_selected_from_browse_animals_page;

--'Create a Animal' form where a new animal is added to the system with a given Species, Age and Price.
INSERT INTO Animals (species, age, price, isAvailable, orderID)
VALUES (:speciesInput, :ageInput, :priceInput, 1, NULL);

-- 'Update Animal' form where a animal can have its price, avalability status and the order it belongs to changed.
SELECT Animals.animalID,
       Animals.species,
       Animals.age,
       Animals.price,
       Animals.isAvailable,
       Animals.orderID
FROM Animals
WHERE Animals.animalID = :animalID_selected_from_browse_animals_page;

UPDATE Animals
SET Animals.price = :priceInput,
    Animals.isAvailable = :isAvailableInput,
    Animals.orderID = :orderIDInput
WHERE Animals.animalID = :animalID_from_update_animal_form;
