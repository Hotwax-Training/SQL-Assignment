-- 5.1 Shipping Addresses for October 2023 Orders
-- Business Problem:
-- Customer Service might need to verify addresses for orders placed or completed in October 2023. This helps ensure shipments are delivered correctly and prevents address-related issues.

-- Fields to Retrieve:

-- ORDER_ID
-- PARTY_ID (Customer ID)
-- CUSTOMER_NAME (or FIRST_NAME / LAST_NAME)
-- STREET_ADDRESS
-- CITY
-- STATE_PROVINCE
-- POSTAL_CODE
-- COUNTRY_CODE
-- ORDER_STATUS
-- ORDER_DATE

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
WHERE oh.ORDER_DATE>='2023-10-01' AND oh.ORDER_DATE<'2024-01-01';
AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
AND oh.status_id = 'ORDER_COMPLETED';

Query Cost : 24785.35 
---------------------------------------------------------------------------------------------------------------------------------
    
  -- 5.2 Orders from New York
-- Business Problem:
-- Companies often want region-specific analysis to plan local marketing, staffing, or promotions in certain areas—here, specifically, New York.

-- Fields to Retrieve:

-- ORDER_ID
-- CUSTOMER_NAME
-- STREET_ADDRESS (or shipping address detail)
-- CITY
-- STATE_PROVINCE
-- POSTAL_CODE
-- TOTAL_AMOUNT
-- ORDER_DATE
-- ORDER_STATUS
    
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

Query Cost : 8055.33
--------------------------------------------------------------------------------------------------------------------------------
    
-- 5.3 Top-Selling Product in New York
-- Business Problem:
-- Merchandising teams need to identify the best-selling product(s) in a specific region (New York) for targeted restocking or promotions.

-- Fields to Retrieve:

-- PRODUCT_ID
-- INTERNAL_NAME
-- TOTAL_QUANTITY_SOLD
-- CITY / STATE (within New York region)
-- REVENUE (optionally, total sales amount)
    
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

Query Cost : 14627.56
--------------------------------------------------------------------------------------------------------------------------------
 
 -- 7.3 Store-Specific (Facility-Wise) Revenue
-- Business Problem:
-- Different physical or online stores (facilities) may have varying levels of performance. The business wants to compare revenue across facilities for sales planning and budgeting.

-- Fields to Retrieve:

-- FACILITY_ID
-- FACILITY_NAME
-- TOTAL_ORDERS
-- TOTAL_REVENUE
-- DATE_RANGE
    
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

Query Cost : 392256.64
-------------------------------------------------------------------------------------------------------------------------------------    

-- 8.1 Lost and Damaged Inventory
-- Business Problem:
-- Warehouse managers need to track “shrinkage” such as lost or damaged inventory to reconcile physical vs. system counts.

-- Fields to Retrieve:

-- INVENTORY_ITEM_ID
-- PRODUCT_ID
-- FACILITY_ID
-- QUANTITY_LOST_OR_DAMAGED
-- REASON_CODE (Lost, Damaged, Expired, etc.)
-- TRANSACTION_DATE
    
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

Query Cost :
---------------------------------------------------------------------------------------------------------------------------------
    
-- 8.3 Retrieve the Current Facility (Physical or Virtual) of Open Orders
-- Business Problem:
-- The business wants to know where open orders are currently assigned, whether in a physical store or a virtual facility (e.g., a distribution center or online fulfillment location).

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_STATUS
-- FACILITY_ID
-- FACILITY_NAME
-- FACILITY_TYPE_ID 
    
SELECT
    oh.order_id,
    oh.status_id AS order_status,
    f.facility_id,
    f.facility_name,
    f.facility_type_id
FROM facility f
JOIN order_header oh ON f.facility_id = oh.origin_facility_id
WHERE oh.status_id IN ('ORDER_APPROVED', 'ORDER_CREATED', 'ORDER_HOLD');
-----------------------------------------------------------------------------------------------------------------------------------

-- 8.4 Items Where QOH and ATP Differ
-- Business Problem:
-- Sometimes the Quantity on Hand (QOH) doesn’t match the Available to Promise (ATP) due to pending orders, reservations, or data discrepancies. This needs review for accurate fulfillment planning.

-- Fields to Retrieve:

-- PRODUCT_ID
-- FACILITY_ID
-- QOH (Quantity on Hand)
-- ATP (Available to Promise)
-- DIFFERENCE (QOH - ATP)

SELECT 
    inv.product_id,
    inv.facility_id,
    inv.quantity_on_hand_total AS QOH,
    inv.available_to_promise_total AS ATP,
    (inv.quantity_on_hand_total - inv.available_to_promise_total) AS difference
FROM inventory_item inv
WHERE inv.quantity_on_hand_total <> inv.available_to_promise_total;
-----------------------------------------------------------------------------------------------------------------------------------

-- 8.5 Order Item Current Status Changed Date-Time
-- Business Problem:
-- Operations teams need to audit when an order item’s status (e.g., from “Pending” to “Shipped”) was last changed, for shipment tracking or dispute resolution.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_ITEM_SEQ_ID
-- CURRENT_STATUS_ID
-- STATUS_CHANGE_DATETIME
-- CHANGED_BY
    
SELECT 
    oi.order_id,
    oi.order_item_seq_id,
    oi.status_id AS current_status_id,
    os.status_datetime AS status_change_datetime,
    os.status_user_login AS changed_by
FROM order_item oi 
JOIN order_status os ON oi.order_id = os.order_id;
------------------------------------------------------------------------------------------------------------------------------------

-- 8.6 Total Orders by Sales Channel
-- Business Problem:
-- Marketing and sales teams want to see how many orders come from each channel (e.g., web, mobile app, in-store POS, marketplace) to allocate resources effectively.

-- Fields to Retrieve:

-- SALES_CHANNEL
-- TOTAL_ORDERS
-- TOTAL_REVENUE
-- REPORTING_PERIOD

SELECT 
    oh.sales_channel_enum_id AS sales_channel,
    COUNT(DISTINCT oh.order_id) AS total_orders, 
    SUM(oh.grand_total) AS total_revenue,
    DATE_FORMAT(oh.order_date, '%Y-%m') AS reporting_period -- Grouping by month
FROM order_header oh
GROUP BY oh.sales_channel_enum_id, reporting_period
ORDER BY reporting_period DESC, total_orders DESC;
