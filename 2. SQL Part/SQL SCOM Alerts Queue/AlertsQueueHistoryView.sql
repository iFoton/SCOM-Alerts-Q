USE SCOMAddons
GO
ALTER VIEW dbo.AlertsQueueHistoryView  
AS 
SELECT 
	AV.AlertStringName AS 'Alert Name',
	Severity = CASE AV.Severity WHEN '1' THEN 'Warning' WHEN '2' THEN 'Critical' WHEN '0' THEN 'Information' END,
	RV.DisplayName AS 'Subscription',
	AQH.Description,
	AQH.TimeStmp
FROM [SCOMAddons].[dbo].AlertsQueueHistory AQH
	LEFT JOIN [OperationsManager].[dbo].AlertView AV
	ON AQH.AlertId = AV.id 
	LEFT JOIN [OperationsManager].[dbo].RuleView RV
	ON AQH.SubscriptionId = RV.id