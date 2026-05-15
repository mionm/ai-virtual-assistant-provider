DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgres_readonly') THEN
        CREATE USER postgres_readonly WITH PASSWORD 'readonly_password';
    ELSE
        ALTER USER postgres_readonly WITH PASSWORD 'readonly_password';
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS customer_data (
    customer_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_description VARCHAR NOT NULL,
    order_date DATE NOT NULL,
    quantity INTEGER NOT NULL,
    order_amount DECIMAL(10, 2) NOT NULL,
    order_status VARCHAR(50),
    return_status VARCHAR(50),
    return_start_date DATE,
    return_received_date DATE,
    return_completed_date DATE,
    return_reason VARCHAR(255),
    notes TEXT,
    PRIMARY KEY (customer_id, order_id)
);

COPY customer_data (
    customer_id,
    order_id,
    product_name,
    product_description,
    order_date,
    quantity,
    order_amount,
    order_status,
    return_status,
    return_start_date,
    return_received_date,
    return_completed_date,
    return_reason,
    notes
)
FROM '/docker-entrypoint-initdb.d/orders.csv'
WITH (FORMAT csv, HEADER true);

GRANT SELECT ON customer_data TO postgres_readonly;
