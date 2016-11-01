USE SCOMAddons
GO
DROP TRIGGER [dbo].[RemoveFromQTrigger]
GO
CREATE TRIGGER [dbo].[RemoveFromQTrigger] ON [SCOMAddons].[dbo].[AlertsQueue]
INSTEAD OF DELETE AS

BEGIN

DECLARE @AlertId uniqueidentifier = (SELECT TOP 1 AlertId FROM deleted)

--If target state not equal "New" and current alert state is "New" then update State
	IF (SELECT toState FROM deleted) > 0 AND
	   (SELECT TOP 1 ResolutionState FROM [OperationsManager].dbo.AlertView WHERE ID = @AlertId) = 0
	BEGIN
		
		DECLARE @BaseManagedEntityId uniqueidentifier
		DECLARE @ResolutionState tinyint = (SELECT toState FROM deleted)
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
		DECLARE @CustomField10 nvarchar(255) = ('Sended at: ' + FORMAT(SWITCHOFFSET(CONVERT(datetimeoffset,GETDATE()),'+10:00'), 'd MMMM yyyy HH:mm:ss', 'en-US'))
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
				@CustomField8 = ISNULL(CustomField8,''),
				@TimeLastModified = LastModified,
				@TicketId = TicketId,
				@ConnectorId = ConnectorId,
				@TfsWorkItemId = TfsWorkItemId,
				@TfsWorkItemOwner = TfsWorkItemOwner
		FROM [OperationsManager].dbo.AlertView WHERE Id = @AlertId
		
		--Custom Fields
		SELECT  
			@CustomField1 = ('Alert Id: ' + CONVERT(varchar(36),AQV.Alert_Id)),
			@CustomField2 = ('Category: ' + AQV.Category),
			@CustomField3 = (AQV.Type + ' Name: ' + AQV.MonitorRule_Name),
			@CustomField4 = ('Management Pack: ' + AQV.Management_Pack),
			@CustomField5 = ('Object Name: ' + AQV.MonitoringObjectDisplayName),
			@CustomField6 = ('Full Name: ' + AQV.MonitoringObjectFullName),
			@CustomField7 = ('Object Id: ' + CONVERT(varchar(36),AQV.MonitoringObjectId)),
			@CustomField8 = ('Subscription: ' + REPLACE(@CustomField8,'Subscription: ','') + RV.DisplayName +'; '),
			@CustomField9 = ('Added to Queue at: ' + FORMAT(SWITCHOFFSET(CONVERT(datetimeoffset, AQV.TimeStmp),'+10:00'), 'd MMMM yyyy HH:mm:ss', 'en-US'))
		FROM 
			[SCOMAddons].dbo.AlertsQueueView AQV 
			LEFT JOIN [OperationsManager].dbo.RuleView RV 
			ON AQV.SubscriptionId = RV.Id
		WHERE AQV.Alert_Id = @AlertId

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
--Write History
	INSERT INTO [SCOMAddons].dbo.AlertsQueueHistory
		SELECT TOP 1
			QID,
			AlertId,
			SubscriptionId,
			Source,
			toState,
			'Sended' AS 'Description',
			TimeStmp
		FROM deleted
--Delete from Queue
	DELETE FROM [SCOMAddons].dbo.AlertsQueue
	WHERE QID IN (SELECT QID FROM deleted)
END
GO