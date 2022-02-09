/*SET datestyle = GERMAN, DMY;
Bucketing Users Into Cohort
First we bucket them into different cohort by their sign up month, and store into cohort_items
(user_id, cohort_month), each */ WITH COHORT_ITEMS AS
	(SELECT DATE_TRUNC('month',

										first_purchase_date::TIMESTAMP)::date AS cohort_month,
			user_id AS user_id
		FROM first_purchases FP
		WHERE product_line = 'Restaurant'
		ORDER BY 1, 2), /*After that, we build user_activities which
(user_id, month_number): user X has activity in month number X*/ PURCHASES AS
	(SELECT A.user_id,
			DATE_PART('month',

				AGE(DATE_TRUNC('month',

									A.purchase_date::TIMESTAMP)::date,

					C.cohort_month)) AS month_number
		FROM purchases A
		LEFT JOIN cohort_items C ON A.user_id = C.user_id
		GROUP BY 1, 2), /*Cohort Size: is simply how many users are in each group
(cohort_month, size)*/ COHORT_SIZE AS
	(SELECT COHORT_MONTH,
			COUNT(1) AS NUM_USERS
		FROM COHORT_ITEMS
		GROUP BY 1
		ORDER BY 1), --And finally, putting them together with the below:
-- (cohort_month, month_number, cnt)
B AS
	(SELECT C.cohort_month,
			A.month_number,
			COUNT(1) AS NUM_USERS
		FROM purchases A
		LEFT JOIN cohort_items C ON A.user_id = C.user_id
		GROUP BY 1, 2) -- our final value: (cohort_month, size, month_number, percentage)

SELECT B.cohort_month,
	S.NUM_USERS AS TOTAL_USERS,
	B.MONTH_NUMBER,
	B.NUM_USERS::float * 100 / S.NUM_USERS AS PERCENTAGE
FROM B
LEFT JOIN cohort_size S ON B.cohort_month = S.cohort_month
WHERE B.cohort_month IS NOT NULL
ORDER BY 1, 3