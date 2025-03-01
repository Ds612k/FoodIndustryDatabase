


--List of Drop Commands for tables 
DROP TABLE Recommendations CASCADE CONSTRAINTS;
DROP TABLE Reviews CASCADE CONSTRAINTS;
DROP TABLE Orders CASCADE CONSTRAINTS;
DROP TABLE Customer CASCADE CONSTRAINTS;
DROP TABLE Menu_Items CASCADE CONSTRAINTS;
DROP TABLE Restaurant_Inventory CASCADE CONSTRAINTS;
DROP TABLE Waiter CASCADE CONSTRAINTS;
DROP TABLE restaurant CASCADE CONSTRAINTS;
DROP TABLE cuisine CASCADE CONSTRAINTS;

--List of Drop Commands for Sequence
DROP SEQUENCE cuisine_seq;
DROP SEQUENCE restaurant_seq;
DROP SEQUENCE WaiterID_SEQ;
DROP SEQUENCE menu_item_seq;
DROP SEQUENCE inventory_seq;
DROP SEQUENCE customer_id_seq;
DROP SEQUENCE order_id_seq;
DROP SEQUENCE reviewID_seq ;
DROP SEQUENCE recommendationID_seq;

--List of Create Commands for Sequences
CREATE SEQUENCE cuisine_seq start with 1 increment by 1;
CREATE SEQUENCE restaurant_seq start with 1 increment by 1;
CREATE SEQUENCE WaiterID_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE menu_item_seq START WITH 1;
CREATE SEQUENCE inventory_seq START WITH 1;
CREATE SEQUENCE customer_id_seq START WITH 1;
CREATE SEQUENCE order_id_seq START WITH 1;
CREATE SEQUENCE reviewID_seq START WITH 1;
CREATE SEQUENCE recommendationID_seq START WITH 1;

--CODE TO CREATE ALL THE TABLES
--Create Cuisine Type Table
create table cuisine (
cid int,
cuisine_type varchar (10),
primary key (cid));

-- Create Restaurant Table
create table restaurant (
rid int,
restaurant_name varchar (50),
street_address varchar (50),
city varchar (30),
zip number,
state varchar (2),
cuisine_specialty varchar (30),
cid int,
foreign key (cid) references cuisine (cid),
primary key (rid));

--Create Table Waiter
CREATE TABLE Waiter(
wid INTEGER,
wname VARCHAR(20),
rid INTEGER,
CONSTRAINT w_pk PRIMARY KEY(wid),
CONSTRAINT w_fk FOREIGN KEY(rid) REFERENCES restaurant(rid));

-- Create a table of menu_items
CREATE TABLE Menu_Items (
menu_item_id INT PRIMARY KEY,
cid INT,
menu_item_name VARCHAR(50),
price DECIMAL(8, 2),
CONSTRAINT fk_cuisine_type FOREIGN KEY (cid) REFERENCES Cuisine(cid));

--created table for Restaurant_Inventory
CREATE TABLE Restaurant_Inventory (
inventory_id INT PRIMARY KEY,
menu_item_id INT,
menu_item_name VARCHAR(50),
rid INT,
quantity INT,
CONSTRAINT fk_restaurant FOREIGN KEY (rid) REFERENCES restaurant(rid),
CONSTRAINT fk_menu_item FOREIGN KEY (menu_item_id) REFERENCES Menu_Items(menu_item_id));

-- Create a Customer Table
CREATE TABLE Customer(
customer_id INTEGER PRIMARY KEY,
customer_name VARCHAR(20),
email VARCHAR(50),
street_address VARCHAR(50),
city VARCHAR(20),
state VARCHAR(20),
zip VARCHAR(5),
credit_card_num VARCHAR(16) );

-- Create orders table
CREATE TABLE Orders(
order_id INTEGER PRIMARY KEY,
rid INTEGER,
customer_id INTEGER,
order_date DATE,
menu_item_id INTEGER,
wid INTEGER,
Amount_paid DECIMAL(8, 2),
Tip DECIMAL(8, 2),
FOREIGN KEY (customer_id) REFERENCES Customer (customer_id),
FOREIGN KEY (rid) REFERENCES Restaurant (rid),
FOREIGN KEY (menu_item_id) REFERENCES Menu_Items(menu_item_id),
FOREIGN KEY (wid) REFERENCES Waiter(wid));

-- Create review table
CREATE TABLE Reviews
(reviewID INT NOT NULL,
restaurantID INT,
reviewer_email VARCHAR(30),
stars_given FLOAT,
review_text VARCHAR(100),
CONSTRAINT reviewID_PK PRIMARY KEY(reviewID),
CONSTRAINT restaurantID_FK FOREIGN KEY(restaurantID) REFERENCES restaurant(rid));

-- Create a recommendation table
CREATE TABLE Recommendations
(recommendationID INT NOT NULL,
customerID INT,
recommended_rid INT,
recommendation_date DATE,
CONSTRAINT recommendationID_PK PRIMARY KEY(recommendationID),
CONSTRAINT customerID_FK FOREIGN KEY(customerID) REFERENCES customer(customer_id), CONSTRAINT recommended_rid_FK FOREIGN KEY(recommended_rid)
REFERENCES restaurant(rid));


--CODE TO CREATE FUNCTIONS/PROCEDURES
--Create a procedure to add a cuisine type
Create or replace procedure ADD_CUISINE (p_cuisine_type in varchar) AS
Begin
 insert into Cuisine (cid, cuisine_type)
 values (cuisine_seq.NEXTVAL, p_cuisine_type);
 dbms_output.put_line('Cuisine Type has been added');
Exception
 WHEN NO_DATA_FOUND THEN
 dbms_output.put_line('An error has occurred while adding the cuisine type');
End;
/

--Create a helper function for the cuisine ID
Create or replace function find_cuisine_id (f_cuisine_type in varchar)
 return number AS
 f_cuisineID number;
Begin
 select cid into f_cuisineID
 from cuisine
 where cuisine_type = f_cuisine_type;
 return f_cuisineID;
Exception
 when no_data_found then
 dbms_output.put_line ('No cuisine found');
 return -1;
End;
/

--Create a Procedure to Add a Restaurant
create or replace procedure Add_Restaurant(
 p_restaraunt_name IN varchar,
 p_street_address IN varchar,
 p_city IN varchar,
 p_zip IN number,
 p_state IN varchar,
 p_cuisine_specialty IN varchar)
 AS
 p_cid int;
Begin
 Select cid into p_cid
 From Cuisine
 Where cuisine_type = p_cuisine_specialty;
 Insert into Restaurant (rid, restaurant_name, street_address, city, zip, state, cuisine_specialty, cid)
 Values (restaurant_seq.NEXTVAL, p_restaraunt_name, p_street_address, p_city, p_zip, p_state, p_cuisine_specialty, p_cid);
 dbms_output.put_line('Restaurant has been added.');
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 dbms_output.put_line('Error: No Cuisine Type Found');
 WHEN OTHERS THEN
 dbms_output.put_line('An Error has occurred adding the restaurant');
End;
/

--Create helper function for the restaurant ID
Create or replace function find_restaurant_id (f_restaurant_name in varchar)
 return number AS
 f_restaurantID number;
Begin
 select rid into f_restaurantID
 from restaurant
 where restaurant_name = f_restaurant_name;
 return f_restaurantID;
