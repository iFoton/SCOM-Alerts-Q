USE OperationsManager
GO
CREATE VIEW dbo.SubscriptionsView  
AS
SELECT ID AS 'SubscriptionID', DisplayName AS 'SubscriptionName',
    (SELECT LEFT(DeviceName, LEN(DeviceName) - 1)
     FROM (SELECT        Subscribers.DeviceName + '; '
           FROM   (SELECT 
                   r.SubscriberId,
                   D .C.value('Name[1]', 'varchar(4000)') DeviceName
                   FROM (SELECT 
                                N .C.value('RecipientId[1]', 'varchar(4000)') SubscriberId,
                                N .C.query('.') AS xmlquery
                         FROM (SELECT cast(MDTImplementationXML AS xml) Recxml
                               FROM [dbo].[ModuleType] mt
                               WHERE MDTName = 'Microsoft.SystemCenter.Notification.Recipients') a CROSS Apply Recxml.nodes('//Recipient') N (C)) r CROSS 
                                     Apply xmlquery.nodes('//Device') D (C))
                   Subscribers JOIN
                        (SELECT r.RuleId, R.DisplayName, D .C.value('RecipientId[1]', 'varchar(4000)') SubscriberId
                         FROM (SELECT RuleId, r.DisplayName, cast(RuleModuleConfiguration AS XML) xmlquery
                               FROM RuleModule rm JOIN 
                                    RuleView r ON rm.RuleId = r.Id
                               WHERE r.Category = 'Notification' AND RuleModuleName = 'CD1') r CROSS Apply xmlquery.nodes('//DirectoryReference') D (C))
                   Subscriptions ON 
                   Subscribers.SubscriberId = Subscriptions.SubscriberId
    WHERE Subscriptions.RuleId = RUL.Id FOR XML PATH('')) c(DeviceName)) AS 'Subscribers'
FROM RuleView RUL
WHERE Category = 'Notification'