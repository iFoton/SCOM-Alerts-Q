USE SCOMAddons
GO
ALTER VIEW dbo.AlertsQueueView  
AS 
SELECT
	Q.QID,
	Q.SubscriptionID,
	Q.Source,
	ISNULL(A.AlertStringName,A.Name) AS 'Alert_Name',
	Severity = CASE A.Severity WHEN '1' THEN 'Warning' WHEN '2' THEN 'Critical' ELSE 'Information' END,
	A.TimeRaised AS 'Time_Raised',
	A.Category,
	A.AlertStringDescription AS 'Alert_Description',
	RS.ResolutionStateName + ' (' + CONVERT(varchar,A.ResolutionState) + ')' AS 'Resolution_State',
	A.RepeatCount AS 'Repeat_Count',
	A.Priority,
	Type = CASE A.IsMonitorAlert WHEN '1' THEN 'Monitor' WHEN '0' THEN 'Rule'END,
	MonitorRule_Name        = CASE A.IsMonitorAlert WHEN '1' THEN M.DisplayName WHEN '0' THEN R.DisplayName END,
	MonitorRule_Description = CASE A.IsMonitorAlert WHEN '1' THEN M.Description WHEN '0' THEN R.Description END,
	MP.DisplayName AS 'Management_Pack',
	A.MonitoringObjectDisplayName,
	A.MonitoringObjectName,
	A.MonitoringObjectPath,
	A.MonitoringObjectFullName,
	A.MonitoringObjectId,
	Q.AlertId AS 'Alert_Id',
	A.AlertParams,
	'STUB' AS 'Subscription',
	'STUB' AS 'Subscribers',
	A.Context,
	KA.KnowledgeContent AS 'Knowledge',
	Q.TimeStmp
FROM
	AlertsQueue Q JOIN
    [OperationsManager].dbo.AlertView A ON
    Q.AlertId = A.Id LEFT JOIN
	[OperationsManager].dbo.RuleView R ON
	A.MonitoringRuleId = R.Id LEFT JOIN
	[OperationsManager].dbo.MonitorView M ON
	A.MonitoringRuleId = M.Id JOIN
	[OperationsManager].dbo.ManagementPackView MP ON
	(M.ManagementPackId = MP.Id) OR (R.ManagementPackId = MP.Id) LEFT JOIN
	[OperationsManager].dbo.KnowledgeArticle KA ON
	(M.Id = KA.KnowledgeReferenceId) OR (R.Id = KA.KnowledgeReferenceId) JOIN
	[OperationsManager].dbo.ResolutionStateView RS ON
	A.ResolutionState = RS.ResolutionState