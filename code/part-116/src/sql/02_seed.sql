-- Deterministic sample data
INSERT INTO customers VALUES
(1, 'Aarav Stores', 'Delhi', '2026-08-01 09:00:00+00'),
(2, 'Blue Kite', 'Mumbai', '2026-08-02 09:00:00+00'),
(3, 'Cedar Labs', NULL, '2026-08-03 09:00:00+00'),
(4, 'Delta Books', 'Delhi', '2026-08-04 09:00:00+00');

INSERT INTO products VALUES
(101, 'SQL-BOOK', 'SQL Practice Book', 49900),
(102, 'DB-WORK', 'Database Design Workbook', 69900),
(103, 'USB-HUB', 'USB-C Hub', 179900);

INSERT INTO orders VALUES
(1001, 1, '2026-08-02', 'paid', 99800),
(1002, 1, '2026-08-05', 'pending', 179900),
(1003, 2, '2026-08-03', 'paid', 69900),
(1004, 2, '2026-08-05', 'cancelled', 49900);

INSERT INTO order_items VALUES
(1001, 1, 101, 2, 49900),
(1002, 1, 103, 1, 179900),
(1003, 1, 102, 1, 69900),
(1004, 1, 101, 1, 49900);
