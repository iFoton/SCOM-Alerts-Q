# SCOM Alerts Queue
## System Center Operations Manager Extention
Advanced Queue for SCOM Alerts Notifications. High-performance, scalable, customizable solution.
![alt tag](https://github.com/iFoton/SCOM-Alerts-Q/blob/master/img/hld.JPG)

# How it Works
## Management Server Part
![alt tag](https://github.com/iFoton/SCOM-Alerts-Q/blob/master/img/MS%20Part.JPG)
When SCOM raises an alert, subscription aimed at him runs a small VBS script and passes them 4 parameters:
Parameter | Description
--------- | -----------
`$Data/Context/DataItem/AlertId$` | Alert ID
`$MPElement$` | Subscription ID
`%computername%` | Hostname, for logging purposes 
0-255 | State that we have set for the alert after the process it
###### If you pass 0, then no any manipulation of the alert's state will not be made.
This script executes the SQL command, which adds an alert to Queue DB