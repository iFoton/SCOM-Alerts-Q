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
    #Write-Host $dataset -ForegroundColor Cyan
    $adapter.Fill($dataset) | Out-Null
    $dataset.Tables[0]
     
} 

$rootPath = "C:\Users\ivan\OneDrive\Документы\GDC\AlertsQ"
$conStr = 'Server=SQLSCOM\SCOM;Database=OperationsManager;Trusted_Connection=True;'
$from = 'vCloud@f.loc'
$smtp = 'iis.f.loc'

$subQuery = Get-Content "$rootPath\Subscription.sql"
$alertQuery = Get-Content "$rootPath\getAlert.sql"

$xmlStruct = Get-Content "$rootPath\alertInfo.xml"

#$subQuery = "select * from Alert where Alertid = 'SUBSCRIPTION_ID'"
$AlertsQ =  Get-DatabaseData -connectionString $conStr -query "SELECT * FROM dbo.SCOM_ALERTS_QUEUE ORDER BY TimeStmp"

foreach ($alert in $AlertsQ ){
    
    Write-Host $alert.AlertID -ForegroundColor Yellow

    #Create mail recipient dim
    $subQ = "$subQuery".Replace("SUBSCRIPTION_ID","$($alert.SubscriptionID)")
    $subscribers = Get-DatabaseData -connectionString $conStr -query $subQ
    $to = @()
    $subscribers | % {if($_.Devicename){$to += $_.Devicename}}

    #CREATE XML
    $alertQ = "$alertQuery".Replace("ALERT_ID","$($alert.AlertID)")
    $alertInfo =  Get-DatabaseData -connectionString $conStr -query $alertQ
    
    $xml = [xml]$xmlStruct

    foreach ($alertProp in ($alertInfo | Get-Member -MemberType Properties)) {
        
        $xml.Alert."$($alertProp.name)" = $alertInfo."$($alertProp.name)".tostring()
        #$alertProp.Name

    }
    
    #Fill Description
    $param = [xml]$alertInfo.AlertParams
    $paramCount = ($param.AlertParameters.ChildNodes).Count
        
    if ($paramCount -gt 0) {
        
        $desc = $xml.Alert.AlertStringDescription
        
        for ($i=0;$i -lt $paramCount;$i++) {
            $desc = $desc.Replace("{$i}","$($param.AlertParameters."AlertParameter$($i+1)")")
        }

        $xml.Alert.AlertStringDescription = $desc
    }

    $xml.Alert.RemoveChild($xml.SelectSingleNode('//Alert/AlertParams')) | Out-Null

    #Create HTML

    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xmlStrReader = New-Object System.IO.StringReader($xml.InnerXml)
    $xmlReader = [System.Xml.XmlReader]::Create($xmlStrReader)
    $htmlWriter = [System.IO.StringWriter]::new("")
    $xslt.Load("$rootPath\errorTemplate.xsl")
    
    $xslt.Transform($xmlReader,$null,$htmlWriter)

    #Send Mail
    $subj = 'Alert'
    $body = $htmlWriter.ToString() 
    Send-MailMessage -BodyAsHtml -From $from -To $to -Subject $subj -Body $body -SmtpServer $smtp -Encoding UTF8 -Verbose

    Invoke-DatabaseQuery `
     -connectionString $conStr `
     -query "DELETE FROM dbo.SCOM_ALERTS_QUEUE WHERE QID = '$($alert.QID)'" | Out-Null


    #pause

}












