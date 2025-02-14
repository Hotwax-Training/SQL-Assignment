5.1 Shipping Addresses for October 2023 Orders
SELECT 
    oh.order_id,
    pcm.party_id AS customer_id,
    CONCAT(per.first_name, ' ', per.last_name) AS customer_name,
    pa.address1 AS street_address,
    pa.city,
    pa.state_province_geo_id AS state_province,
    pa.postal_code,
    pa.country_geo_id AS country_code,
    oh.status_id,
    oh.order_date
FROM order_header oh 
JOIN order_contact_mech ocm ON ocm.order_id = oh.order_id
JOIN postal_address pa ON pa.contact_mech_id = ocm.contact_mech_id
JOIN party_contact_mech pcm ON pcm.contact_mech_id = pa.contact_mech_id
JOIN person per ON per.party_id = pcm.party_id
WHERE oh.order_date BETWEEN '2023-10-01' AND '2023-10-31' 
AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
AND oh.status_id = 'ORDER_COMPLETED';

5.2 :Orders from New York
SELECT 
    oh.order_id,
    CONCAT(per.first_name, ' ', per.last_name) AS customer_name,
    pa.address1 AS street_address,
    pa.city,
    pa.state_province_geo_id AS state_province,
    pa.postal_code,
    oh.grand_total AS total_amount,
    oh.order_date,
    oh.status_id AS order_status
FROM order_header oh
JOIN order_contact_mech ocm ON oh.order_id = ocm.order_id
JOIN postal_address pa ON pa.contact_mech_id = ocm.contact_mech_id
JOIN party_contact_mech pcm ON pcm.contact_mech_id = pa.contact_mech_id
JOIN person per ON per.party_id = pcm.party_id
WHERE ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
AND pa.state_province_geo_id = 'NY' 
AND pa.city = 'New York'
AND oh.status_id = 'ORDER_COMPLETED';

5.3 Top-Selling Product in New York
SELECT
    p.product_id,
    p.internal_name,
    pa.state_province_geo_id AS state_province,
    COUNT(oi.quantity) AS total_quantity_sold,
    SUM(oh.grand_total) AS revenue
FROM product p 
JOIN order_item oi ON p.product_id = oi.product_id
JOIN order_header oh ON oh.order_id = oi.order_id
JOIN order_contact_mech ocm ON ocm.order_id = oh.order_id
JOIN postal_address pa ON pa.contact_mech_id = ocm.contact_mech_id
WHERE pa.state_province_geo_id = 'NY' 
AND pa.city = 'New York' 
AND oh.status_id = 'ORDER_COMPLETED' 
GROUP BY p.product_id;

7.3 Store-Specific (Facility-Wise) Revenue
SELECT 
    fac.facility_id,
    fac.facility_name,
    COUNT(oi.quantity) AS total_quantity_sold,
    SUM(oh.grand_total) AS revenue,
    MIN(oh.order_date) AS start_date,
    MAX(oh.order_date) AS end_date
FROM facility fac 
JOIN order_item_ship_group oisg ON fac.facility_id = oisg.facility_id 
JOIN order_header oh ON oh.order_id = oisg.order_id
JOIN order_item oi ON oi.order_id = oisg.order_id 
GROUP BY fac.facility_id;

8.1 Inventory Management & Transfers
SELECT 
    inv.inventory_item_id,
    inv.product_id,
    inv.facility_id,
    invd.reason_enum_id AS reason_code,
    invd.quantity_on_hand_diff AS quantity_lost_or_damaged,
    invd.effective_date AS transaction_date
FROM inventory_item inv 
JOIN inventory_item_detail invd 
    ON inv.inventory_item_id = invd.inventory_item_id
WHERE invd.reason_enum_id IN ('VAR_LOST', 'VAR_DAMAGED');
    
8.2 Low Stock or Out of Stock Items Report
SELECT 
    p.product_id,
    p.product_name,
    inv.facility_id,
    inv.quantity_on_hand_total AS QOH,
    inv.available_to_promise_total AS ATP
FROM product p 
JOIN inventory_item inv
    ON p.product_id = inv.product_id;

8.3 Retrieve the Current Facility (Physical or Virtual) of Open Orders
SELECT
    oh.order_id,
    oh.status_id AS order_status,
    f.facility_id,
    f.facility_name,
    f.facility_type_id
FROM facility f
JOIN order_header oh ON f.facility_id = oh.origin_facility_id
WHERE oh.status_id IN ('ORDER_APPROVED', 'ORDER_CREATED', 'ORDER_HOLD');

8.4 Items Where QOH and ATP Differ
SELECT 
    inv.product_id,
    inv.facility_id,
    inv.quantity_on_hand_total AS QOH,
    inv.available_to_promise_total AS ATP,
    (inv.quantity_on_hand_total - inv.available_to_promise_total) AS difference
FROM inventory_item inv
WHERE inv.quantity_on_hand_total <> inv.available_to_promise_total;

8.5 Order Item Current Status Changed Date-Time
SELECT 
    oi.order_id,
    oi.order_item_seq_id,
    oi.status_id AS current_status_id,
    os.status_datetime AS status_change_datetime,
    os.status_user_login AS changed_by
FROM order_item oi 
JOIN order_status os ON oi.order_id = os.order_id;

8.6 Total Orders by Sales Channel
SELECT 
    oh.sales_channel_enum_id AS sales_channel,
    COUNT(DISTINCT oh.order_id) AS total_orders, 
    SUM(oh.grand_total) AS total_revenue,
    DATE_FORMAT(oh.order_date, '%Y-%m') AS reporting_period -- Grouping by month
FROM order_header oh
JOIN order_item oi 
    ON oi.order_id = oh.order_id
GROUP BY oh.sales_channel_enum_id, reporting_period
ORDER BY reporting_period DESC, total_orders DESC;
