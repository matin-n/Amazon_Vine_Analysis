# Amazon_Vine_Analysis

## Project Overview
In this project, I analyzed Amazon reviews written by the Amazon Vince program members. The Amazon Vine program is an invite-only program that utilizes hand-selected reviewers to receive free products for compensation for writing a review. In addition, the Amazon Vine program allows manufacturers and publishers to pay Amazon a small fee for curating reviews from the Amazon userbase.

I chose and analyzed the Digital Video Games dataset by utilizing the ETL process to extract the dataset, transform the data, connect it to an AWS RDS instance, and load the transformed data into a database. Then, I analyzed the data with SQL to determine any bias towards favorable reviews from Vine members within my dataset.

## ETL Process
### Extract Amazon Data

```python
from pyspark import SparkFiles
url = "https://s3.amazonaws.com/amazon-reviews-pds/tsv/amazon_reviews_us_Digital_Video_Games_v1_00.tsv.gz"
spark.sparkContext.addFile(url)
df = spark.read.option("encoding", "UTF-8").csv(SparkFiles.get("amazon_reviews_us_Digital_Video_Games_v1_00.tsv.gz"), sep="\t", header=True, inferSchema=True)
df.show()
```
|marketplace|customer_id|     review_id|product_id|product_parent|       product_title|   product_category|star_rating|helpful_votes|total_votes|vine|verified_purchase|     review_headline|         review_body|review_date|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|         US|   21269168| RSH1OZ87OYK92|B013PURRZW|     603406193|Madden NFL 16 - X...|Digital_Video_Games|          2|            2|          3|   N|                N|A slight improvem...|I keep buying mad...| 2015-08-31|
|         US|     133437|R1WFOQ3N9BO65I|B00F4CEHNK|     341969535| Xbox Live Gift Card|Digital_Video_Games|          5|            0|          0|   N|                Y|          Five Stars|             Awesome| 2015-08-31|
|         US|   45765011| R3YOOS71KM5M9|B00DNHLFQA|     951665344|Command & Conquer...|Digital_Video_Games|          5|            0|          0|   N|                Y|Hail to the great...|If you are preppi...| 2015-08-31|
|         US|     113118|R3R14UATT3OUFU|B004RMK5QG|     395682204|Playstation Plus ...|Digital_Video_Games|          5|            0|          0|   N|                Y|          Five Stars|             Perfect| 2015-08-31|
|         US|   22151364| RV2W9SGDNQA2C|B00G9BNLQE|     640460561|Saints Row IV - E...|Digital_Video_Games|          5|            0|          0|   N|                Y|          Five Stars|            Awesome!| 2015-08-31|
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

### Transform DataFrames to match table schema

#### customers_table
Create the `customers_table` DataFrame and table:
```python
customers_df = df.groupBy("customer_id").agg(count("customer_id").alias("customer_count"))
customers_df.show()
```

| customer_id | customer_count |
| :---: | :---: |
|   26079415|             1|
|   12521601|             2|
|    4593696|             1|
|    1468259|             1|
|   38173350|             1|
| ... | ... |

#### products_table
Create the `products_table` DataFrame and drop duplicates:
```python
products_df = df.select(["product_id", "product_title"]).dropDuplicates()
products_df.show()
```


