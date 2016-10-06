USE SCOMAddons
GO
CREATE TRIGGER [dbo].[RemoveFromQTrigger] ON [SCOMAddons].[dbo].[AlertsQueue]
AFTER DELETE AS
BEGIN
--UpdateState
	IF (SELECT toState FROM deleted) > 0 AND
	   (SELECT TOP 1 ResolutionState FROM deleted d JOIN [OperationsManager].dbo.AlertView A ON d.AlertID = A.id) = 0
	BEGIN
		DECLARE @AlertId uniqueidentifier
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
		DECLARE @CustomField10 nvarchar(255)
		DECLARE @Comments nvarchar(2000) = N'Alert modified by Alerts Queue solution'
		DECLARE @TimeLastModified datetime
		DECLARE @ModifiedBy nvarchar(255) = N'AlertQ'
		DECLARE @TicketId nvarchar(150)
		DECLARE @ConnectorId uniqueidentifier = NULL
		DECLARE @ModifyingConnectorId uniqueidentifier = NULL
		DECLARE @TfsWorkItemId nvarchar(150)
		DECLARE @TfsWorkItemOwner nvarchar(255)

		SELECT  @AlertId = Id,
				@BaseManagedEntityId = MonitoringObjectId,
				@Owner = Owner,
				@CustomField1 = CustomField1,
				@CustomField2 = CustomField2,
				@CustomField3 = CustomField3,
				@CustomField4 = CustomField4,
				@CustomField5 = CustomField5,
				@CustomField6 = CustomField6,
				@CustomField7 = CustomField7,
				@CustomField8 = CustomField8,
				@CustomField9 = CustomField9,
				@CustomField10 = CustomField10,
				@TimeLastModified = LastModified,
				@TicketId = TicketId,
				@ConnectorId = ConnectorId,
				@TfsWorkItemId = TfsWorkItemId,
				@TfsWorkItemOwner = TfsWorkItemOwner
		FROM [OperationsManager].dbo.AlertView WHERE Id = (SELECT TOP 1 AlertId FROM deleted)

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

END
GO