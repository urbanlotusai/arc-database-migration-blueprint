-- Sample schema proving the DMS migration pipeline end-to-end.
-- Apply to the SOURCE database before starting the replication task;
-- DMS full-load will recreate this schema (or migrate existing data) on the target.

CREATE TABLE IF NOT EXISTS customers (
    customer_id   SERIAL PRIMARY KEY,
    full_name     VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INTEGER NOT NULL REFERENCES customers(customer_id),
    amount        NUMERIC(10, 2) NOT NULL,
    status        VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Sample rows so the migration has something to move
INSERT INTO customers (full_name, email) VALUES
    ('Ada Lovelace', 'ada@example.com'),
    ('Grace Hopper', 'grace@example.com')
ON CONFLICT (email) DO NOTHING;

INSERT INTO orders (customer_id, amount, status) VALUES
    (1, 129.99, 'completed'),
    (2, 49.50, 'pending');