Exception
 when no_data_found then
 dbms_output.put_line ('No restaurant found');
 return -1;
End;
/

-- Display restaurant by cuisine: Given a cuisine type, show the name and address of all restaurants that offer that cuisine
-- Create a Procedure to Display Restaurants by Cuisine
CREATE OR REPLACE PROCEDURE DISPLAY_RESTAURANTS_BY_CUISINE(p_cuisine_type IN VARCHAR) IS
Begin
 For r_row IN (Select restaurant_name, street_address, city, state, zip
 From restaurant r, cuisine c
 Where r.cid = c.cid and c.cuisine_type = p_cuisine_type)
 LOOP
 DBMS_OUTPUT.PUT_LINE('Restaurant Name: ' || r_row.restaurant_name || ', Address: ' || r_row.street_address || ', ' || r_row.city || ',
' || r_row.state || ', ' || r_row.zip);
 END LOOP;
End;
/

--Procedure for reporting income by state. Generate a report that lists the income of restaurants per cuisine type and per state.
CREATE OR REPLACE PROCEDURE REPORT_INCOME_BY_STATE AS
Begin
 For state_record IN (
 Select r.state, c.cuisine_type, SUM(o.Amount_paid) AS total_income
 From Restaurant r, orders o, cuisine c, menu_items m
 Where r.rid = o.rid and o.menu_item_id = m.menu_item_id and m.cid = c.cid
 Group By r.state, c.cuisine_type
 Order By r.state, total_income DESC
 ) LOOP
 DBMS_OUTPUT.PUT_LINE('State: ' || state_record.state || ', Cuisine Type: ' || state_record.cuisine_type || ', Total Income: $' ||
state_record.total_income);
 END LOOP;
EXCEPTION
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END REPORT_INCOME_BY_STATE;
/

--Create function to find waiter id
CREATE OR REPLACE FUNCTION FIND_Waiter_ID (waiter_name VARCHAR)
RETURN INTEGER
AS
 waiter_id INTEGER;
BEGIN
 SELECT wid INTO waiter_id
 FROM waiter
 WHERE wname = waiter_name;
 RETURN waiter_id;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 RETURN -1;
END;
/

--Create a procedure to hire a waiter
CREATE OR REPLACE PROCEDURE HIRE_WAITER (
 waiter_name_new VARCHAR,
 restaurant_name_new VARCHAR
)
AS
 restaurant_id_new INTEGER; --New variable to store the restaurant id
BEGIN
--Store the Given restaurant Id in the new variable
 restaurant_id_new := FIND_RESTAURANT_ID(restaurant_name_new);
--Insert the values in the table Waiter
 INSERT INTO Waiter VALUES(WaiterID_SEQ.NEXTVAL, waiter_name_new, restaurant_id_new);
--Print that the data is added with the waiter name
 dbms_output.put_line('Data is added for waiter -' || waiter_name_new );
--Exception conditions
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 dbms_output.put_line('Restaurant Not Found');
 WHEN OTHERS THEN
 dbms_output.put_line('Error has occurred while adding the waiter information');
 END;
/

--Procedure to show all waiters working in a restaurant
CREATE OR REPLACE PROCEDURE SHOW_WAITERS (
 restaurant_name_n VARCHAR
)
AS
 restaurant_id_n INTEGER;
 waiters Waiter%ROWTYPE;
BEGIN
 restaurant_id_n := FIND_RESTAURANT_ID(restaurant_name_n);
 DBMS_OUTPUT.PUT_LINE('List of waiters working in '||restaurant_name_n);
--Loop for the select Statement to get all the waiters working in a particular restaurant
 FOR waiters IN (SELECT * FROM Waiter WHERE rid = restaurant_id_n) LOOP
--Display all the waiters working in a particular restaurant
 DBMS_OUTPUT.PUT_LINE('Waiter ID- ' || waiters.wid || ', Waiter Name- ' || waiters.wname);
 END LOOP;
--Exception statement
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 DBMS_OUTPUT.PUT_LINE('No data found.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An error occurred');
END;
/

-- D3: Create a procedure to Report tips: Show total tips by each waiter.
CREATE OR REPLACE PROCEDURE Report_Tips AS
BEGIN
DBMS_OUTPUT.PUT_LINE('Report Tips by each Waiter');
 FOR i IN (
 -- Select statement to get the waiter's name and sum of tips from orders
 SELECT w.wname AS waiter_name, NVL(SUM(o.Tip),0) AS total_tips
 FROM waiter w, orders o
 WHERE w.wid = o.wid(+) -- Left join is used to include all waiters
 GROUP BY w.wname -- Group by waiter to sum up the tips for each waiter
 ORDER BY total_tips
 )
 LOOP
 -- Print waiter's name and total tips
 DBMS_OUTPUT.PUT_LINE('Waiter Name: ' || i.waiter_name || '; Total Tips: $' || i.total_tips);
 END LOOP;
-- Handle exceptions and errors
EXCEPTION
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- D3: Create a procedure to Report tips by state: Show total tips earned by waiters per state
CREATE OR REPLACE PROCEDURE Report_tips_by_state AS
BEGIN
DBMS_OUTPUT.PUT_LINE('Report Tips by State');
 FOR i IN (
 -- Select statement to get State and sum of tips from orders
 SELECT State,NVL(SUM(tip),0) AS total_tips
 FROM Restaurant r, Orders o
 WHERE r.rid=o.rid(+) -- Left join is used to include all states
 GROUP BY State -- Group by state to sum up the tips by each waiter
 Order BY total_tips
 )
 LOOP
 -- Print State and total tips
 DBMS_OUTPUT.PUT_LINE('State: ' || i.State || '; Total Tips: $' || i.total_tips);
 END LOOP;
-- Handle exceptions and errors
EXCEPTION
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-----Function to find the menu_item_id
CREATE OR REPLACE FUNCTION FIND_MENU_ITEM_ID(i_menu_item_name IN VARCHAR)
RETURN INT AS
 o_menu_item_id INT;
BEGIN
 SELECT menu_item_id INTO o_menu_item_id
 FROM Menu_Items
 WHERE menu_item_name = i_menu_item_name;
 RETURN o_menu_item_id;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 DBMS_OUTPUT.PUT_LINE('No menu item found.');
 RETURN -1;
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE || '. Error Message: ' || SQLERRM);
 RETURN -1;
END;
/

----Procedure to insert menu_items into to restaurants
CREATE OR REPLACE PROCEDURE create_menu_item(i_cuisine_name IN VARCHAR, i_item_name IN VARCHAR, i_price IN DECIMAL) IS
 o_cuisine_type_id NUMBER;
 o_menu_item_id INT;
BEGIN
 -- Get the cuisine type ID using the function
 o_cuisine_type_id := find_cuisine_id(i_cuisine_name);
 IF o_cuisine_type_id IS NOT NULL THEN
 -- Get the next menu_item_id from the sequence
 o_menu_item_id := menu_item_seq.nextval;
 -- Insert the menu item into the Menu_Items table
 INSERT INTO Menu_Items (menu_item_id, cid, menu_item_name, price)
 VALUES (o_menu_item_id, o_cuisine_type_id, i_item_name, i_price);

 DBMS_OUTPUT.PUT_LINE('Menu item ' || i_item_name || ' added successfully.');
 ELSE
 DBMS_OUTPUT.PUT_LINE('Cuisine type not found.');
 END IF;
