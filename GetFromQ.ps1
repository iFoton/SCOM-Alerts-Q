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

function Invoke-DatabaseQuery { 
    param ( 
        [string]$connectionString, 
        [string]$query     
    ) 
    
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection 
    $connection.ConnectionString = $connectionString 
    $command = $connection.CreateCommand()
    $command.CommandText = $query 
    $connection.Open() 
    $command.ExecuteNonQuery() 
    $connection.close() 
}

function fnMamlToHTML
{
    param ($MAMLText) 
	$HTMLText = "";
	$HTMLText = $MAMLText -replace ('xmlns:maml="http://schemas.microsoft.com/maml/2004/10"');
	$HTMLText = $HTMLText -replace ("maml:para", "p");
	$HTMLText = $HTMLText -replace ("maml:");
	$HTMLText = $HTMLText -replace ("</section>");
	$HTMLText = $HTMLText -replace ("<section>");
	$HTMLText = $HTMLText -replace ("<section >");
	$HTMLText = $HTMLText -replace ("<title>", "<h3>");
	$HTMLText = $HTMLText -replace ("</title>", "</h3>");
	$HTMLText = $HTMLText -replace ("<listitem>", "<li>");
	$HTMLText = $HTMLText -replace ("</listitem>", "</li>");
    $HTMLText = $HTMLText -replace ("</MamlContent>", "");
    $HTMLText = $HTMLText -replace ("<MamlContent>", "");
	$HTMLText;
}

