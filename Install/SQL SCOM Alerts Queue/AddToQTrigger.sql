USE SCOMAddons
GO
DROP TRIGGER [dbo].[AddToQTrigger]
GO
CREATE TRIGGER [dbo].[AddToQTrigger] ON [SCOMAddons].[dbo].[AlertsQueue]
INSTEAD OF INSERT
AS
BEGIN

DECLARE @AlertId uniqueidentifier = (SELECT AlertId FROM inserted)
DECLARE @currResolutionState tinyint = (SELECT TOP 1 ResolutionState FROM [OperationsManager].dbo.AlertView WHERE Id = @AlertID)

DECLARE @ResolutionState tinyint = (SELECT toState FROM inserted)
DECLARE @CustomField10 nvarchar(255)

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
	
	SET @ResolutionState = 200
	SET @CustomField10 = 'Ignored, No Alert in AlertView'	
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
					'Ignored, Gates Unavailable.' AS 'Description',
					(SELECT GETDATE()) AS 'TimeStmp'
				FROM inserted

			SET @ResolutionState = 200
			SET @CustomField10 = 'Ignored, Gates Unavailable'	
		END
END

--If this is Closed Alert then check what we send notification about it early
ELSE IF @currResolutionState = 255
BEGIN
	IF @AlertId NOT IN (SELECT AlertId FROM [SCOMAddons].dbo.AlertsQueueHistory WHERE Description = 'Sended'
						UNION
						SELECT AlertId FROM [SCOMAddons].dbo.AlertsQueue)
	SET @ResolutionState = 200
END

--If not Ignored state then add Alert to Queue
IF @ResolutionState != 200
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
--Else if this not Closed Alert then update state to Ignored
ELSE IF @currResolutionState != 255
BEGIN	
	DECLARE @BaseManagedEntityId uniqueidentifier
	DECLARE @Owner nvarchar(255)
	DECLARE @CustomField1 nvarchar(255)
	DECLARE @CustomField2 nvarchar(255)
	DECLARE @CustomField3 nvarchar(255)
	DECLARE @CustomField4 nvarchar(255)
	DECLARE @CustomField5 nvarchar(255)
	DECLARE @CustomField6 nvarchar(255)
	DECLARE @CustomField7 nvarchar(255)
	DECLARE @CustomField8 nvarchar(255)
	DECLARE @CustomField9 nvarchar(255)
	DECLARE @Comments nvarchar(2000) = N'Alert modified by Alerts Queue solution'
	DECLARE @TimeLastModified datetime
	DECLARE @ModifiedBy nvarchar(255) = N'AlertQ'
	DECLARE @TicketId nvarchar(150)
	DECLARE @ConnectorId uniqueidentifier = NULL
	DECLARE @ModifyingConnectorId uniqueidentifier = NULL
	DECLARE @TfsWorkItemId nvarchar(150)
	DECLARE @TfsWorkItemOwner nvarchar(255)

	SELECT  @BaseManagedEntityId = MonitoringObjectId,
			@Owner = Owner,
			@TimeLastModified = LastModified,
			@TicketId = TicketId,
			@ConnectorId = ConnectorId,
			@TfsWorkItemId = TfsWorkItemId,
			@TfsWorkItemOwner = TfsWorkItemOwner,
			@CustomField1 = CustomField1,
			@CustomField2 = CustomField2,
			@CustomField3 = CustomField3,
			@CustomField4 = CustomField4,
			@CustomField5 = CustomField5,
			@CustomField6 = CustomField6,
			@CustomField7 = CustomField7,
			@CustomField8 = CustomField8,
			@CustomField9 = CustomField9
	FROM [OperationsManager].dbo.AlertView WHERE Id = @AlertId

	--Execute stored procedure
	EXEC [OperationsManager].dbo.p_AlertUpdate
		@AlertId,
		@BaseManagedEntityId,
		@ResolutionState,
		@Owner,
		@CustomField1,@CustomField2,@CustomField3,@CustomField4,@CustomField5,@CustomField6,@CustomField7,@CustomField8,@CustomField9,@CustomField10,
		@Comments,
		@TimeLastModified,
		@ModifiedBy,
		@TicketId,@ConnectorId,@ModifyingConnectorId,@TfsWorkItemId,@TfsWorkItemOwner
END
END