EXCEPTION
 -- Prints an error message if the cuisine type is not found.
 WHEN no_data_found THEN
 DBMS_OUTPUT.PUT_LINE('Error is found because there is no data.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE || '. Error Message: ' || SQLERRM);
END;
/

-----Procedure to add menu_items to the inventory
CREATE OR REPLACE PROCEDURE add_menu_item_to_inventory(
 i_menu_item_name IN VARCHAR,
 i_restaurant_name IN VARCHAR,
 i_quantity IN INT
) IS
 o_menu_item_id INT;
 o_restaurant_id INT;
 o_inventory_id INT; 
BEGIN
 -- Find the menu item ID
 o_menu_item_id := FIND_MENU_ITEM_ID(i_menu_item_name);
 -- Find the restaurant ID
 o_restaurant_id := find_restaurant_id(i_restaurant_name);
 -- Check if both menu item ID and restaurant ID are found
 IF o_menu_item_id IS NOT NULL AND o_restaurant_id IS NOT NULL THEN
 -- Get the next value from the sequence for inventory_id
 o_inventory_id := inventory_seq.nextval;
 -- Insert the menu item into the Restaurant Inventory table
 INSERT INTO Restaurant_Inventory (inventory_id, menu_item_id, menu_item_name, rid, quantity)
 VALUES (o_inventory_id, o_menu_item_id, i_menu_item_name, o_restaurant_id, i_quantity);
 -- Print success message
 DBMS_OUTPUT.PUT_LINE('Menu item ' || i_menu_item_name || ' added to ' || i_restaurant_name || ' with quantity ' || i_quantity);
 ELSE
 -- Print error message if either menu item or restaurant is not found
 DBMS_OUTPUT.PUT_LINE('Menu item or restaurant not found.');
 END IF;
EXCEPTION
 WHEN OTHERS THEN
 -- Print an error message if any exception occurs
 DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE || '. Error Message: ' || SQLERRM);
END;
/

----Procedure to update the inventory when an order is placed
CREATE OR REPLACE PROCEDURE update_menu_item_inventory(
 i_rest_id IN INT,
 i_item_id IN INT,
 i_quantity IN INT
) IS
 o_curr_quantity INT;
