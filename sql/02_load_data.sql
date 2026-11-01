-- 02_load_data.sql : load CSVs from D:\olist-project\data\raw

COPY customers FROM 'D:/olist-project/data/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY geolocation FROM 'D:/olist-project/data/raw/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY sellers FROM 'D:/olist-project/data/raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY products FROM 'D:/olist-project/data/raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY category_translation FROM 'D:/olist-project/data/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY orders FROM 'D:/olist-project/data/raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY order_items FROM 'D:/olist-project/data/raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY order_payments FROM 'D:/olist-project/data/raw/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY order_reviews FROM 'D:/olist-project/data/raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
