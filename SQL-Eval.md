# 1 Products Missing NetSuite ID

## Business Problem
A product cannot sync to NetSuite unless it has a valid **NetSuite ID**. The **Order Management System (OMS)** needs a list of all products that still need to be created or updated in NetSuite.

## Fields to Retrieve
The query retrieves the following details for products that **do not have a NetSuite ID**:

- `PRODUCT_ID`
- `INTERNAL_NAME`
- `PRODUCT_TYPE_ID`
- `NETSUITE_ID` (or a similar field indicating the NetSuite ID, which may be `NULL` or empty if missing)

##  SQL Query

```sql
SELECT
    product_id,
    internal_name,
    product_type_id,
    good_identification_type_id  
FROM product
JOIN good_identification USING (product_id)
WHERE GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID'
AND ID_VALUE IS NULL OR ID_VALUE = '';
```

## Explanation
This query identifies products **missing a NetSuite ID** by:

1️ **Joining `product` and `good_identification`**  
   - The `good_identification` table stores external identifiers like ERP IDs (NetSuite), SKUs, and UPCs.
   - Using `USING (product_id)`, we ensure we only fetch products with external ID entries.

2️ **Filtering by `GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID'`**  
   - Setting `GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID'` ensures we only check NetSuite-related IDs.

3️ **Checking `ID_VALUE IS NULL OR ID_VALUE = ''`**  
   - Filters products that do not have a NetSuite ID assigned yet.

##  Query Cost
- **Estimated Query Cost:** `2.19`

# 2 Newly Created Sales Orders and Payment Methods

##  Business Problem

The **finance team** needs to monitor newly created **sales orders** and their corresponding **payment methods** for **reconciliation and fraud detection**.  
This query retrieves **new orders** along with their **payment method details**.

## Fields to Retrieve

- **`ORDER_ID`** – Unique order identifier.
- **`TOTAL_AMOUNT`** – The total order value (Grand Total).
- **`PAYMENT_METHOD`** – The payment method used for the order.
- **`SHOPIFY_ORDER_ID`** – External order ID from Shopify (if applicable).

##  SQL Query with Explanation

```sql
SELECT 
      oh.ORDER_ID,
      oh.GRAND_TOTAL AS TOTAL_AMOUNT,
      oh.external_id AS Shopify_Order_ID,
      opp.payment_method_type_id AS PAYMENT_METHOD 
FROM order_header oh
JOIN order_payment_preference opp USING (order_id)
ORDER BY oh.order_date DESC;
```

## Explanation:
1️ **Retrieve New Orders**:
   - Selecting orders from the `order_header` table.
   - Fetching the `ORDER_ID`, `GRAND_TOTAL`, and `external_id`.

2️ **Join with Payment Preferences**:
   - `JOIN order_payment_preference USING (order_id)` ensures we get the payment method used for each order.

3️ **Sorting by Latest Orders**:
   - `ORDER BY oh.order_date DESC` ensures the most recent orders appear first.

 ## Query Cost: 
 - **Estimated Query Cost:** 55,516.37  

#  3 Orders from New York

##  Business Problem

Companies often require **region-specific analysis** to optimize **local marketing, staffing, or promotions**. This query retrieves **orders completed in New York**, allowing for better **business planning**.

## Fields to Retrieve

- **`ORDER_ID`** – Unique identifier for each order.
- **`CUSTOMER_NAME`** – Full name of the customer (first & last name).
- **`STREET_ADDRESS`** – Shipping address details.
- **`CITY`** – City of the shipping address.
- **`STATE_PROVINCE`** – State or province code (e.g., `NY` for New York).
- **`POSTAL_CODE`** – ZIP code for geographic tracking.
- **`TOTAL_AMOUNT`** – The total value of the order.
- **`ORDER_DATE`** – Date when the order was placed.
- **`ORDER_STATUS`** – Status of the order (e.g., `ORDER_COMPLETED`).

##  SQL Query with Explanation

