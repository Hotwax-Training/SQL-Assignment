1. New Customers Acquired in June 2023
Business Problem:
The marketing team ran a campaign in June 2023 and wants to see how many new customers signed up during that period.
Fields to Retrieve:
--PARTY_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE,ENTRY_DATE
-- Tables required: Party, Party_role, Person, PartyContactMech, Contact_mech, Telecom_number
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
    
2. List All Active Physical Products
Tables required: Product, Product_type
SELECT 
    product_id, 
    product_type_id, 
    internal_name 
FROM product p
JOIN product_type pt on p.product_id=pt.product_id
WHERE IS_PHYSICAL = 'Y';

Query Cost : 171000.33

-- 3. Products Missing NetSuite ID
-- Tables required: Product, Good_identification
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

-- 4. Product IDs Across Systems
-- Tables required: Good_identification
SELECT 
    product_id, 
    (CASE WHEN good_identification_type_id = 'SHOPIFY_PROD_ID' THEN ID_VALUE END) AS shopify_id,
    (CASE WHEN good_identification_type_id = 'HC_GOOD_ID_TYPE' THEN ID_VALUE END) AS hotwax_id,
    (CASE WHEN good_identification_type_id = 'ERP_ID' THEN ID_VALUE END) AS erp_id
FROM good_identification
GROUP BY product_id;

Query Cost : 252022.31

-- 5. Completed Orders in August 2023
-- Tables required: Product, Order_header, Order_item, Order_history, Facility

SELECT 
    p.PRODUCT_ID,
    p.PRODUCT_TYPE_ID,
    orh.PRODUCT_STORE_ID,
    p.INTERNAL_NAME,
    SUM(o.QUANTITY) AS TOTAL_QUANTITY,
    f.FACILITY_ID,
    f.EXTERNAL_ID,
    f.FACILITY_TYPE_ID,
    o.ORDER_ID,
    o.ORDER_ITEM_SEQ_ID,
    oh.ORDER_HISTORY_ID,
    oh.SHIP_GROUP_SEQ_ID
FROM product p 
LEFT JOIN facility f ON p.FACILITY_ID = f.FACILITY_ID
JOIN order_item o ON o.product_id = p.product_id
JOIN order_history oh ON oh.order_id = o.order_id
JOIN order_header orh ON orh.order_id = o.ORDER_ID
WHERE orh.STATUS_ID = 'ORDER_COMPLETED' AND
ORDER_DATE between '2023-08-01' AND '2023-08-31' group by order_id;

6. Newly Created Sales Orders and Payment Methods
--select * from order_header;
--select * from order_payment_preference;

SELECT 
      ORDER_ID,
      GRAND_TOTAL as TOTAL_AMOUNT,
      external_id as Shopify_Order_ID,
      payment_method_type_id as payment_method 
FROM order_header 
JOIN order_payment_preference using (order_id)
order by order_date desc;
Query Cost : 60516.37
    
7.Payment Captured but Not Shipped
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

8.Orders Completed Hour
select  hour(order_Date) AS order_hour,
    COUNT(order_Id) AS total_orders
FROM Order_Header
WHERE status_Id = 'ORDER_COMPLETED'
group by hour(order_Date)
order by hour(order_date);

Query Cost : 5644.01

9.BOPIS Orders Revenue (Last Year)
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
    
10. Canceled Orders (Last Month)
SELECT 
    COUNT(oh.order_id) AS total_orders,
    os.change_reason AS cancelation_reason
FROM Order_Header oh 
JOIN order_status os USING(order_id)
WHERE os.status_id = 'ORDER_CANCELLED'
AND oh.order_date BETWEEN '2024-12-01' AND '2024-12-31'
GROUP BY os.change_reason;
Query Cost : 28948.63