BEGIN
 -- Find the current quantity of the menu item in the Restaurant Inventory
 SELECT quantity INTO o_curr_quantity
 FROM Restaurant_Inventory
 WHERE rid = i_rest_id AND menu_item_id = i_item_id;
 -- Check if the current quantity is greater than or equal to the ordered quantity
 IF o_curr_quantity >= i_quantity THEN
 -- Update the quantity in the Restaurant Inventory
 UPDATE Restaurant_Inventory
 SET quantity = quantity - i_quantity
 WHERE rid = i_rest_id AND menu_item_id = i_item_id;
 DBMS_OUTPUT.PUT_LINE('Restaurant Inventory is updated successfully.');
 ELSE
 DBMS_OUTPUT.PUT_LINE('There is not enough inventory.');
 END IF;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 DBMS_OUTPUT.PUT_LINE('No data found for the given restaurant and menu item.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE || '. Error Message: ' || SQLERRM);
END;
/

-- Procedure to report the total quantity of each menu item for each cuisine type
CREATE OR REPLACE PROCEDURE report_menu_items IS
BEGIN
 -- Loop through each cuisine type and menu item to calculate and display the total quantity
 FOR rep IN (
 SELECT
 c.cuisine_type,
 m.menu_item_name,
 SUM(ri.quantity) AS total_quantity
 FROM
 Cuisine c, Menu_Items m, Restaurant_Inventory ri
 WHERE
 c.cid = m.cid AND
 m.menu_item_id = ri.menu_item_id
 GROUP BY
 c.cuisine_type, m.menu_item_name
 ORDER BY
 c.cuisine_type, m.menu_item_name
 )
 LOOP
 -- Display the total quantity for each menu item and cuisine type
 DBMS_OUTPUT.PUT_LINE('For ' || rep.cuisine_type || ', the total quantity of ' || rep.menu_item_name || ' is ' || rep.total_quantity ||
'.');
 END LOOP;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 DBMS_OUTPUT.PUT_LINE('No data found.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE || '. Error Message: ' || SQLERRM);
END;
/

-- Create a Procedure to add customer
CREATE OR REPLACE PROCEDURE ADD_CUSTOMER(
p_customer_name IN VARCHAR,
p_email IN VARCHAR,
p_street_address IN VARCHAR,
p_city IN VARCHAR,
p_state IN VARCHAR,
p_zip IN VARCHAR,
p_credit_card_num IN VARCHAR)
AS
BEGIN
INSERT INTO Customer VALUES(customer_id_seq.nextval,p_customer_name,p_email,
p_street_address,p_city,p_state,p_zip ,p_credit_card_num);
EXCEPTION
WHEN Others THEN
 DBMS_OUTPUT.PUT_LINE('Error Occur');
END;
/

-- Create function for finding a customer id
CREATE OR REPLACE FUNCTION find_customer_id ( cname IN VARCHAR) RETURN NUMBER
IS
c_id NUMBER ;
BEGIN
 SELECT customer_id INTO c_id FROM customer WHERE customer_name = cname;
 RETURN c_id ;
EXCEPTION
 WHEN no_data_found THEN
 DBMS_OUTPUT.PUT_LINE('no such customer');
 RETURN -1;
END;
/

-- Create procedure for adding order
CREATE OR REPLACE PROCEDURE ADD_ORDERS(
p_restaurant_name IN VARCHAR,
p_customer_name IN VARCHAR,
p_order_date IN DATE,
p_menu_item_name IN VARCHAR,
p_waiter_name IN VARCHAR,
number_of_menu IN NUMBER)
IS
p_restaurant_id INTEGER;
p_customer_id INTEGER;
p_menu_item_id INTEGER;
p_waiter_id INTEGER;
amount_paid DECIMAL(8, 2);
tip DECIMAL(8, 2);
BEGIN
p_restaurant_id := find_restaurant_id(p_restaurant_name);
p_customer_id:= find_customer_id(p_customer_name);
p_menu_item_id:= find_menu_item_id(p_menu_item_name);
p_waiter_id:= find_waiter_id(p_waiter_name);
SELECT price INTO amount_paid FROM menu_items WHERE menu_item_id = p_menu_item_id;
amount_paid := amount_paid*number_of_menu;
tip := amount_paid*0.2;
INSERT INTO orders VALUES(order_id_seq.nextval,p_restaurant_id,p_customer_id,
p_order_date,p_menu_item_id,p_waiter_id,amount_paid,tip);
DBMS_OUTPUT.PUT_LINE('Order has been  added.');
EXCEPTION
WHEN no_data_found THEN
DBMS_OUTPUT.PUT_LINE('Data is not found');
WHEN Others THEN
DBMS_OUTPUT.PUT_LINE('Error Occur');
END;
/

-- CREATE ADD_REVIEW PROCEDURE �
CREATE OR REPLACE PROCEDURE ADD_REVIEW (res_name IN VARCHAR, rev_email IN VARCHAR, rev_stars IN FLOAT, r_text IN VARCHAR)
AS
rest_id INT;
INVALID_NO_OF_STARS exception;
BEGIN
IF rev_stars < 1 OR rev_stars > 5 THEN RAISE INVALID_NO_OF_STARS;
 END IF;
rest_id := find_restaurant_id(res_name); --get restaurant id from restaurant name
INSERT INTO Reviews VALUES (reviewID_seq.nextval,rest_id,rev_email,rev_stars,r_text);
EXCEPTION --Handling Exceptions
WHEN INVALID_NO_OF_STARS THEN
 DBMS_OUTPUT.PUT_LINE('Error: Stars must be a number between 1-5.');
WHEN Others THEN
 DBMS_OUTPUT.PUT_LINE('Error Occurred');
END;
/

-- CREATE FIND_REVIEW_ID helper function �
CREATE OR REPLACE FUNCTION FIND_REVIEW_ID (email IN VARCHAR) RETURN NUMBER
IS
rev_id NUMBER;
BEGIN
 SELECT reviewID into rev_id FROM Reviews WHERE reviewer_email = email;
 RETURN rev_id ;
EXCEPTION
 WHEN no_data_found THEN
 DBMS_OUTPUT.PUT_LINE('no such review');
 RETURN -1;
END;
/

-- CREATE INSERT_RECOMMENDATIONS procedure �
CREATE OR REPLACE PROCEDURE INSERT_RECOMMENDATIONS (cus_name IN VARCHAR, rest_name IN VARCHAR, rec_date IN DATE)
AS
cus_id INT;
res_id INT;
BEGIN
cus_id := find_customer_id(cus_name);
res_id := find_restaurant_id(rest_name);
INSERT INTO Recommendations VALUES (recommendationID_seq.nextval,cus_id,res_id,rec_date);
EXCEPTION
WHEN Others THEN
 DBMS_OUTPUT.PUT_LINE('Error Occurred');
END;
/

-- CREATE BUY_OR_BEWARE procedure �
CREATE OR REPLACE PROCEDURE BUY_OR_BEWARE (x IN NUMBER)
AS
Cursor c1 is SELECT * FROM (SELECT round(avg(stars_given),2) as avg_stars, restaurant_name, restaurantID, cuisine_type, round(stddev
(stars_given),2) as st_dev
FROM ((Reviews
 INNER JOIN restaurant ON restaurant.rid = Reviews.restaurantID)
 INNER JOIN cuisine ON cuisine.cid = restaurant.cid)
 GROUP BY restaurantID, restaurant_name, cuisine_type
 ORDER BY avg_stars DESC)
 WHERE ROWNUM <= x; --Creating cursor c1
Cursor c2 is SELECT * FROM (SELECT round(avg(stars_given),2) as stars_average, restaurant_name, restaurantID, cuisine_type, round(stddev
(stars_given),2) as dev FROM ((Reviews
 INNER JOIN restaurant ON restaurant.rid = Reviews.restaurantID)
 INNER JOIN cuisine ON cuisine.cid = restaurant.cid)
 GROUP BY restaurantID, restaurant_name, cuisine_type
 ORDER BY stars_average)
 WHERE ROWNUM <= x; --Creating cursor c2
BEGIN
 dbms_output.put_line('Top rated restaurants'); --Printing the top rated restaurants
 for item in c1 --Start of for loop
 loop
 dbms_output.put_line('Average number of stars: ' || item.avg_stars || ' | Restaurant ID: ' || item.restaurantID || ' | Restaurant Name: ' ||
item.restaurant_name || ' | Cuisine Type: ' || item.cuisine_type || ' | Standard deviation: ' || item.st_dev);
 End loop; --End of for loop
 dbms_output.put_line('Buyer Beware:Stay Away from...'); --Print buyer beware restaurants
 for items in c2 --Start of for loop
 loop
 dbms_output.put_line('Average number of stars: ' || items.stars_average || ' | Restaurant ID: ' || items.restaurantID || ' | Restaurant Name: ' || items.restaurant_name || ' | Cuisine Type: ' || items.cuisine_type || ' | Standard deviation: ' || items.dev);
 End loop; --End of for loop
EXCEPTION --Handling Exceptions
 WHEN no_data_found THEN
 DBMS_OUTPUT.PUT_LINE('no such data');
END;
/

--Insert Recommendations: Calculates a Recommendation to customer--
CREATE OR REPLACE PROCEDURE RECOMMEND_TO_CUSTOMER (cus_id IN INT, cuisine_type IN VARCHAR)
AS

 Cursor c1 is SELECT restaurantID FROM(SELECT max(stars_given), restaurantID FROM Reviews
 JOIN restaurant ON Reviews.restaurantID = restaurant.rid
 AND restaurant.cuisine_specialty = cuisine_type
 GROUP BY restaurantID
 )sub
 LEFT JOIN (
 SELECT DISTINCT rid FROM orders
 WHERE orders.customer_id = cus_id
 )visited ON sub.restaurantID = visited.rid
 WHERE visited.rid IS NULL
 AND ROWNUM = 1;
todays_date date;
no_such_restuarant EXCEPTION;
cnt number := 0;
BEGIN
 SELECT sysdate INTO todays_date FROM dual;
 for item in c1
 loop
 INSERT INTO Recommendations VALUES (recommendationID_seq.nextval,cus_id,item.restaurantID,todays_date);
 cnt := cnt + 1;
 End loop;
 if cnt = 0
 then
 raise no_such_restuarant;
 end if;
 EXCEPTION
 WHEN no_such_restuarant THEN
 DBMS_OUTPUT.PUT_LINE('No such restaurant with the given cuisine type');
 WHEN no_data_found THEN
 DBMS_OUTPUT.PUT_LINE('no such data');
 WHEN Others THEN
 DBMS_OUTPUT.PUT_LINE('Error Occurred');
END;
/

--Provide a report that lists all customer recommendations--
CREATE or REPLACE PROCEDURE LIST_RECOMMENDATIONS
AS
Cursor c1 is SELECT customer.customer_name,
 restaurant.restaurant_name,
 cuisine.cuisine_type,
 round(avg(stars_given),2) AS average_stars
 FROM Recommendations
 JOIN customer ON Recommendations.customerID = customer.customer_id
 JOIN Restaurant ON Recommendations.recommended_rid = Restaurant.rid
 JOIN cuisine ON Restaurant.cuisine_specialty = cuisine.cuisine_type
 JOIN Reviews ON Recommendations.recommended_rid = Reviews.restaurantID
 GROUP BY customer_name, restaurant_name, cuisine_type;
BEGIN
dbms_output.put_line('All Customer Recommendations');
for item in c1
loop
dbms_output.put_line('Customer name: ' || item.customer_name || ' | Restaurant Name: ' || item.restaurant_name || ' | Cuisine Type: ' || item.
cuisine_type || ' | Average number of stars: ' || item.average_stars);
End loop;
EXCEPTION
 WHEN no_data_found THEN
 DBMS_OUTPUT.PUT_LINE('no such data');
End;
/

-- List names of all customers who live in a given zip code
-- create procedure get_CustomersByZip
CREATE OR REPLACE PROCEDURE get_CustomersByZip(x IN VARCHAR) AS
 CURSOR c1 IS SELECT customer_name FROM customer WHERE zip = x; --creating the cursor c1
c_name c1%ROWTYPE; --declaring a variable
BEGIN
 OPEN c1; --Opening the cursor
 LOOP --Start of Loop
 FETCH c1 INTO c_name;
 EXIT WHEN c1%NOTFOUND;
 DBMS_OUTPUT.PUT_LINE(c_name.customer_name); --printing the output
 END LOOP; --End of Loop
 if c1%rowcount = 0 then
 dbms_output.put_line('Please enter a Valid Zip Code');
 end if;
 CLOSE c1; --Closing the cursor
EXCEPTION --adding exception to the procedure
 WHEN NO_DATA_FOUND THEN --no data found exception
 DBMS_OUTPUT.PUT_LINE('No customers found with the given ZIP code.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
END;
/

-- For each cuisine type identify the most popular restaurant based on number of orders generated
-- create procedure get_PopularRestaurant
CREATE OR REPLACE PROCEDURE get_PopularRestaurant AS
CURSOR c1 IS --creating the cursor c1
 SELECT r.cuisine_specialty, r.restaurant_name, COUNT(o.order_id) AS Orders
 FROM restaurant r JOIN orders o ON r.rid = o.rid
 GROUP BY r.cuisine_specialty, r.restaurant_name
 ORDER BY r.cuisine_specialty, Orders DESC;
x c1%ROWTYPE; --declaring a variable
BEGIN
 OPEN c1; --Opening the cursor
 LOOP --Start of Loop
 FETCH c1 INTO x;
 EXIT WHEN c1%NOTFOUND;
 DBMS_OUTPUT.PUT_LINE('Cuisine: ' || x.cuisine_specialty || '| Restaurant: ' || x.restaurant_name || '| Orders: ' || x.Orders); --
--printing the output
 END LOOP; --End of Loop
 CLOSE c1; --Closing the cursor
EXCEPTION --adding exception to the procedure
 WHEN NO_DATA_FOUND THEN --no data found exception
 DBMS_OUTPUT.PUT_LINE('No data found.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
END;
/
 
-- Member 4 Procedure
-- Create a procedure for showing list of order based on a given date and restaurant name
CREATE OR REPLACE PROCEDURE show_orders(given_restaurant_name VARCHAR, given_date DATE) AS
 CURSOR c1 IS
 SELECT o.order_id, o.customer_id, o.menu_item_id, o.wid, o.amount_paid, o.tip
 FROM restaurant r JOIN orders o ON r.rid = o.rid
 WHERE r.restaurant_name = given_restaurant_name AND o.order_date = given_date;
BEGIN
 DBMS_OUTPUT.PUT_LINE('Show all orders in ' || given_restaurant_name || ' on ' || given_date);
 FOR item IN c1 LOOP
 DBMS_OUTPUT.PUT_LINE('order id: ' || item.order_id || ' customer id: ' || item.customer_id ||
 ' menu item id: ' || item.menu_item_id || ' waiter id: ' || item.wid ||
 ' amount paid: ' || item.amount_paid || ' tip: ' || item.tip);
 END LOOP;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 DBMS_OUTPUT.PUT_LINE('There is no data found');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('Error occurs');
END;
/

-- Create a procedure for showing the top 3 restaurants of each state. The ranking is based on the total of �amount paid� per restaurant per state.
CREATE OR REPLACE PROCEDURE generate_restaurant AS
CURSOR c1 IS
SELECT state, restaurant_name, total_amount_paid
FROM (SELECT r.state, r.restaurant_name, SUM(o.amount_paid) AS total_amount_paid,
 DENSE_RANK() OVER (PARTITION BY r.state ORDER BY SUM(o.amount_paid) DESC) AS rank
 FROM restaurant r,orders o WHERE r.rid = o.rid
 GROUP BY r.state, r.restaurant_name)
WHERE rank <= 3
ORDER BY state, rank;
BEGIN
DBMS_OUTPUT.PUT_LINE('Show top 3 restaurant of each state');
FOR item in c1 LOOP
 DBMS_OUTPUT.PUT_LINE('State: ' || item.state ||' Restaurant Name: ' || item.restaurant_name || ' Total Amount: '|| item.
total_amount_paid );
END LOOP;
END;
/

--EXECUTABLE COMMANDS CALLING THE PROCEDURES
SET SERVEROUTPUT ON;
BEGIN
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE (' ========== Below are Member 1 Operations ===========');
DBMS_OUTPUT.PUT_LINE (' ===============================================');
-- Add Cuisine
ADD_CUISINE('American');
ADD_CUISINE('BBQ');
ADD_CUISINE('Indian');
ADD_CUISINE('Italian');
ADD_CUISINE('Ethiopian');
-- Add Restaurant
Add_Restaurant('Ribs R US','4912 N 5TH ST',' Philadelphia', 21250, 'PA', 'American');
Add_Restaurant('Bella Italia', '456 Maple Ave', 'Another Town', 21043, 'MD', 'Italian');
Add_Restaurant('Selasie', '296 Maes ST', 'Eldersburg', 16822, 'PA', 'Ethiopian');
Add_Restaurant('Roma', '885 Manchester Ave', 'Piedmont', 21043, 'GA', 'Italian');
Add_Restaurant('Taj Mahal', '233 Johnsville Rd', 'Bellmore', 10013, 'NY', 'Indian');
Add_Restaurant('Ethiop', '987 Southwestern Ave', 'Allentown', 16822, 'PA', 'Ethiopian');
Add_Restaurant('Bull Roast', '158 Hester Street', 'New York', 10013, 'NY', 'BBQ');
--Call the Report By Income Procedure
DISPLAY_RESTAURANTS_BY_CUISINE('Ethiopian');
DISPLAY_RESTAURANTS_BY_CUISINE('Italian');
--Call the Report By Income Procedure
REPORT_INCOME_BY_STATE;
END;
/

--Select statements to verify that the restaurant and cuisine data has been added
select * from Cuisine;
select * from restaurant;

BEGIN
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE (' ========== Below are Member 2 Operations ===========');
DBMS_OUTPUT.PUT_LINE (' ===============================================');
--Insert the data provided in the scenario 2
HIRE_WAITER('Jack','Ribs R US');
HIRE_WAITER('Jill','Ribs R US');
HIRE_WAITER('Wendy','Ribs R US');
HIRE_WAITER('Hailey','Ribs R US');
HIRE_WAITER('Mary','Bella Italia');
HIRE_WAITER('Pat','Bella Italia');
HIRE_WAITER('Michael','Bella Italia');
HIRE_WAITER('Rakesh','Bella Italia');
HIRE_WAITER('Verma','Bella Italia');
--Insert the data provided in scenario 3
HIRE_WAITER('Mike','Roma');
HIRE_WAITER('Judy','Roma');
HIRE_WAITER('Trevor','Selasie');
HIRE_WAITER('Gupta','Taj Mahal');
HIRE_WAITER('Trisha','Ethiop');
HIRE_WAITER('Hannah','Bull Roast');
--Show list of waiters in the Bella Italia restaurant
DBMS_OUTPUT.PUT_LINE('===============================================');
SHOW_WAITERS('Bella Italia');
DBMS_OUTPUT.PUT_LINE('===============================================');
--Show list of waiters in the Taj Mahal restaurant
SHOW_WAITERS('Taj Mahal');
END;
/
----Member 3
BEGIN
DBMS_OUTPUT.PUT_LINE('===============================================');
DBMS_OUTPUT.PUT_LINE('========== Below are Member 3 Operations ========');
DBMS_OUTPUT.PUT_LINE('===============================================');
 -- Adding menu items based on the cuisine type and prices 
create_menu_item('American', 'burger', 10);
create_menu_item('American', 'fries', 5);
create_menu_item('American', 'pasta', 15);
create_menu_item('American', 'salad', 10);
create_menu_item('American', 'salmon', 20);
create_menu_item('Italian', 'Lasagna', 15);
create_menu_item('Italian', 'meatballs', 10);
create_menu_item('Italian', 'spaghetti', 15);
create_menu_item('Italian', 'pizza', 20);
create_menu_item('BBQ', 'steak', 25);
----- create_menu_item('BBQ', 'burger', 10);
create_menu_item('BBQ', 'pork loin', 15);
create_menu_item('BBQ', 'filet mignon', 30);
create_menu_item('Indian', 'dal soup', 10);
create_menu_item('Indian', 'rice', 5);
create_menu_item('Indian', 'tandoori chicken', 10);
create_menu_item('Indian', 'samosa', 8);
create_menu_item('Ethiopian', 'meat chunks', 12);
create_menu_item('Ethiopian', 'legume stew', 10);
create_menu_item('Ethiopian', 'flatbread', 3);
DBMS_OUTPUT.PUT_LINE(' ');
---- Adding quantity to the restaurant inventory 
add_menu_item_to_inventory('burger', 'Ribs R US', 50);
add_menu_item_to_inventory('fries', 'Ribs R US', 150);
add_menu_item_to_inventory('Lasagna', 'Bella Italia', 10);
add_menu_item_to_inventory('steak', 'Bull Roast', 15);
add_menu_item_to_inventory('pork loin', 'Bull Roast', 50);
add_menu_item_to_inventory('filet mignon', 'Bull Roast', 5);
add_menu_item_to_inventory('dal soup', 'Taj Mahal', 50);
add_menu_item_to_inventory('rice', 'Taj Mahal', 500);
add_menu_item_to_inventory('samosa', 'Taj Mahal', 150);
add_menu_item_to_inventory('meat chunks', 'Selasie', 150);
add_menu_item_to_inventory('legume stew', 'Selasie', 150);
add_menu_item_to_inventory('flatbread', 'Selasie', 500);
add_menu_item_to_inventory('meat chunks', 'Ethiop', 150);
add_menu_item_to_inventory('legume stew', 'Ethiop', 150);
add_menu_item_to_inventory('flatbread', 'Ethiop', 500);
DBMS_OUTPUT.PUT_LINE(' ');
 --generating report menu items 
report_menu_items;
DBMS_OUTPUT.PUT_LINE(' ');
--- Updating inventory based on the restaurant_id,menu_item_id and quantity
update_menu_item_inventory(find_restaurant_id('Taj Mahal'), find_menu_item_id('rice'), 25);
update_menu_item_inventory(find_restaurant_id('Selasie'), find_menu_item_id('meat chunks'), 50);
update_menu_item_inventory(find_restaurant_id('Bull Roast'), find_menu_item_id('filet mignon'), 2);
update_menu_item_inventory(find_restaurant_id('Bull Roast'), find_menu_item_id('filet mignon'), 2);
DBMS_OUTPUT.PUT_LINE(' ');
-- Display initial inventory for Ethiop restaurant
DBMS_OUTPUT.PUT_LINE('--------------- Initial Inventory for Ethiop restaurant -------------------');
FOR i IN (SELECT * FROM Restaurant_Inventory WHERE rid = find_restaurant_id('Ethiop')) LOOP
DBMS_OUTPUT.PUT_LINE('Inventory ID: ' || i.inventory_id || ', Menu Item ID: ' || i.menu_item_id || ', Menu Item Name: ' || i.menu_item_name || ', Quantity: ' || i.quantity);
END LOOP;

DBMS_OUTPUT.PUT_LINE(' ');
-- Update inventory based on the restaurant_id,menu_item_id and quantity
update_menu_item_inventory(find_restaurant_id('Ethiop'), find_menu_item_id('meat chunks'), 30);
update_menu_item_inventory(find_restaurant_id('Ethiop'), find_menu_item_id('meat chunks'), 30);
update_menu_item_inventory(find_restaurant_id('Ethiop'), find_menu_item_id('legume stew'), 20);
 -- Display final inventory for Ethiop restaurant
DBMS_OUTPUT.PUT_LINE('--------------- Final Inventory for Ethiop restaurant -------------------');
FOR i IN (SELECT * FROM Restaurant_Inventory WHERE rid = find_restaurant_id('Ethiop')) LOOP
DBMS_OUTPUT.PUT_LINE('Inventory ID: ' || i.inventory_id || ', Menu Item ID: ' || i.menu_item_id || ', Menu Item Name: ' || i.menu_item_name || ', Quantity: ' || i.quantity);
END LOOP;
DBMS_OUTPUT.PUT_LINE(' ');
-- generating Report of  menu items 
 report_menu_items;
END;
/















-- Member4
BEGIN
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE (' ========== Below are Member 4 Operations ===========');
DBMS_OUTPUT.PUT_LINE (' ===============================================');
-- Add Customers
ADD_CUSTOMER('Cust1','cust1@gmail.com','9225 Osprey Ct','Columbia','MD','21045','374245455400126');
ADD_CUSTOMER('Cust11','cust11@gmail.com','9310 Mellenbrook Rd','Columbia','MD','21045','378282246310005');
ADD_CUSTOMER('Cust3','cust3@gmail.com','6606 Allview Dr','Columbia','MD','21046','5425233430109903');
ADD_CUSTOMER('Cust111','cust3@gmail.com','9217 Adalee Ct','Columbia','MD','21045','4263982640269299');
-- Add Customers who live in NY
ADD_CUSTOMER('CustNY1','CustNY1@gmail.com','8 Liberty Pl','New York','NY','10045','4259982543268280');
ADD_CUSTOMER('CustNY2','CustNY2@gmail.com','33 LIBERTY ST','New York','NY','10045','2410778368421318');
ADD_CUSTOMER('CustNY3','CustNY3@gmail.com','WILLIAM ST','New York','NY','10045','5723755097712020');
-- Add Customers who live in PA
ADD_CUSTOMER('CustPA1','CustPA1@gmail.com','86 Harrison St','Beech Creek','PA','16822','8001925710931057');
ADD_CUSTOMER('CustPA2','CustPA2@gmail.com','93 Locust St','Beech Creek','PA','16822','6941803106182243');
ADD_CUSTOMER('CustPA3','CustPA3@gmail.com','317 Maple Ave','Beech Creek','PA','16822','5459942428642448');
ADD_CUSTOMER('CustPA4','CustPA4@gmail.com','328 Maple Ave','Beech Creek','PA','16822','5200533989557118');
ADD_CUSTOMER('CustPA5','CustPA5@gmail.com','322 Maple Ave','Beech Creek','PA','16822','6676035368275142');
ADD_CUSTOMER('CustPA6','CustPA6@gmail.com','302 Maple Ave','Beech Creek','PA','16822','6322362065237412');
END;
/
-- Show list of customer name who living in 21045 zip code
SELECT customer_name FROM customer WHERE zip = '21045';
/
-- Place orders
BEGIN
ADD_ORDERS('Bella Italia','Cust1',date'2024-3-10','pizza','Mary',1);
ADD_ORDERS('Bella Italia','Cust11',date'2024-3-15','spaghetti','Mary',2);
ADD_ORDERS('Bella Italia','Cust11',date'2024-3-15','pizza','Mary',1);
-- Place new orders
ADD_ORDERS('Bull Roast','CustNY1',date'2024-4-1','filet mignon','Hannah',2);
ADD_ORDERS('Bull Roast','CustNY1',date'2024-4-2','filet mignon','Hannah',2);
ADD_ORDERS('Bull Roast','CustNY2',date'2024-4-1','pork loin','Hannah',1);

ADD_ORDERS('Ethiop','CustPA1',date'2024-4-1','meat chunks','Trisha',10);
ADD_ORDERS('Ethiop','CustPA1',date'2024-5-1','meat chunks','Trisha',10);
ADD_ORDERS('Ethiop','CustPA1',date'2024-5-10','meat chunks','Trisha',10);
ADD_ORDERS('Ethiop','CustPA2',date'2024-5-1','legume stew','Trevor',10);
ADD_ORDERS('Ethiop','CustPA2',date'2024-5-11','legume stew','Trevor',10);
ADD_ORDERS('Taj Mahal','CustPA2',date'2024-5-1','samosa','Trevor',10);

ADD_ORDERS('Selasie','CustNY2',date'2024-4-1','meat chunks','Trevor',4);
ADD_ORDERS('Ribs R US','CustNY1',date'2024-4-1','burger','Jack',4);
ADD_ORDERS('Ribs R US','CustNY2',date'2024-4-2','burger','Jill',4);
ADD_ORDERS('Ribs R US','CustNY2',date'2024-4-1','pork loin','Jack',1);
ADD_ORDERS('Ribs R US','CustNY2',date'2024-4-1','meat chunks','Trevor',4);
END;
/
BEGIN
DBMS_OUTPUT.PUT_LINE('Show all orders at Selasie on April 1, 2024');
show_orders('Selasie', date'2024-4-1');
DBMS_OUTPUT.PUT_LINE('Show all orders at Ribs R US on April 1, 2024');
show_orders('Ribs R US', date'2024-4-1');
DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE('Showing the top 3 restaurants of each state');
generate_restaurant;
END;
/
--Member 5:
BEGIN
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE (' ========== Below are Member 5 Operations ===========');
DBMS_OUTPUT.PUT_LINE (' ===============================================');
--Add Reviews--
ADD_REVIEW ('Ribs R US','cust1@gmail.com',4,'Wonderful place, but expensive');
ADD_REVIEW ('Bella Italia','cust1@gmail.com',2,'Very bad food. I�m Italian and Bella Italia does NOT give you authentic Italian food');
ADD_REVIEW ('Ribs R US','abc@abc.com',4, 'I liked the food. Good experience');
ADD_REVIEW ('Ribs R US','dce@abc.com',5,'Excellent');
ADD_REVIEW ('Bella Italia','abc@abc.com',3,'So-so');
ADD_REVIEW ('Selasie','abc@abc.com',4,'I liked the food. Authentic Ethiopian experience');
ADD_REVIEW ('Selasie','cust1@gmail.com',5,'Excellent flavor. Highly recommended');
ADD_REVIEW ('Ribs R US','abc@abc.com',2,'So-so. Low quality beef');
ADD_REVIEW ('Taj Mahal','abc@abc.com',5,'Best samosas ever');
ADD_REVIEW ('Taj Mahal','cust1@gmail.com',4,'I enjoyed their samosas, but did not like the dal');
ADD_REVIEW ('Taj Mahal','zzz@abc.com',5,'Excellent samosas');
ADD_REVIEW ('Taj Mahal','surajit@abc.com',3,'Not really authentic');
ADD_REVIEW ('Bull Roast','dce@abc.com',5,'Excellent');
ADD_REVIEW ('Bull Roast','abc@abc.com',3,'Just fine');
ADD_REVIEW ('Bull Roast','abc@abc.com',4,'I liked the food');

DBMS_OUTPUT.PUT_LINE('===============================================');
--Execute the Buy Or Beware procedure--
BUY_OR_BEWARE(2);
DBMS_OUTPUT.PUT_LINE('===============================================');
--Insert Recommendations--
RECOMMEND_TO_CUSTOMER(find_customer_id('Cust111'),'BBQ');
RECOMMEND_TO_CUSTOMER(find_customer_id('Cust111'),'Indian');
--List all Customer Recommendations--
LIST_RECOMMENDATIONS;
END;
/

--Select statements to verify that the reviews and recommendations data has been added
select * from Reviews;
select * from Recommendations;

--MEMBER 6:
/* List names of all customers who live in a given zip code */
CREATE OR REPLACE PROCEDURE get_CustomersByZip(x IN VARCHAR) AS
CURSOR c1 IS --creating the cursor c1
 SELECT customer_name FROM customer
 WHERE zip = x;
c_name c1%ROWTYPE; --declaring a variable
BEGIN
OPEN c1; --Opening the cursor
LOOP --Start of Loop
 FETCH c1 INTO c_name;
 EXIT WHEN c1%NOTFOUND;
 DBMS_OUTPUT.PUT_LINE(c_name.customer_name); --printing the output
 END LOOP; --End of Loop
 IF c1%ROWCOUNT = 0 then
 DBMS_OUTPUT.PUT_LINE ('Please enter a Valid Zip Code');
 END IF;
CLOSE c1; --Closing the cursor
EXCEPTION --adding exception to the procedure
 WHEN NO_DATA_FOUND THEN --no data found exception
 DBMS_OUTPUT.PUT_LINE('No customers found with the given ZIP code.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
END;
/
/* For each cuisine type identify the most popular restaurant based on number of orders generated */
CREATE OR REPLACE PROCEDURE get_PopularRestaurant AS
-- cursor to fetch cuisine type, restaurant name and total orders
CURSOR c1 IS
 SELECT c.cuisine_type, r.restaurant_name, COUNT(o.order_id) AS total_orders
 FROM restaurant r, orders o, cuisine c where r.rid = o.rid and r.cid=c.cid
 GROUP BY c.cuisine_type, r.restaurant_name
 ORDER BY c.cuisine_type, total_orders DESC;
v_cuisine_type cuisine.cuisine_type%TYPE;
v_restaurant_name restaurant.restaurant_name%TYPE;
v_total_orders number;
v_max_orders number;
v_prev_cuisine_type cuisine.cuisine_type%TYPE; -- To store previous cuisine type in loop
BEGIN
v_max_orders := 0;
v_prev_cuisine_type := null;
OPEN c1; --Open the cursor
LOOP --Start the Loop
 FETCH c1 INTO v_cuisine_type, v_restaurant_name, v_total_orders;
 EXIT WHEN c1%NOTFOUND;
-- storing the above result as the maximum orders
 IF v_cuisine_type != v_prev_cuisine_type THEN
 v_max_orders := v_total_orders;
 DBMS_OUTPUT.PUT_LINE('Cuisine: ' || v_cuisine_type ||
 '| Restaurant: ' || v_restaurant_name ||
 '| Orders: ' || v_total_orders); --printing the output
-- checking if the current orders are greater that the max orders recorded for this cuisine
 ELSIF v_total_orders >= v_max_orders THEN
 v_max_orders := v_total_orders;
 DBMS_OUTPUT.PUT_LINE('Cuisine: ' || v_cuisine_type ||
 '| Restaurant: ' || v_restaurant_name ||
 '| Orders: ' || v_total_orders); --printing the output
 END IF;
v_prev_cuisine_type := v_cuisine_type;-- update the previous cuisine type
END LOOP; --End the Loop
CLOSE c1; --Close the cursor
EXCEPTION --adding exception to the procedure
 WHEN NO_DATA_FOUND THEN --no data found exception
 DBMS_OUTPUT.PUT_LINE('No data found.');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
END;
/
/* For each cuisine type identify the most profitable restaurant based on number of amounts paid */
CREATE OR REPLACE PROCEDURE get_most_profitable_res AS
-- cursor to fetch cuisine type, restaurant name and total earnings
CURSOR c1 IS
 SELECT c.cuisine_type, r.restaurant_name, sum(o.amount_paid) AS total_earnings
 FROM orders o,restaurant r,cuisine c WHERE o.rid = r.rid and r.cid = c.cid
 GROUP BY c.cuisine_type, r.restaurant_name
 ORDER BY c.cuisine_type, sum(o.amount_paid) DESC;
v_cuisine_type cuisine.cuisine_type%TYPE;
v_restaurant_name restaurant.restaurant_name%TYPE;
v_total_earnings number;
v_max_earnings number;
v_prev_cuisine_type cuisine.cuisine_type%TYPE; -- To store previous cuisine type in loop
BEGIN
v_max_earnings := 0;
v_prev_cuisine_type := null;
OPEN c1; -- open the cursor
LOOP -- start the loop
 FETCH c1 INTO v_cuisine_type, v_restaurant_name, v_total_earnings;
 EXIT WHEN c1%NOTFOUND; -- exit the loop
-- storing the above result as the maximum earnings
 IF v_cuisine_type != v_prev_cuisine_type THEN
 v_max_earnings := v_total_earnings;
 DBMS_OUTPUT.PUT_LINE('Cuisine Type: ' || v_cuisine_type ||
 ' | Restaurant: ' || v_restaurant_name ||
 ' | Total Earnings: $' || v_total_earnings);
-- checking if the current earnings are greater that the max earnings recorded for this cuisine
 ELSIF v_total_earnings >= v_max_earnings THEN
 v_max_earnings := v_total_earnings;
 DBMS_OUTPUT.PUT_LINE('Cuisine Type: ' || v_cuisine_type ||
 ' | Restaurant: ' || v_restaurant_name ||
 ' | Total Earnings: $' || v_total_earnings);
 END IF;
-- update the previous cuisine type
v_prev_cuisine_type := v_cuisine_type;
END LOOP; -- end the loop
CLOSE c1; -- close the cursor
EXCEPTION --adding exception to the procedure
 WHEN NO_DATA_FOUND THEN --no data found exception
 DBMS_OUTPUT.PUT_LINE('No Data Found');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
END;
/
/* Report: Generate a report with the names of customers who spent the most money (top 3) so we can send them discount coupons, and also the
names of the most frugal customers (bottom 3) */
CREATE OR REPLACE PROCEDURE get_report_customers AS
-- Cursor to fetch the top 3 customers who have spent the most
CURSOR c1 IS
 SELECT c.customer_name, sum(o.amount_paid + o.tip) AS amount_spent
 FROM customer c, orders o WHERE c.customer_id = o.customer_id
 GROUP BY c.customer_name
 ORDER BY amount_spent DESC;
-- Cursor to fetch the bottom 3 customers who have spent the least
CURSOR c2 IS
 SELECT c.customer_name, sum(o.amount_paid + o.tip) AS amount_spent
 FROM customer c, orders o WHERE c.customer_id = o.customer_id
 GROUP BY c.customer_name
 ORDER BY amount_spent;
top_customer_name varchar(20);
top_amount_spent number;
bottom_customer_name varchar(20);
least_amount_spent number;
BEGIN
DBMS_OUTPUT.PUT_LINE('-------------------');
DBMS_OUTPUT.PUT_LINE('Top 3 Spenders:');
OPEN c1; -- open the cursor
LOOP -- start the loop
 FETCH c1 INTO top_customer_name, top_amount_spent;
 EXIT WHEN c1%ROWCOUNT>3 or c1%NOTFOUND;
 --exiting the loop after top 3 rows or no more rows
 DBMS_OUTPUT.PUT_LINE(top_customer_name || ' - $' || top_amount_spent);
END LOOP; -- end the loop
CLOSE c1; -- close the cursor
 DBMS_OUTPUT.PUT_LINE('-------------------');
 DBMS_OUTPUT.PUT_LINE('Bottom 3 Spenders:');
OPEN c2; -- open the cursor
LOOP -- start the loop
 FETCH c2 INTO bottom_customer_name, least_amount_spent;
 EXIT WHEN c2%ROWCOUNT>3 OR c2%NOTFOUND;
 --exiting the loop after top 3 rows or no more rows
 DBMS_OUTPUT.PUT_LINE(bottom_customer_name || ' - $' || least_amount_spent);
END LOOP; -- end the loop
CLOSE c2; -- close the cursor
EXCEPTION --adding exception to the procedure
 WHEN NO_DATA_FOUND THEN --no data found exception
 DBMS_OUTPUT.PUT_LINE('No Data Found');
 WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
END;
/
-- Anonymous PL/SQL program to call procedures for member 6
DECLARE
zip NUMBER;
BEGIN
zip := 21045;
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE (' ========== Below are Member 6 Operations ========');
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE ('List of customers who live in '|| zip ||' zip code');
get_CustomersByZip(zip); -- List all names of customers who live in 21045 zip code
DBMS_OUTPUT.PUT_LINE(' ');
DBMS_OUTPUT.PUT_LINE('For Each Cuisine Type the Most Popular Restaurant Based on Number of Orders Generated');
get_PopularRestaurant; -- Execute the procedure that corresponds to Operation 22 (most popular restaurant)
DBMS_OUTPUT.PUT_LINE(' ');
DBMS_OUTPUT.PUT_LINE ('For Each Cuisine Type the Most Profitable Restaurant Based on Number of Amounts Paid');
get_most_profitable_res;
DBMS_OUTPUT.PUT_LINE(' ');
DBMS_OUTPUT.PUT_LINE ('Report with the names of customers who spent the most money (top 3) and the most frugal customers (bottom 3)');
get_report_customers;
END;
/

-- Member 1 Reports
BEGIN
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE (' ========== Below is Member 1 Reports ===========');
DBMS_OUTPUT.PUT_LINE (' ===============================================');
REPORT_INCOME_BY_STATE;
END;
/

-- Member 2 Reports
BEGIN
DBMS_OUTPUT.PUT_LINE (' ===============================================');
DBMS_OUTPUT.PUT_LINE (' ========== Below are Member 2 Reports ===========');
DBMS_OUTPUT.PUT_LINE (' ===============================================');
Report_Tips;
DBMS_OUTPUT.PUT_LINE (' ===============================================');
Report_tips_by_state;
END;
/