```sql
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
JOIN order_contact_mech ocm 
    ON oh.order_id = ocm.order_id
JOIN postal_address pa 
    ON pa.contact_mech_id = ocm.contact_mech_id
JOIN party_contact_mech pcm 
    ON pcm.contact_mech_id = pa.contact_mech_id
JOIN person per 
    ON per.party_id = pcm.party_id
WHERE oh.status_id = 'ORDER_COMPLETED'
AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
AND pa.state_province_geo_id = 'NY' 
AND pa.city = 'New York';

```

## Explanation:
1️ **Retrieve Completed Orders**:
   - Selecting orders from `order_header` where `status_id = 'ORDER_COMPLETED'`.

2️ **Joining with Order Contact Mechanisms**:
   - `JOIN order_contact_mech` ensures we get the **shipping address** associated with the order.

3️ **Fetching Postal Address Details**:
   - `JOIN postal_address` provides **street address, city, state, and postal code**.

4️ **Linking to Customer Details**:
   - `JOIN party_contact_mech` and `JOIN person` retrieve **customer name**.

5️ **Filtering for New York Orders**:
   - `pa.state_province_geo_id = 'NY'` ensures only **New York** orders.
   - `pa.city = 'New York'` ensures the specific **city** is targeted.

 ## Query Cost**: 
 - **Estimated Query Cost:** 8,055.33  


# 4 Completed Return Items

## Business Problem
Customer service and finance often need insights into returned items to manage refunds, replacements, and inventory restocking.

## Fields to Retrieve
This query retrieves details of **completed return items**, including:

- `RETURN_ID`
- `ORDER_ID`
- `PRODUCT_STORE_ID`
- `STATUS_DATETIME`
- `ORDER_NAME`
- `FROM_PARTY_ID`
- `RETURN_DATE`
- `ENTRY_DATE`
- `RETURN_CHANNEL_ENUM_ID`

## SQL Query

```sql
SELECT 
      rh.return_id,
      oh.ORDER_ID,
      oh.PRODUCT_STORE_ID,
      oh.ORDER_NAME,
      rh.FROM_PARTY_ID,
      oh.ENTRY_DATE,
      rh.return_date,
      rh.RETURN_CHANNEL_ENUM_ID
FROM return_header rh
JOIN return_item ri ON rh.return_id = ri.return_id
JOIN order_header oh ON ri.ORDER_ID = oh.order_id
WHERE ri.status_id = 'RETURN_COMPLETED';
```

## Query Explanation
This query efficiently retrieves completed return items:

1 **Joining `return_header` and `return_item`**: Links return transactions with item-level details.

2 **Joining `order_header`**: Fetches order-specific details like store ID, order name, and entry date.

## Query Cost 
- **Estimated Query Cost:** 7225.4

---

# 5 Orders with Multiple Returns

## Business Problem

Analyzing orders with multiple returns can help identify potential fraud, chronic issues with certain items, or inconsistencies in shipping processes. Understanding these patterns can improve operational efficiency and reduce costs associated with returns.

## Fields to Retrieve

The query retrieves the following details for orders with multiple returns:

- `ORDER_ID` - The unique identifier of the order.
- `RETURN_ID` - The return transaction associated with the order.
- `RETURN_DATE` - The date when the return was processed.
- `RETURN_REASON` - The reason provided for the return.
- `RETURN_QUANTITY` - The number of returned items.

## SQL Query

```sql
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
```

## Query Explanation

1️ **Identifies orders with multiple returns**:
   - The subquery groups return items by `order_id`.
   - It filters only those orders where the count of distinct `return_id` values is greater than 1.

2️ **Joins `return_header` and `return_item`**:
   - The `return_item` table links individual return items to orders.
      
3️ **Filters results based on the identified multiple-return orders**:
   - The `WHERE` clause ensures that only orders with multiple return transactions are included.

## Query Cost
- - **Estimated Query Cost:** `1925.50`.




