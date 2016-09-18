DECLARE @Id uniqueidentifier = 'ALERT_ID'
DECLARE @IsMonitor tinyint = (SELECT DISTINCT IsMonitorAlert FROM AlertView WHERE Id = @id)

IF @IsMonitor = 1
BEGIN
	SELECT DISTINCT
		A.AlertStringName AS 'Alert_Name',
		A.AlertStringDescription AS 'Alert_Description',
		A.TimeRaised,
		A.RepeatCount,
		A.Category,
		A.Severity,
		A.Priority,
		M.DisplayName AS 'Monitor_Name',
		M.Description AS 'Monitor_Description',
		MP.DisplayName AS 'Management_Pack',
		A.MonitoringObjectId,
		A.MonitoringObjectDisplayName,
		A.MonitoringObjectName,
		A.MonitoringObjectPath,
		A.MonitoringObjectFullName,
		A.AlertParams,
		KA.KnowledgeContent AS 'Knowledge'
	FROM AlertView A Join
	MonitorView M ON
	A.ProblemId = M.Id JOIN
	ManagementPackView MP ON
	M.ManagementPackId = MP.Id JOIN
	KnowledgeArticle KA ON
	M.Id = KnowledgeReferenceId
	WHERE A.Id = @id
END
ELSE
BEGIN
	SELECT DISTINCT
		A.AlertStringName AS 'Alert_Name',
		A.AlertStringDescription AS 'Alert_Description',
		A.TimeRaised,
		A.RepeatCount,
		A.Category,
		A.Severity,
		A.Priority,
		R.DisplayName AS 'Rule_Name',
		R.Description AS 'Rule_Description',
		MP.DisplayName AS 'Management_Pack',
		A.MonitoringObjectId,
		A.MonitoringObjectDisplayName,
		A.MonitoringObjectName,
		A.MonitoringObjectPath,
		A.MonitoringObjectFullName,
		A.AlertParams,
		KA.KnowledgeContent AS 'Knowledge'
	FROM AlertView A Join
	RuleView R ON
	A.MonitoringRuleId = R.Id JOIN
	ManagementPackView MP ON
	R.ManagementPackId = MP.Id JOIN
	KnowledgeArticle KA ON
	R.Id = KnowledgeReferenceId
	Where A.Id = @id
END