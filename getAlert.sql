DECLARE @Id uniqueidentifier = 'ALERT_ID'
DECLARE @IsMonitor tinyint = (SELECT DISTINCT IsMonitorAlert FROM AlertView WHERE Id = @id)

IF @IsMonitor = 1
BEGIN
	SELECT DISTINCT
		A.AlertStringName AS 'Alert_Name',
		A.Severity,
		A.TimeRaised AS 'Time_Raised',
		A.Category,
		A.AlertStringDescription AS 'Alert_Description',
		A.ResolutionState AS 'Resolution_State',
		RS.ResolutionStateName,
		A.RepeatCount AS 'Repeat_Count',
		A.Priority,
		M.DisplayName AS 'Monitor_Name',
		M.Description AS 'Monitor_Description',
		MP.DisplayName AS 'Management_Pack',
		A.MonitoringObjectDisplayName,
		A.MonitoringObjectName,
		A.MonitoringObjectPath,
		A.MonitoringObjectFullName,
		A.MonitoringObjectId,
		A.Id AS 'Alert_Id',
		'STUB' AS 'Subscription',
		'STUB' AS 'Subscribers',
		A.AlertParams,
		KA.KnowledgeContent AS 'Knowledge'
	FROM AlertView A Join
	MonitorView M ON
	A.ProblemId = M.Id JOIN
	ManagementPackView MP ON
	M.ManagementPackId = MP.Id LEFT JOIN
	KnowledgeArticle KA ON
	M.Id = KnowledgeReferenceId JOIN
	ResolutionStateView RS ON
	A.ResolutionState = RS.ResolutionState
	WHERE A.Id = @id
END
ELSE
BEGIN
	SELECT DISTINCT
		A.AlertStringName AS 'Alert_Name',
		A.Severity,
		A.TimeRaised AS 'Time_Raised',
		A.Category,
		A.AlertStringDescription AS 'Alert_Description',
		A.ResolutionState AS 'Resolution_State',
		RS.ResolutionStateName,
		A.RepeatCount AS 'Repeat_Count',
		A.Priority,
		R.DisplayName AS 'Rule_Name',
		R.Description AS 'Rule_Description',
		MP.DisplayName AS 'Management_Pack',
		A.MonitoringObjectDisplayName,
		A.MonitoringObjectName,
		A.MonitoringObjectPath,
		A.MonitoringObjectFullName,
		A.MonitoringObjectId,
		A.Id AS 'Alert_Id',
		'STUB' AS 'Subscription',
		'STUB' AS 'Subscribers',
		A.AlertParams,		
		KA.KnowledgeContent AS 'Knowledge'
	FROM AlertView A Join
	RuleView R ON
	A.MonitoringRuleId = R.Id JOIN
	ManagementPackView MP ON
	R.ManagementPackId = MP.Id LEFT JOIN
	KnowledgeArticle KA ON
	R.Id = KnowledgeReferenceId JOIN
	ResolutionStateView RS ON
	A.ResolutionState = RS.ResolutionState
	Where A.Id = @id
END