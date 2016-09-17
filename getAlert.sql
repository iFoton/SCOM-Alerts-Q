DECLARE @Id uniqueidentifier = 'ALERT_ID'
DECLARE @IsMonitor tinyint = (SELECT DISTINCT IsMonitorAlert FROM AlertView WHERE Id = @id)

IF @IsMonitor = 1
BEGIN --If Monitor
	SELECT DISTINCT
		A.AlertStringName AS 'Alert Name',
		A.AlertStringDescription AS 'Alert Description',
		A.TimeRaised,
		A.RepeatCount,
		A.Category,
		A.Severity,
		A.Priority,
		M.DisplayName AS 'Monitor Name',
		M.Description AS 'Monitor Description',
		MP.DisplayName AS 'Management Pack',
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
ELSE --If Rule
BEGIN
	SELECT DISTINCT
		A.AlertStringName AS 'Alert Name',
		A.AlertStringDescription AS 'Alert Description',
		A.TimeRaised,
		A.RepeatCount,
		A.Category,
		A.Severity,
		A.Priority,
		R.DisplayName AS 'Rule Name',
		R.Description AS 'Rule Description',
		MP.DisplayName AS 'Management Pack',
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