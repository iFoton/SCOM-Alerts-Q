function Get-DatabaseData { 

    param ( 
        [string]$connectionString, 
        [string]$query
    ) 
    
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection 
    $connection.ConnectionString = $connectionString 
    $command = $connection.CreateCommand() 
    $command.CommandText = $query 
    $adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command 
    $dataset = New-Object -TypeName System.Data.DataSet 
    $adapter.Fill($dataset) | Out-Null
    $dataset.Tables[0]
     
} 
$conStr ="Server=SMVSQLCLP01\scom_db;Database=SCOMAddons;Trusted_Connection=True;"
$subQ = "SELECT TOP 200 
`"Alert Name`",
Severity,
Subscription,
Description,
FORMAT(SWITCHOFFSET(CONVERT(datetimeoffset,TimeStmp),'+02:00'), 'd MMMM HH:mm:ss', 'en-US') AS 'Time'
 FROM [SCOMAddons].[dbo].[AlertsQueueHistoryView] ORDER BY TimeStmp DESC"
$history = Get-DatabaseData -connectionString $conStr -query $subQ
$id = 1000
foreach ($alert in $history) {

$dataObj = $ScriptContext.CreateInstance("xsd://foo!bar/baz")
$dataObj["Id"]           = [String]($id)
$dataObj["Name"]         = [String]($alert."Alert Name")
$dataObj["Severity"]     = [String]($alert.Severity)
$dataObj["Subscription"] = [String]($alert.Subscription)
$dataObj["Description"]  = [String]($alert.Description)
$dataObj["Time"]         = [String]($alert.time)
$ScriptContext.ReturnCollection.Add($dataObj)
$id++

}
