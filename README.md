# SCOM Alerts Queue
## System Center Operations Manager Extention
Advanced Queue for SCOM Alerts Notifications. High-performance, scalable, customizable solution.
![alt tag](https://github.com/iFoton/SCOM-Alerts-Q/blob/master/img/hld.JPG)

# How it Works
## 1. Management Server Part
![alt tag](https://github.com/iFoton/SCOM-Alerts-Q/blob/master/img/MS%20Part.JPG)

When SCOM raises an alert, subscription aimed at him runs a small VBS script and passes them 4 parameters:

Parameter | Description
--------- | -----------
`$Data/Context/DataItem/AlertId$` | Alert ID
`$MPElement$` | Subscription ID
`%computername%` | Hostname, for logging purposes 
0-255 | State that we have set for the alert after the process it

###### If you pass 0, then no any manipulation of the alert's state will not be made.
This script executes the SQL command, which adds an alert to the Queue DB.

## 2. SQL Part
![alt tag](https://github.com/iFoton/SCOM-Alerts-Q/blob/master/img/SQL-Part.JPG)

SQL Part implemented as separeted database with few tables, triggers and views.

Type | Name | Description
---- | ---- | -----------
Table | AlertsQueue | Contains alerts added to the Queue
Table | AlertsQueueHistory | Contains history of prosessed alerts
Trigger | AddToQTrigger | Check conditions before add an alert to the Queue
Trigger | RemoveFromQTrigger | Triggered when you remove an alert from the Queue
View | AlertsQueueView | Provides information about alerts in the Queue
View | SubscriptionsView | Provides information about subscriptions and subscribers
View | AlertsQueueHistoryView | Provides information about prosessed alerts

When you try to add an alert in the Queue, the trigger `AddToQTrigger` checks several conditions:

1. Alert exsist in SCOM DB Alert View.
2. Gates availability. If this 'Failed to Connect to Computer' or 'Health Service Heartbeat Failure' alert and gateway server has n/a state alert will be rejected.
3. Closed alerts will be added to the Queue only if they was sended before.

###### For rejected alerts will be set ignored state in SCOM database. For alerts with states New (0) and Closed (255) the status update never made.

When you remove an alert from the Queue, the trigger `RemoveFromQTrigger` makes follows actions:

1. If current alert's state is New (0) and target state not New (0) then update alert's state and also fill in custom fields by additional information:
    * Alert ID
    * Category
    * Monitor/Rule name
    * Management Pack name
    * Object name
    * Full name
    * Object ID
    * Subscription name
    * Time of adding to the Queue
    * Time of sending
2. Write history.

###### Update alert's status is performed using a stored procedure `p_AlertUpdate` from the SCOM database.

## 3. Queue Handler Part

Queue Handler Part implemented as scheduled PowerShell script that runs every X minutes.

1. Gets alerts from `AlertsQueueView`.
2. Gets subscription info from `SubscriptionsView`.
3. Generates html report for each.
4. Sends they by e-mail to subscribers.
5. Removes alerts from the Queue.

### Report Examples

![alt tag](https://github.com/iFoton/SCOM-Alerts-Q/blob/master/img/ReportExamples.JPG)

###### Reports generates from XML by XSLT template. You can modify template to your liking.