function Get-HTML {
    param ( 
        $alertInfo,
        $subscribers, 
        $xslt    
    ) 

    #Prepare subscribers info
    $subScr = ""
    $subscribers | % {
        if(($_.Devicename) -and ($subScr -notlike "*$($_.Devicename)*")) {
            $subScr += $_.DeviceName + "; "
        }
    }
    $alertInfo.Subscription = $subscribers.DisplayName[0]
    $alertInfo.Subscribers = $subScr

    #Create XML
    $xml.LoadXml("<?xml version=`"1.0`" encoding=`"utf-8`"?><Alert></Alert>")
    $xmlA = $xml.SelectSingleNode("//Alert")
    
    #Fill XML
    foreach ($alertProp in ($alertInfo.psobject.properties | select -ExpandProperty Name | ? {$_ -notin ('RowError','RowState','Table','ItemArray','HasErrors')})) {
        
        $node = $xml.CreateElement("$alertProp")
        $xmlAtt = $xml.CreateAttribute("Name")
        $xmlAtt.Value  = "$alertProp".replace("_"," ")
        $node.Attributes.Append($xmlAtt) | Out-Null
        $xmlA.AppendChild($node) | Out-Null
        $xmlA."$alertProp".InnerText = $alertInfo."$alertProp".tostring()

    }
    
    #Fill Description
    $param = [xml]$alertInfo.AlertParams
    $paramCount = ($param.AlertParameters.ChildNodes).Count
        
    if ($paramCount -gt 0) {
        
        $desc = $xml.Alert.Alert_Description.InnerText
        
        for ($i=0;$i -lt $paramCount;$i++) {
            $desc = $desc.Replace("{$i}","$($param.AlertParameters."AlertParameter$($i+1)")")
        }

        $xml.Alert.Alert_Description.InnerText = $desc
    }
    
    $xml.Alert.RemoveChild($xml.SelectSingleNode('//Alert/AlertParams')) | Out-Null
    
    #Fill Resolution State
    $xml.Alert.Resolution_State.InnerText = $xml.Alert.ResolutionStateName.InnerText + " (" +$xml.Alert.Resolution_State.InnerText + ")"
    $xml.Alert.RemoveChild($xml.SelectSingleNode('//Alert/ResolutionStateName')) | Out-Null

    #Fill Knowledge
    if ($xml.Alert.Knowledge.InnerText) {
        $Knowledge = fnMamlToHTML $xml.Alert.Knowledge.InnerText
        $xml.Alert.Knowledge.InnerText = 'Knowledge_replace'
    } else {
        $xml.Alert.RemoveChild($xml.SelectSingleNode('//Alert/Knowledge')) | Out-Null
    }
    
    #Fill Sevrity
    switch ($xml.Alert.Severity.InnerText) {
    
        (0) {$xml.Alert.Severity.InnerText = "Information"}
        (1) {$xml.Alert.Severity.InnerText = "Warning"}
        (2) {$xml.Alert.Severity.InnerText = "Critical"}

    }
    
    #Create HTML    
    $xmlStrReader = New-Object System.IO.StringReader($xml.InnerXml)
    $xmlReader    = [System.Xml.XmlReader]::Create($xmlStrReader)
    $htmlWriter   = New-Object System.IO.StringWriter("")
        
    $xslt.Transform($xmlReader,$null,$htmlWriter)
    $html = $htmlWriter.ToString().Replace('Knowledge_replace',$Knowledge)

    Return $html

}

if ($PSscriptRoot) {
    $rootPath = $PSscriptRoot    
} else {
    $rootPath = "C:\Users\ivan\OneDrive\Документы\GDC\AlertsQ"
    }

#Prepare Objects and Query
$confXml = [xml](Get-Content (Join-Path $rootPath "Config.xml")) 
$conStr  = $confXml.Settings.Sender.SQLConnectionString
$from    = $confXml.Settings.Sender.FromAddress
$smtp    = $confXml.Settings.Sender.SMTPServerAddress

$subQuery   = Get-Content "$rootPath\getSubscription.sql"
$alertQuery = Get-Content "$rootPath\getAlert.sql"

$xml  = New-Object system.Xml.XmlDocument
$xslt = New-Object System.Xml.Xsl.XslCompiledTransform
$xslt.Load("$rootPath\template.xsl")

#Get alerts from Queue
$AlertsQ =  Get-DatabaseData -connectionString $conStr -query "SELECT TOP 100 * FROM dbo.SCOM_ALERTS_QUEUE ORDER BY TimeStmp"

foreach ($alert in $AlertsQ ){
    
    Write-Host $alert.AlertID -ForegroundColor Yellow

    #Create mail recipient dim
    $subQ = "$subQuery".Replace("SUBSCRIPTION_ID","$($alert.SubscriptionID)")
    $subscribers = Get-DatabaseData -connectionString $conStr -query $subQ
    $to = @()
    $subscribers | % {if($_.Devicename){$to += $_.Devicename}}

    #Get Alert Info
    $alertQ = "$alertQuery".Replace("ALERT_ID","$($alert.AlertID)")
    $alertInfo =  Get-DatabaseData -connectionString $conStr -query $alertQ
        
    #Fill subject
    $subj = $alertInfo.ResolutionStateName + ", Severity: "
    switch ($alertInfo.Severity) {
    
        (0) {$subj += "Information, "}
        (1) {$subj += "Warning, "}
        (2) {$subj += "Critical, "}

    }
    $subj += $alertInfo.MonitoringObjectFullName + ", " + $alertInfo.Alert_Name
    
    #Fill body           
    $body = Get-HTML $alertInfo $subscribers $xslt

    #Send Mail
    Send-MailMessage -BodyAsHtml -From $from -To $to -Subject $subj -Body $body -SmtpServer $smtp -Encoding UTF8 -Verbose

    #Write history
    $Description = "Sended"
    $sendQ = "INSERT INTO dbo.SCOM_ALERTS_QUEUE_HISTORY (AlertID,AlertName,SubscriptionID,SubscriptionName,Description,Severity)
            VALUES ('$($alert.AlertID)',
                    '$($alertInfo.Alert_Name)',
                    '$($alert.SubscriptionID)',
                    '$($subscribers.DisplayName[0])',
                    '$Description', 
                     $($alertInfo.Severity))"

    Invoke-DatabaseQuery `
         -connectionString $conStr `
         -query $sendQ | Out-Null
    
    #Remove alert from Q
    #Invoke-DatabaseQuery `
    # -connectionString $conStr `
    # -query "DELETE FROM dbo.SCOM_ALERTS_QUEUE WHERE QID = '$($alert.QID)'" | Out-Null

    pause

}












