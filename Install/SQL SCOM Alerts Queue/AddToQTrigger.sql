USE OperationsManager
GO
DROP TRIGGER [dbo].[update_state_new]
GO
CREATE TRIGGER [dbo].[update_state_new] ON [OperationsManager].[dbo].[AlertsQueue]
INSTEAD OF INSERT
AS
BEGIN

DECLARE @isFailGate bit = 0
DECLARE @AlertID uniqueidentifier = (SELECT AlertId FROM inserted)
--Checking for Null Alert
IF (not exists (SELECT 1 FROM AlertView WHERE Id = @AlertID))
BEGIN
	INSERT INTO dbo.AlertsQueueHistory
		SELECT
			(SELECT NEWID()) as 'QID',
			AlertId,
			SubscriptionID,
			Source,
			isChangeState,
			'Ignored, No Alert in AlertView.' AS 'Description',
			(SELECT GETDATE()) AS 'TimeStmp'
		FROM inserted
END

--Checking Gates Availability
ELSE IF (SELECT DISTINCT AlertStringName FROM AlertView WHERE id = @AlertID) IN ('Failed to Connect to Computer','Health Service Heartbeat Failure')
BEGIN
	IF (SELECT SUM(CONVERT(int,MEGV.IsAvailable))
		FROM dbo.TypedManagedEntity AS TME 
		 INNER JOIN dbo.BaseManagedEntity AS BME 
			 ON BME.[BaseManagedEntityId] = TME.[BaseManagedEntityId]
		 INNER JOIN dbo.ManagedEntityGenericView AS MEGV 
			 ON MEGV.[Id] = BME.[TopLevelHostEntityId]
		 INNER JOIN dbo.Relationship AS HSC 
			 ON HSC.[TargetEntityId] = BME.[BaseManagedEntityId]
		 INNER JOIN dbo.BaseManagedEntity AS BME2 
			 ON BME2.[BaseManagedEntityId] = HSC.[SourceEntityId] 
		WHERE (((TME.[IsDeleted] = 0) AND (MEGV.[IsDeleted] = 0 AND MEGV.[TypedMonitoringObjectIsDeleted] = 0) AND (HSC.[IsDeleted] = 0) AND 
			  (TME.[ManagedTypeId] = '9189A49E-B2DE-CAB0-2E4F-4925B68E335D') AND (HSC.[RelationshipTypeId] IN ('37848e16-37a2-b81b-daaf-60a5a626be93','CA26F3F0-B8CE-C193-D6DF-632D53DEE714')))) AND
		      ([BME2].[TopLevelHostEntityId] IN (SELECT id 
												 FROM ManagedEntityGenericView 
												 WHERE DisplayName = (SELECT MonitoringObjectDisplayName
																	  FROM AlertView 
																	  WHERE id = @AlertID) AND FullName LIKE 'Microsoft.Windows.Computer:%'))) = 0
		BEGIN
			INSERT INTO dbo.AlertsQueueHistory
				SELECT 
					(SELECT NEWID()) as 'QID',
					AlertId,
					SubscriptionID,
					Source,
					isChangeState,
					'Ignored, Gates unavailable.' AS 'Description',
					(SELECT GETDATE()) AS 'TimeStmp'
				FROM inserted
					
			SET @isFailGate = 1
		END
END

IF @isFailGate = 0
BEGIN
	INSERT INTO dbo.AlertsQueue
				SELECT 
					(SELECT NEWID()) as 'QID',
					AlertId,
					SubscriptionID,
					Source,
					isChangeState,
					(SELECT GETDATE()) AS 'TimeStmp'
				FROM inserted
END

END
