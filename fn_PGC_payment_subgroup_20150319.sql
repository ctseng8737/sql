USE [subctontrcker_20150130]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_PGC_payment_subgroup]    Script Date: 3/20/2015 11:45:55 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Chi Zen Tseng
-- Create date: 2/17/2015
-- Description:	Payments to or cumulate to a specified period 
--				of certain certification
-- Paremeter:   @report_month smallint
--				@report_year smallint
--              AorC varchar(10): C -- accumulate to date, P -- current month
--							, return 0 when other value
--              @subgroup varchar(20): a specified company certification
--							, return 0 when null
------------------------------------------------------------------------------
-- 03/10/2015   replace the p.prime_is_mbe_PGC = 'N' logic with 'not exists (prime_id....'
-- 03/10/2015   Add the restriction that payment date are within 1/1/2014 and 12/31/2014
-- 03/06/2015   Add the baseline, calculation start from 01/2014
-- =============================================
CREATE FUNCTION [dbo].[fn_PGC_payment_subgroup]
(
@report_month int,
@report_year int,
@CorP varchar(10),
@subgroup varchar(20) 
)
RETURNS money
AS
BEGIN
	declare @total_paid money,
			@before_the_date date,
			@after_the_date date

	--if @subgroup is null return 0

	if @report_month = 12
		set @before_the_date=datefromparts(@report_year +1, 1, 1)
	else
		set @before_the_date = datefromparts(@report_year, @report_month + 1, 1)

	set @after_the_date = datefromparts(@report_year, @report_month, 1)

	select @total_paid = sum(p.amount) 
	from d6_payment p 
	inner join d6 on p.d6_id = d6.d6_id
	inner join company_certification cc on d6.mbe_id = cc.company_id --and cc.cert_id = @cert_id -- and cc.cert_no is not null 
	inner join lp_company_certification lpc on cc.cert_id = lpc.cert_id
	where p.payment_type = 'paid' 
	and p.date_issued >= '1/1/2014' and p.date_issued <= '12/31/2014'
	and @report_year * 100 + @report_month >= 201401
	--and p.prime_is_mbe_PGC = 'N'


	and not exists (select * from company_certification cc inner join lp_company_certification lcc
		on cc.cert_id = lcc.cert_id
		where lcc.cert_name =upper(@subgroup) AND cc.company_id = d6.prime_id)


	and lpc.cert_name = upper(@subgroup)
	and (
		(@report_month is null) or 
		(@report_year is null) OR 
		((upper(@CorP) = 'C') and (@report_year * 100 + @report_month >= d6.report_year * 100 + d6.report_month)) or
		((upper(@CorP) = 'P') and (d6.report_month = @report_month and d6.report_year = @report_year))
		)

	if @total_paid is null
		set @total_paid = 0

	RETURN @total_paid

END





GO


