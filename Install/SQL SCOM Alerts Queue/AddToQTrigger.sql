USE SCOMAddons
GO
--DROP TRIGGER [dbo].[AddToQTrigger]
--GO
CREATE TRIGGER [dbo].[AddToQTrigger] ON [SCOMAddons].[dbo].[AlertsQueue]
INSTEAD OF INSERT
AS
BEGIN

DECLARE @stop bit = 0
DECLARE @AlertID uniqueidentifier = (SELECT AlertId FROM inserted)
--Checking for Null Alert
IF (not exists (SELECT 1 FROM [OperationsManager].dbo.AlertView WHERE Id = @AlertID))
BEGIN
	INSERT INTO [SCOMAddons].dbo.AlertsQueueHistory
		SELECT
			(SELECT NEWID()) as 'QID',
			AlertId,
			SubscriptionID,
			Source,
			toState,
			'Ignored, No Alert in AlertView.' AS 'Description',
			(SELECT GETDATE()) AS 'TimeStmp'
		FROM inserted

	SET @stop = 1
END

--Checking Gates Availability
ELSE IF (SELECT DISTINCT AlertStringName FROM [OperationsManager].dbo.AlertView WHERE id = @AlertID) IN ('Failed to Connect to Computer','Health Service Heartbeat Failure')
BEGIN
	IF (SELECT SUM(CONVERT(int,MEGV.IsAvailable))
		FROM [OperationsManager].dbo.TypedManagedEntity AS TME 
		 INNER JOIN [OperationsManager].dbo.BaseManagedEntity AS BME 
			 ON BME.[BaseManagedEntityId] = TME.[BaseManagedEntityId]
		 INNER JOIN [OperationsManager].dbo.ManagedEntityGenericView AS MEGV 
			 ON MEGV.[Id] = BME.[TopLevelHostEntityId]
		 INNER JOIN [OperationsManager].dbo.Relationship AS HSC 
			 ON HSC.[TargetEntityId] = BME.[BaseManagedEntityId]
		 INNER JOIN [OperationsManager].dbo.BaseManagedEntity AS BME2 
			 ON BME2.[BaseManagedEntityId] = HSC.[SourceEntityId] 
		WHERE (((TME.[IsDeleted] = 0) AND (MEGV.[IsDeleted] = 0 AND MEGV.[TypedMonitoringObjectIsDeleted] = 0) AND (HSC.[IsDeleted] = 0) AND 
			  (TME.[ManagedTypeId] = '9189A49E-B2DE-CAB0-2E4F-4925B68E335D') AND (HSC.[RelationshipTypeId] IN ('37848e16-37a2-b81b-daaf-60a5a626be93','CA26F3F0-B8CE-C193-D6DF-632D53DEE714')))) AND
		      ([BME2].[TopLevelHostEntityId] IN (SELECT id 
												 FROM [OperationsManager].dbo.ManagedEntityGenericView 
												 WHERE DisplayName = (SELECT MonitoringObjectDisplayName
																	  FROM [OperationsManager].dbo.AlertView 
																	  WHERE id = @AlertID) AND FullName LIKE 'Microsoft.Windows.Computer:%'))) = 0
		BEGIN
			INSERT INTO [SCOMAddons].dbo.AlertsQueueHistory
				SELECT 
					(SELECT NEWID()) as 'QID',
					AlertId,
					SubscriptionID,
					Source,
					toState,
					'Ignored, Gates unavailable.' AS 'Description',
					(SELECT GETDATE()) AS 'TimeStmp'
				FROM inserted
					
			SET @stop = 1
		END
END

IF @stop = 0
BEGIN
	INSERT INTO [SCOMAddons].dbo.AlertsQueue
				SELECT 
					(SELECT NEWID()) as 'QID',
					AlertId,
					SubscriptionID,
					Source,
					toState,
					(SELECT GETDATE()) AS 'TimeStmp'
				FROM inserted
END

END
