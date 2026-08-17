SET search_path = iq117, public;
INSERT INTO departments VALUES (1,'Sales'),(2,'Support'),(3,'Operations');
INSERT INTO employees(employee_id,employee_name,department_id,manager_id,salary_paise,active) VALUES
(1,'Asha',1,NULL,9000000,true),(2,'Kabir',1,1,6500000,true),(3,'Meera',2,NULL,7200000,true),
(4,'Rohan',3,NULL,8000000,true),(5,'Nina',1,1,6500000,false);
INSERT INTO customers VALUES
(1,'Aarav Stores',' aarav@example.com ','North','2026-06-01 09:00+00'),
(2,'Blue Kite','BLUE@example.com','West','2026-06-10 09:00+00'),
(3,'Cedar Labs','blue@example.com','West','2026-07-01 09:00+00'),
(4,'Delta Books',NULL,'South','2026-07-20 09:00+00'),
(5,'Evergreen Co','evergreen@example.com','East','2026-08-01 09:00+00');
INSERT INTO products VALUES
(101,'BK-SQL','SQL Guide','Books',49900,22000),(102,'BK-DESIGN','Database Design','Books',79900,36000),
(103,'AC-KB','Keyboard','Accessories',149900,90000),(104,'AC-MOUSE','Mouse','Accessories',89900,48000),
(105,'SV-AUDIT','Data Audit','Services',399900,120000),(106,'SV-REVIEW','Query Review','Services',249900,80000);
INSERT INTO orders VALUES
(1001,1,1,2,'2026-07-03 10:00+00','completed',149800,0),
(1002,2,1,2,'2026-07-18 10:00+00','completed',149900,0),
(1003,3,2,3,'2026-08-02 10:00+00','completed',399900,50000),
(1004,4,2,2,'2026-08-02 10:00+00','completed',239800,0),
(1005,5,3,4,'2026-08-05 10:00+00','pending',89900,0),
(1006,7,1,2,'2026-08-08 10:00+00','refunded',49900,49900),
(1007,8,2,2,'2026-08-10 10:00+00','completed',79900,0),
(1008,10,2,1,'2026-08-12 10:00+00','completed',249900,0);
INSERT INTO order_items VALUES
(1,1,101,2,49900),(2,1,103,1,149900),(3,1,105,1,399900),(4,1,101,1,49900),(4,2,102,1,79900),(4,3,104,1,89900),
(5,1,104,1,89900),(6,1,101,1,49900),(7,1,102,1,79900),(8,1,106,1,249900);
INSERT INTO payments VALUES
(1,1,100000,'captured','2026-07-03 10:05+00'),(2,1,49800,'captured','2026-07-03 10:06+00'),
(3,2,149900,'captured','2026-07-18 10:05+00'),(4,3,399900,'captured','2026-08-02 10:05+00'),
(5,4,239800,'captured','2026-08-02 10:05+00'),(6,6,49900,'refunded','2026-08-09 10:05+00');
INSERT INTO required_products VALUES (101),(102);
INSERT INTO bundle_products VALUES ('STARTER',101),('STARTER',102);
INSERT INTO staging_orders VALUES (1,1,'SRC-1'),(2,999,'SRC-2'),(3,NULL,'SRC-3');
INSERT INTO login_events VALUES
(1,'2026-08-01 08:00+00'),(1,'2026-08-02 08:00+00'),(1,'2026-08-03 08:00+00'),(1,'2026-08-05 08:00+00'),
(2,'2026-08-01 08:00+00'),(2,'2026-08-03 08:00+00');
INSERT INTO subscriptions VALUES
(1,1,'PRO','2026-01-01','2026-03-31','cancelled'),(2,1,'PRO','2026-04-01','2026-06-30','cancelled'),
(3,1,'PRO','2026-06-25',NULL,'active'),(4,2,'BASIC','2026-02-01',NULL,'active');
INSERT INTO stock_movements VALUES
(1,101,'MAIN','2026-08-01 09:00+00',10),(2,101,'MAIN','2026-08-02 09:00+00',-4),
(3,101,'MAIN','2026-08-03 09:00+00',-7),(4,101,'MAIN','2026-08-04 09:00+00',5);
