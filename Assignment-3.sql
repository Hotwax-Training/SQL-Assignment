-- 1 Completed Sales Orders (Physical Items)
-- Business Problem:
-- Merchants need to track only physical items (requiring shipping and fulfillment) for logistics and shipping-cost analysis.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_ITEM_SEQ_ID
-- PRODUCT_ID
-- PRODUCT_TYPE_ID
-- SALES_CHANNEL_ENUM_ID
-- ORDER_DATE
-- ENTRY_DATE
-- STATUS_ID
-- STATUS_DATETIME
-- ORDER_TYPE_ID
-- PRODUCT_STORE_ID
	
select 
     oh.order_id,
     oi.ORDER_ITEM_SEQ_ID,
     p.PRODUCT_ID,
     p.PRODUCT_TYPE_ID,
     oh.SALES_CHANNEL_ENUM_ID,
     oh.ORDER_DATE,
     oh.ENTRY_DATE,
     oh.STATUS_ID,
     os.STATUS_DATETIME,
     oh.ORDER_TYPE_ID,
     oh.PRODUCT_STORE_ID
from order_header oh 
join order_item oi on oh.order_id=oi.ORDER_ID AND oh.order_type_id='SALES_ORDER' and oh.status_id = 'ORDER_COMPLETED'
join order_status os on os.ORDER_ID=oi.ORDER_ID AND oi.order_item_seq_id = os.order_Item_Seq_Id;
join product p on p.product_id=oi.product_id product p ON oi.product_id = p.product_id 
AND p.PRODUCT_TYPE_ID not in('DIGITAL_GOOD','DONATION','INSTALLATION_SERVICE','SERVICE');

Query cost : 131859.54

---------------------------------------------------------------------------------------------------------------------------------

-- 2 Completed Return Items
-- Business Problem:
-- Customer service and finance often need insights into returned items to manage refunds, replacements, and inventory restocking.

-- Fields to Retrieve:

-- RETURN_ID
-- ORDER_ID
-- PRODUCT_STORE_ID
-- STATUS_DATETIME
-- ORDER_NAME
-- FROM_PARTY_ID
-- RETURN_DATE
-- ENTRY_DATE
-- RETURN_CHANNEL_ENUM_ID
	
select * from return_item;
select * from return_header;
select 
      rh.return_id,
      oh.ORDER_ID,
      oh.PRODUCT_STORE_ID,
      oh.ORDER_NAME,
      rh.FROM_PARTY_ID,
      oh.ENTRY_DATE,
      rh.return_date,
      rh.RETURN_CHANNEL_ENUM_ID
from return_header rh
join return_item ri on rh.return_id=ri.return_id
join order_header oh on ri.ORDER_ID=oh.order_id
join order_status os on oh.order_id=os.order_id
where ri.status_id="RETURN_COMPLETED";

Query Cost : 7225.4
---------------------------------------------------------------------------------------------------------------------------------

-- 3 Single-Return Orders (Last Month)
-- Business Problem:
-- The mechandising team needs a list of orders that only have one return.

-- Fields to Retrieve:

-- PARTY_ID
-- FIRST_NAME

select 
	rh.from_party_id as party_id,
	per.first_name
from return_header rh 
join person per on rh.from_party_id=per.party_id
join return_item ri on ri.return_id=rh.return_id
where return_date between "2024-12-01" AND "2024-12-31"
GROUP BY ri.order_id,ri.RETURN_ID,rh.FROM_PARTY_ID
HAVING COUNT(rh.return_id) = 1;

Query Cost : 1380.18

--------------------------------------------------------------------------------------------------------------------------------------
    
-- 4 Returns and Appeasements
-- Business Problem:
-- The retailer needs the total amount of items, were returned as well as how many appeasements were issued.

-- Fields to Retrieve:

-- TOTAL RETURNS
-- RETURN $ TOTAL
-- TOTAL APPEASEMENTS
-- APPEASEMENTS $ TOTAL

select 
    count(ri.return_id) as total_returns,
	  SUM(ri.return_price) AS return_total,
    COUNT(ra.return_adjustment_id) AS total_appeasements,
	  SUM(ra.amount) AS appeasement_total
from return_item ri 
left join return_adjustment ra on ri.return_id=ra.return_id
where RETURN_ADJUSTMENT_TYPE_ID="APPEASEMENT" ;

Query Cost : 384.95
----------------------------------------------------------------------------------------------------------------------------------

-- 5 Detailed Return Information
-- Business Problem:
-- Certain teams need granular return data (reason, date, refund amount) for analyzing return rates, identifying recurring issues, or updating policies.

-- Fields to Retrieve:

-- RETURN_ID
-- ENTRY_DATE
-- RETURN_ADJUSTMENT_TYPE_ID (refund type, store credit, etc.)
-- AMOUNT
-- COMMENTS
-- ORDER_ID
-- ORDER_DATE
-- RETURN_DATE
-- PRODUCT_STORE_ID

select 
      ra.RETURN_ID,
      rh.ENTRY_DATE,
      ra.RETURN_ADJUSTMENT_TYPE_ID,
      ra.amount,
      ra.COMMENTS,
      oh.order_id,
      oh.order_date,
      rh.return_date,
      oh.PRODUCT_STORE_ID
from return_header rh 
left join return_adjustment ra on ra.RETURN_ID=rh.RETURN_ID
left join return_item ri on ra.ORDER_ID=ri.ORDER_ID 
join order_header oh on oh.ORDER_ID=ri.order_id;

Query Cost : 5861.09
--------------------------------------------------------------------------------------------------------------------------------

-- 6 Orders with Multiple Returns
-- Business Problem:
-- Analyzing orders with multiple returns can identify potential fraud, chronic issues with certain items, or inconsistent shipping processes.

