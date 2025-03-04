-- 1 New Customers Acquired in June 2023
-- Business Problem:
-- The marketing team ran a campaign in June 2023 and wants to see how many new customers signed up during that period.

-- Fields to Retrieve:

-- PARTY_ID
-- FIRST_NAME
-- LAST_NAME
-- EMAIL
-- PHONE
-- ENTRY_DATE 

SELECT 
    p.PARTY_ID,
    per.FIRST_NAME, 
    per.LAST_NAME, 
    cm.INFO_STRING, 
    tn.CONTACT_NUMBER, 
    p.CREATED_DATE 
FROM party p 
JOIN party_role pr ON p.party_id = pr.party_id
JOIN person per ON per.party_id = p.party_id 
JOIN party_contact_mech pcm ON pcm.party_id = p.party_id
JOIN contact_mech cm ON cm.CONTACT_MECH_ID = pcm.CONTACT_MECH_ID
JOIN telecom_number tn ON tn.CONTACT_MECH_ID = cm.CONTACT_MECH_ID
WHERE pr.ROLE_TYPE_ID = 'CUSTOMER' AND  p.CREATED_DATE >= '2023-06-01' AND  p.CREATED_DATE <'2023-07-01';

Query Cost : 17325.44
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2 List All Active Physical Products
-- Business Problem:
-- Merchandising teams often need a list of all physical products to manage logistics, warehousing, and shipping.

-- Fields to Retrieve:

-- PRODUCT_ID
-- PRODUCT_TYPE_ID
-- INTERNAL_NAME
    
SELECT 
    product_id, 
    product_type_id, 
    internal_name 
FROM product p
JOIN product_type pt on p.product_id=pt.product_id
WHERE IS_PHYSICAL = 'Y';

Query Cost : 171000.33
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
-- 3 Products Missing NetSuite ID
-- Business Problem:
-- A product cannot sync to NetSuite unless it has a valid NetSuite ID. The OMS needs a list of all products that still need to be created or updated in NetSuite.

-- Fields to Retrieve:

-- PRODUCT_ID
-- INTERNAL_NAME
-- PRODUCT_TYPE_ID
-- NETSUITE_ID (or similar field indicating the NetSuite ID; may be NULL or empty if missing)
    
SELECT 
    product_id, 
    internal_name, 
    product_type_id, 
    good_identification_type_id  
FROM product 
JOIN good_identification USING (product_id) 
WHERE GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID' 
AND ID_VALUE IS NULL;

Query Cost : 2.19
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    

-- 4 Product IDs Across Systems
-- Business Problem:
-- To sync an order or product across multiple systems (e.g., Shopify, HotWax, ERP/NetSuite), the OMS needs to know each system’s unique identifier for that product. This query retrieves the Shopify ID, HotWax ID, and ERP ID (NetSuite ID) for all products.
                                                             
-- Fields to Retrieve:

-- PRODUCT_ID
-- SHOPIFY_ID  
-- HOTWAX_ID      
-- ERP_ID or NETSUITE_ID (depending on naming)
SELECT 
    product_id, 
    (CASE WHEN good_identification_type_id = 'SHOPIFY_PROD_ID' THEN ID_VALUE END) AS shopify_id,
    (CASE WHEN good_identification_type_id = 'HC_GOOD_ID_TYPE' THEN ID_VALUE END) AS hotwax_id,
    (CASE WHEN good_identification_type_id = 'ERP_ID' THEN ID_VALUE END) AS erp_id
FROM good_identification
GROUP BY product_id;

Query Cost : 252022.31
-------------------------------------------------------------------------------------------------------------------------------------
    
-- 7 Newly Created Sales Orders and Payment Methods
-- Business Problem:
-- Finance teams need to see new orders and their payment methods for reconciliation and fraud checks.

-- Fields to Retrieve:

-- ORDER_ID
-- TOTAL_AMOUNT
-- PAYMENT_METHOD
-- Shopify Order ID (if applicable) //External_id
SELECT 
      ORDER_ID,
      GRAND_TOTAL as TOTAL_AMOUNT,
      external_id as Shopify_Order_ID,
      payment_method_type_id as payment_method 
FROM order_header 
JOIN order_payment_preference using (order_id)
order by order_date desc;

Query Cost : 60516.37
----------------------------------------------------------------------------------------------------------------------------------
    
-- 8 Payment Captured but Not Shipped
-- Business Problem:
-- Finance teams want to ensure revenue is recognized properly. If payment is captured but no shipment has occurred, it warrants further review.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_STATUS
-- PAYMENT_STATUS
-- SHIPMENT_STATUS
Select 
      oh.order_id,
      oh.status_id as order_status ,
      opp.STATUS_ID as payment_status,
      s.status_id as shipment_status
from order_header oh 
join order_payment_preference opp on oh.order_id=opp.order_id 
join order_shipment os on os.ORDER_ID=oh.ORDER_ID
join shipment s on s.SHIPMENT_ID=os.SHIPMENT_ID 
where s.status_id is null;

Query Cost : 3.58
---------------------------------------------------------------------------------------------------------------------------------

-- 9 Orders Completed Hourly
-- Business Problem:
-- Operations teams may want to see how orders complete across the day to schedule staffing.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- HOUR

select 
    COUNT(order_Id) AS total_orders
    hour(order_Date) AS order_hour,
FROM Order_Header
WHERE status_Id = 'ORDER_COMPLETED'
group by hour(order_Date)
order by hour(order_date);

Query Cost : 5344.01
-------------------------------------------------------------------------------------------------------------------------------

-- 10 BOPIS Orders Revenue (Last Year)
-- Business Problem:
-- BOPIS (Buy Online, Pickup In Store) is a key retail strategy. Finance wants to know the revenue from BOPIS orders for the previous year.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- TOTAL REVENUE
    
SELECT 
    COUNT(oh.order_id) AS total_orders, 
    SUM(oh.grand_total) AS total_revenue
FROM order_header oh
JOIN shipment s ON oh.order_id = s.primary_order_id
WHERE oh.sales_channel_enum_id = 'WEB_SALES_CHANNEL'
AND s.shipment_method_type_id = 'STOREPICKUP'
AND oh.status_id = 'ORDER_COMPLETED' 
AND OH.ORDER_DATE BETWEEN "2024-01-01" AND "2024-12-31";

Query Cost : 6500.76
---------------------------------------------------------------------------------------------------------------------------------
    
-- 11 Canceled Orders (Last Month)
-- Business Problem:
-- The merchandising team needs to know how many orders were canceled in the previous month and their reasons.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- CANCELATION REASON  
    
SELECT 
    COUNT(oh.order_id) AS total_orders,
    os.change_reason AS cancelation_reason
FROM Order_Header oh 
JOIN order_status os USING(order_id)
WHERE os.status_id = 'ORDER_CANCELLED'
AND	oh.order_date >'2024-12-01' AND	oh.order_date <'2024-12-31' 
GROUP BY os.change_reason;
Query Cost : 22948.63
