-- 1 Completed Sales Orders (Physical Items)
select * from order_header;
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
join order_item oi on oh.order_id=oi.ORDER_ID
join order_status os on os.ORDER_ID=oi.ORDER_ID
join product p on p.product_id=oi.product_id
where oh.order_type_id="SALES_ORDER" AND os.status_id="ORDER_COMPLETED";

-- 2 Completed Return Item
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
where ri.status_id="RETURN_COMPLETED" AND rh.status_id="RETURN_COMPLETED";

-- 3 Single-Return Orders (Last Month)
select 
	rh.from_party_id as party_id,
	per.first_name
from return_header rh 
join person per on rh.from_party_id=per.party_id
join return_item ri on ri.return_id=rh.return_id
where return_date between "2024-12-01" AND "2024-12-31"
GROUP BY ri.order_id,ri.RETURN_ID,rh.FROM_PARTY_ID
HAVING COUNT(rh.return_id) = 1;
    
    
-- 4 Returns and Appeasements
select * from return_item;
select * from appeasement;
select * from return_status;
select * from return_item;
select * from appeasements;

select 
    count(ri.return_id) as total_returns,
	  SUM(ri.return_price) AS return_total,
    COUNT(ra.return_adjustment_id) AS total_appeasements,
	  SUM(ra.amount) AS appeasement_total
from return_item ri 
left join return_adjustment ra on ri.return_id=ra.return_id
where RETURN_ADJUSTMENT_TYPE_ID="APPEASEMENT" ;

 -- 5 Detailed Return Information
select * from order_header;
select * from return_adjustment;
select * from return_item;
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

-- 6 Orders with Multiple Return 
select * from return_header;
select * from return_item;
select * from return_reason;
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
-- 7.Store with Most One-Day Shipped Orders (Last Month)

-- 8 List of Warehouse Pickers
select * from facility;
select distinct STATUS_ID from party;
select * from party_role;

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

-- 9 Total Facilities That Sell the Product
select * from facility;
select * from inventory_item;
select * from product_facility;
SELECT 
    p.product_id,
    p.product_name, 
    COUNT(DISTINCT i.facility_id) AS facility_count
FROM product p
JOIN inventory_item i ON p.product_id = i.product_id
GROUP BY p.product_id;
     
-- 10 Total Items in Various Virtual Facilities
select * from facility;
select * from product;
select * from order_header;
select * from inventory_item;
select * from product_facility;

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

-- 11 Transfer Orders Without Inventory Reservation

-- 12 Orders Without Picklist
select * from order_header;
select * from picklist_bin;
SELECT 
    o.order_id,
    pb.primary_order_id,
    o.order_date,
    o.status_id AS order_status
FROM order_header o
JOIN picklist_bin pb ON o.order_id = pb.primary_order_id;