-- Fields to Retrieve:

-- ORDER_ID
-- RETURN_ID
-- RETURN_DATE
-- RETURN_REASON
-- RETURN_QUANTITY

SELECT 
    ri.order_id,
    rh.return_id,
    rh.return_date,
    ri.reason AS return_reason,
    ri.return_quantity
FROM return_header rh
JOIN return_item ri ON ri.return_id = rh.return_id
WHERE ri.order_id IN (
    SELECT order_id
    FROM return_item
    GROUP BY order_id
    HAVING COUNT(DISTINCT return_id) > 1
);

Query Cost : 1925.50
--------------------------------------------------------------------------------------------------------------------------------------

-- 7 Store with Most One-Day Shipped Orders (Last Month)
-- Business Problem:
-- Identify which facility (store) handled the highest volume of “one-day shipping” orders in the previous month, useful for operational benchmarking.

-- Fields to Retrieve:

-- FACILITY_ID
-- FACILITY_NAME
-- TOTAL_ONE_DAY_SHIP_ORDERS
-- REPORTING_PERIOD

SELECT
    F.FACILITY_ID,
    F.FACILITY_NAME,
    COUNT(OH.order_id) AS TOTAL_ONE_DAY_SHIP_ORDERS,
    DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m') AS REPORTING_PERIOD
FROM Order_Header OH
JOIN Order_Item OI ON OI.ORDER_ID = OH.ORDER_ID
JOIN Facility F ON OH.origin_Facility_Id = F.FACILITY_ID
JOIN Shipment S ON OH.ORDER_ID = S.primary_Order_Id
WHERE OH.order_date >= DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01') 
AND OH.order_date < DATE_FORMAT(NOW(), '%Y-%m-01') AND S.shipment_Method_Type_Id = 'NEXT_DAY'  
GROUP BY F.FACILITY_ID,F.FACILITY_NAME
ORDER BY TOTAL_ONE_DAY_SHIP_ORDERS DESC LIMIT 1;

Query Cost :6737.04
---------------------------------------------------------------------------------------------------------------------------------

-- 8 List of Warehouse Pickers
-- Business Problem:
-- Warehouse managers need a list of employees responsible for picking and packing orders to manage shifts, productivity, and training needs.

-- Fields to Retrieve:

-- PARTY_ID (or Employee ID)
-- NAME (First/Last)
-- ROLE_TYPE_ID (e.g., “WAREHOUSE_PICKER”)
-- FACILITY_ID (assigned warehouse)
-- STATUS (active or inactive employee)
	
SELECT 
    p.party_id AS employee_id,
    CONCAT(per.first_name, ' ', per.last_name) AS name,
    pr.role_type_id,
    p.STATUS_ID,
    f.FACILITY_ID
FROM party p
JOIN party_role pr ON p.party_id = pr.party_id
JOIN person per on per.party_id=p.party_id
JOIN facility f on f.OWNER_PARTY_ID=p.PARTY_ID
WHERE pr.role_type_id = 'WAREHOUSE_PICKER' AND f.facility_type_id="WAREHOUSE";

Query Cost : 51.43

--------------------------------------------------------------------------------------------------------------------------------

-- 9 Total Facilities That Sell the Product
-- Business Problem:
-- Retailers want to see how many (and which) facilities (stores, warehouses, virtual sites) currently offer a product for sale.

-- Fields to Retrieve:

-- PRODUCT_ID
-- PRODUCT_NAME (or INTERNAL_NAME)
-- FACILITY_COUNT (number of facilities selling the product)
-- (Optionally) a list of FACILITY_IDs if more detail is needed

SELECT 
    p.product_id,
    p.product_name, 
    COUNT(DISTINCT i.facility_id) AS facility_count
FROM product p
JOIN inventory_item i ON p.product_id = i.product_id
GROUP BY p.product_id;

-----------------------------------------------------------------------------------------------------------------------------------

-- 10 Total Items in Various Virtual Facilities
-- Business Problem:
-- Retailers need to study the relation of inventory levels of products to the type of facility it's stored at. Retrieve all inventory levels for products at locations and include the facility type Id. Do not retrieve facilities that are of type Virtual.

-- Fields to Retrieve:

-- PRODUCT_ID
-- FACILITY_ID
-- FACILITY_TYPE_ID
-- QOH (Quantity on Hand)
-- ATP (Available to Promise)
	
select
      pf.product_id,
      f.facility_id,
      f.facility_type_id,
      i.quantity_on_hand_total as QOH,
      i.available_to_promise_total as ATP
from product_facility pf
join facility f on f.FACILITY_ID=pf.FACILITY_ID
join inventory_item i on i.product_id=pf.product_id
WHERE f.facility_type_id = 'VIRTUAL_FACILITY';

Query Cost : 250798

------------------------------------------------------------------------------------------------------------------------------------
-- 12 Orders Without Picklist
-- Business Problem:
-- A picklist is necessary for warehouse staff to gather items. Orders missing a picklist might be delayed and need attention.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_DATE
-- ORDER_STATUS
-- FACILITY_ID
-- DURATION (How long has the order been assigned at the facility)

SELECT 
    oh.order_id AS ORDER_ID,
    oh.order_date AS ORDER_DATE,
    oh.status_id AS ORDER_STATUS,
    oh.origin_facility_id AS FACILITY_ID,
    DATEDIFF(CURRENT_DATE, oh.order_date) AS DURATION
FROM Order_Header oh
LEFT JOIN PickList_Item pi ON oh.order_id = pi.order_id
WHERE pi.order_id IS NULL;

Query Cost : 45622.3
