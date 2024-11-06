$datetime=Get-Date -format "MMddyyyy-HHmmss"
$filePath = "E:\Scripts\checkSSLExpiry"
$inputFile = "$filePath\hostsList.csv"
$outputFile = "$filePath\certificate_status-$datetime.csv"

$minCertAge = 10
$timeoutMs = 10000
$sites = Import-Csv -Path $inputFile

# Disable certificate validation
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$results = @()
foreach ($site in $sites) {

    Write-Host "Check $($site.HostName)" -ForegroundColor Green
    $fqdn="https://$($site.HostName)"
    
    $req = [Net.HttpWebRequest]::Create($fqdn)
    $req.Timeout = $timeoutMs
    try {

        $req.GetResponse() | Out-Null

    }
    catch {
        Write-Host "URL check error $($site.HostName)`: $_" -ForegroundColor Red
        continue
    }
    $expDate = $req.ServicePoint.Certificate.GetExpirationDateString()
    
    #Write-Host $expDate
`
    $certExpDate = Get-Date -Date $expDate;
    $currDate = Get-Date

    $certExpiresIn = ($certExpDate - $currDate).Days
    
    #[int]$certExpiresIn = ($expDate - $(Get-Date)).Days
    $certName = $req.ServicePoint.Certificate.GetName()
    $certThumbprint = $req.ServicePoint.Certificate.GetCertHashString()
    $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
    $certIssuer = $req.ServicePoint.Certificate.GetIssuerName()
    if ($certExpiresIn -gt $minCertAge) {
       Write-Host "The $($site.hostname) certificate expires in $certExpiresIn days [$certExpDate]" -ForegroundColor Green
    }
    else {
        $message = "The $($site.hostname) certificate expires in $certExpiresIn days"
        $messageTitle = "Renew certificate"
        Write-Host $message [$certExpDate]. Details:`n`nCert name: $certName`Cert thumbprint: $certThumbprint`nCert effective date: $certEffectiveDate`nCert issuer: $certIssuer -ForegroundColor Red
        # Displays a pop-up notification and sends an email to the administrator
        # ShowNotification $messageTitle $message
        # Send-MailMessage -From powershell@woshub.com -To admin@woshub.com -Subject $messageTitle -Body $message -SmtpServer gwsmtp.woshub.com -Encoding UTF8
    }
    $result = [PSCustomObject]@{
        Site = $site.HostName
        ExpiresInDays = $certExpiresIn
        #ExpirationDate = $certExpDate
        ExpirationDate = $expDate
        Name = $certName
        Thumbprint = $certThumbprint
        EffectiveDate = $certEffectiveDate
        Issuer = $certIssuer
    }
    $results += $result
    }
$results | Export-Csv -Path $outputFile -NoTypeInformation
