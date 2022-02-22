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

-- Step 5: Determine the total number of reviews, the number of 5-star reviews, and the percentage of 5-star reviews for the two types of review (paid vs unpaid)
SELECT * FROM vine_table WHERE (total_votes >= 20) AND (CAST(helpful_votes AS FLOAT) / CAST(total_votes AS FLOAT) >= 0.5) AND (VINE = 'N') AND star_rating = 5
-- Count: 631


-- Additional: Determine if there are any vine reviews within the dataset
SELECT COUNT(*) FROM vine_table WHERE vine = 'Y'
-- Count: 0

SELECT COUNT(*) FROM vine_table WHERE vine = 'N'
-- Count: 145,431

-- Total Number of Reviews
SELECT COUNT(*) FROM vine_table 
-- Count: 145,431