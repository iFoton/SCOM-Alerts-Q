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

$conStr ="Server=SQLSCOM\SCOM;Database=SCOMAddons;Trusted_Connection=True;"
$subQ = "SELECT TOP 100 * FROM [SCOMAddons].[dbo].[AlertsQueueHistoryView] ORDER BY Time DESC"
$history = Get-DatabaseData -connectionString $conStr -query $subQ
$id = 1000

foreach ($alert in ($history | Sort-Object -Property TimeStmp -Descending)) {

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
