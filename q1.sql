with Cancelled as (
	-- All the reservations with cancel status 
	select Cust_Reservation.Email as Email, count(Status) as Num 
	from Reservation, Cust_Reservation 
	where Reservation.ID = Cust_Reservation.Reservation_ID and Reservation.Status = 'Cancelled' 
	group by Cust_Reservation.Email

),
Not_Cancelled as (
	-- All the reservations which were not cancelled. 
	select Cust_Reservation.Email as Email, count(Status) as Num 
	from Reservation, Cust_Reservation 
	where Reservation.ID = Cust_Reservation.Reservation_ID and Reservation.Status != 'Cancelled' 
	group by Cust_Reservation.Email
),
All_Reservations as (
	-- All the emails with their number of cancellations and number of reservations which 
	-- were not cancelled.
	select Cancelled.Email as Email, Cancelled.Num as Cancelled, Not_Cancelled.Num as Not_Cancelled 
	from Cancelled, Not_Cancelled 
	where Cancelled.Email = Not_Cancelled.Email
),
Ratios as(
	-- Emails with their corresponding cancellation ratios
	select Email, cast(Cancelled as decimal) / cast(Not_Cancelled as decimal) as Ratio 
	from All_Reservations 
	order by Ratio desc, Email
)
-- Final querry with the formated output. 
select Customer.Email as Customer_Email, Ratios.Ratio as Cancel_Ratio 
from Ratios, Customer 
where Ratios.Email = Customer.Email 
order by Ratios.Ratio desc, Customer.Email 
limit 2;