|product_id|       product_title|
| :---: | :---: |
|B001TK3VTC|Cubis Gold 2 [Dow...|
|B002MUB0TG|Little Shop of Tr...|
|B00DRO824C|X2 The Threat [On...|
|B00CMDKNHI| 100% Hidden Objects|
|B00CMSCTA2|Age of Empires II...|
| ... | ... |

#### review_id_table
Create the `review_id_table` DataFrame:
```python
review_id_df = df.select(["review_id", "customer_id", "product_id", "product_parent", to_date("review_date", 'yyyy-MM-dd').alias("review_date")])
review_id_df.show()
```

|     review_id|customer_id|product_id|product_parent|review_date|
| :---: | :---: | :---: | :---: | :---: |
| RSH1OZ87OYK92|   21269168|B013PURRZW|     603406193| 2015-08-31|
|R1WFOQ3N9BO65I|     133437|B00F4CEHNK|     341969535| 2015-08-31|
| R3YOOS71KM5M9|   45765011|B00DNHLFQA|     951665344| 2015-08-31|
|R3R14UATT3OUFU|     113118|B004RMK5QG|     395682204| 2015-08-31|
| RV2W9SGDNQA2C|   22151364|B00G9BNLQE|     640460561| 2015-08-31|
| ... | ... | ... | ... | ... |

#### vine_table
Create the `vine_table` DataFrame:
```python
vine_df = df.select(["review_id", "star_rating", "helpful_votes", "total_votes", "vine", "verified_purchase"])
vine_df.show()
```

|     review_id|star_rating|helpful_votes|total_votes|vine|verified_purchase|
| :---: | :---: | :---: | :---: | :---: | :---: |
| RSH1OZ87OYK92|          2|            2|          3|   N|                N|
|R1WFOQ3N9BO65I|          5|            0|          0|   N|                Y|
| R3YOOS71KM5M9|          5|            0|          0|   N|                Y|
|R3R14UATT3OUFU|          5|            0|          0|   N|                Y|
| RV2W9SGDNQA2C|          5|            0|          0|   N|                Y|
| ... | ... | ... | ... | ... | ... |

### Load data to AWS RDS instance and write each DataFrame to its table

```python
# Configure settings for RDS
mode = "append"
jdbc_url="jdbc:postgresql://<endpoint>:5432/<database_name>"
config = {"user":"postgres",
          "password": "<password>",
          "driver":"org.postgresql.Driver"}

# Write review_id_df to table in RDS
review_id_df.write.jdbc(url=jdbc_url, table='review_id_table', mode=mode, properties=config)

# Write products_df to table in RDS
products_df.write.jdbc(url=jdbc_url, table='products_table', mode=mode, properties=config)

# Write customers_df to table in RDS
customers_df.write.jdbc(url=jdbc_url, table='customers_table', mode=mode, properties=config)

# Write vine_df to table in RDS
vine_df.write.jdbc(url=jdbc_url, table='vine_table', mode=mode, properties=config)
```

### SQL Queries

#### Table Schema
```sql
CREATE TABLE review_id_table (
  review_id TEXT PRIMARY KEY NOT NULL,
  customer_id INTEGER,
  product_id TEXT,
  product_parent INTEGER,
  review_date DATE -- this should be in the formate yyyy-mm-dd
);

-- This table will contain only unique values
CREATE TABLE products_table (
  product_id TEXT PRIMARY KEY NOT NULL UNIQUE,
  product_title TEXT
);

-- Customer table for first data set
CREATE TABLE customers_table (
  customer_id INT PRIMARY KEY NOT NULL UNIQUE,
  customer_count INT
);

-- Vine table
CREATE TABLE vine_table (
  review_id TEXT PRIMARY KEY,
  star_rating INTEGER,
  helpful_votes INTEGER,
  total_votes INTEGER,
  vine TEXT,
  verified_purchase TEXT
);
```

#### Result Queries
```sql
-- Step 1: Retrieve all rows where `total_votes` is equal to or greater than 20
SELECT * FROM vine_table WHERE total_votes >= 20
-- Count: 3,342

-- Step 2: Filter the query from Step 1 and retrieve all the rows where the number of helpful_votes divided by total_votes is equal to or greater than 50%.
SELECT * FROM vine_table WHERE (total_votes >= 20) AND (CAST(helpful_votes AS FLOAT) / CAST(total_votes AS FLOAT) >= 0.5)
-- Count: 1,685

-- Step 3: Filter the query created in Step 2, and create a new query that retrieves all the rows where a review was written as part of the Vine program (paid), vine == 'Y'
SELECT * FROM vine_table WHERE (total_votes >= 20) AND (CAST(helpful_votes AS FLOAT) / CAST(total_votes AS FLOAT) >= 0.5) AND (VINE = 'Y')
-- Count: 0

-- Step 4: Repeat Step 3, but this time retrieve all the rows where the review was not part of the Vine program (unpaid), vine == 'N'
SELECT * FROM vine_table WHERE (total_votes >= 20) AND (CAST(helpful_votes AS FLOAT) / CAST(total_votes AS FLOAT) >= 0.5) AND (VINE = 'N')
-- Count: 1,685

-- Step 5: How many reviews were 5 stars from non-Vine?
SELECT * FROM vine_table WHERE (total_votes >= 20) AND (CAST(helpful_votes AS FLOAT) / CAST(total_votes AS FLOAT) >= 0.5) AND (VINE = 'N') AND star_rating = 5
-- Count: 631
```

## Results

First, to determine reviews that are likely to be considered helpful I filtered the reviews to include only reviews that had 20 or more total votes. Second, I filtered the reviews to only include those that had more than half of votes marking the review as helpful. Finally, I filtered the reviews to determine those that are apart of the vine program and are not apart of the vine program.

- How many Vines and non-Vine reviews were there?
  - Vine Reviews: 0
  - Non-Vine Reviews: 1,685
- How many Vine reviews were 5 stars? How many non-Vine reviews were 5 stars?
  - 5 Star Vine Reviews: 0
  - 5 Star non-Vine reviews: 631
- What percentage of Vine reviews were 5 stars? What percentage of non-Vine reviews were 5 stars?
  - Percentage of 5 Star Vine Reviews: 0%
  - Percentage of 5 Star non-Vine Reviews: 37.5% (631/1685)

I was shocked to see how there was not a single Vine review within the Digital Video Games category. I was curious to see if the filters I enacted were influencing the results. So, I ran another query on the original dataset to count the amount of vine reviews without any filters and the results were still 0 vine reviews! It is safe to say that there is no positivity bias for reviews in the Vine program as there is not a single review within the dataset.
