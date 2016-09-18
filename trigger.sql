USE OperationsManager
GO
CREATE TRIGGER [dbo].[update_state] ON [OperationsManager].[dbo].[SCOM_ALERTS_QUEUE]
AFTER DELETE AS
IF (SELECT ResolutionState FROM dbo.Alert WHERE AlertId IN (SELECT AlertID FROM deleted)) = 0
BEGIN
	UPDATE dbo.Alert
	SET ResolutionState = 247,
		LastModifiedBy = N'AlertsQ',
		TimeResolutionStateLastModifiedInDB = (SELECT CURRENT_TIMESTAMP),
		TimeResolutionStateLastModified = (SELECT CURRENT_TIMESTAMP),
		LastModified = (SELECT CURRENT_TIMESTAMP),
		LastModifiedByNonConnector = (SELECT CURRENT_TIMESTAMP),
		LastModifiedExceptRepeatCount = (SELECT CURRENT_TIMESTAMP)
	WHERE dbo.Alert.AlertId IN (SELECT AlertID FROM deleted)
END
GO