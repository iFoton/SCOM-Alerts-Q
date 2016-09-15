SELECT DISTINCT
	MonitoringObjectId,
	MonitoringObjectDisplayName,
	MonitoringObjectName,
	MonitoringObjectPath,
	MonitoringObjectFullName,
	IsMonitorAlert,
	Priority,
	Severity,
	Category,
	TimeRaised,
	LastModified,
	RepeatCount,
	AlertStringName,
	AlertStringDescription,
	AlertParams
FROM AlertView 
WHERE ID = 'ALERT_ID'