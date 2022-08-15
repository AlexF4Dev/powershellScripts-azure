<#
# example script to query service fabric api on localhost using self signed cert
# docs.microsoft.com/en-us/rest/api/servicefabric/sfclient-index

[net.servicePointManager]::Expect100Continue = $true;[net.servicePointManager]::SecurityProtocol = [net.SecurityProtocolType]::Tls12;
invoke-webRequest "https://raw.githubusercontent.com/jagilber/powershellScripts/master/serviceFabric/sf-rest-api.ps1" -outFile "$pwd/sf-rest-api.ps1";
./sf-rest-api.ps1

#>
param(
    $gatewayHost = "https://localhost:19080",
    $gatewayCertThumb = "xxxxx",
    $startTime = (get-date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ"),
    $endTime = (get-date).ToString("yyyy-MM-ddTHH:mm:ssZ"),
    $timeoutSec = 100,
    $apiVer = "6.2-preview",
    [ValidateSet('CurrentUser', 'LocalMachine')]
    $store = 'CurrentUser',
    $certificatePath = '',
    $certificatePassword = ''
)

Clear-Host
$ErrorActionPreference = "continue"

function main() {
    $result = $Null
    set-callback
    $error.Clear()

    if ($certificatePath -and (test-path $certificatePath)) {
        $cert = [security.cryptography.x509Certificates.x509Certificate2]::new($pfxFile, $certificatePassword);
    }
    else {
        $cert = Get-ChildItem -Path cert:\$store -Recurse | Where-Object Thumbprint -eq $gatewayCertThumb
    }

    $eventArgs = "api-version=$($apiVer)&timeout=$($timeoutSec)&StartTimeUtc=$($startTime)&EndTimeUtc=$($endTime)"

    $url = "$($gatewayHost)/EventsStore/Cluster/Events?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result = call-rest -url $url -cert $cert
    $result | Format-List *
    $result = $Null


    $url = "$($gatewayHost)/EventsStore/Nodes/Events?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result | Format-List *
    $result = $Null


    $url = "$($gatewayHost)/EventsStore/Applications/Events?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result | Format-List *
    $result = $Null


    $url = "$($gatewayHost)/EventsStore/Services/Events?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result | Format-List *
    $result = $Null


    $url = "$($gatewayHost)/EventsStore/Partitions/Events?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result | Format-List *
    $result = $Null

    $eventArgs = "api-version=$($apiVer)&timeout=$($timeoutSec)"
    $url = "$($gatewayHost)/ImageStore?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result | Format-List *
    $result.StoreFiles
    $result.StoreFolders
    $result = $Null

    $url = "$($gatewayHost)/$/GetClusterManifest?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    #$result |fl *
    $result.manifest
    $result = $Null

    $url = "$($gatewayHost)/$/GetClusterHealth?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result | Format-List *
    $result = $Null

    $url = "$($gatewayHost)/Nodes?$($eventArgs)"
    $result = call-rest -url $url -cert $cert
    $result.items | Format-List *
}

function call-rest($url, $cert) {
    if ($PSVersionTable.PSEdition -ieq 'core') {
        write-host "Invoke-RestMethod -Uri $url -TimeoutSec 30 -UseBasicParsing -Method Get -Certificate $($cert.thumbprint) -SkipCertificateCheck -SkipHttpErrorCheck" -ForegroundColor Cyan
        return Invoke-RestMethod -Uri $url -TimeoutSec 30 -UseBasicParsing -Method Get -Certificate $cert -SkipCertificateCheck -SkipHttpErrorCheck
    }
    else {
        write-host "Invoke-RestMethod -Uri $url -TimeoutSec 30 -UseBasicParsing -Method Get -Certificate $($cert.thumbprint)" -ForegroundColor Cyan
        return Invoke-RestMethod -Uri $url -TimeoutSec 30 -UseBasicParsing -Method Get -Certificate $cert        
    }
}

function set-callback() {

    if ($PSVersionTable.PSEdition -ieq 'core') {
        # not working but -skipcertificatecheck works
        class SecurityCallback {
            [bool] ValidationCallback(
                [object]$senderObject, 
                [System.Security.Cryptography.X509Certificates.X509Certificate]$cert, 
                [System.Security.Cryptography.X509Certificates.X509Chain]$chain, 
                [System.Net.Security.SslPolicyErrors]$policyErrors
            ) {
                write-host "validation callback:sender:$($senderObject | out-string)" -ForegroundColor Cyan
                write-verbose "validation callback:sender:$($senderObject | convertto-json)"
        
                write-host "validation callback:cert:$($cert | Format-List * |out-string)" -ForegroundColor Cyan
                write-verbose  "validation callback:cert:$($cert | convertto-json)"
        
                write-host "validation callback:chain:$($chain | Format-List * |out-string)" -ForegroundColor Cyan
                write-verbose  "validation callback:chain:$($chain | convertto-json)"
        
                write-host "validation callback:errors:$($policyErrors | out-string)" -ForegroundColor Cyan
                write-verbose  "validation callback:errors:$($policyErrors | convertto-json)"
                return $true
            }
            [System.Security.Cryptography.X509Certificates.X509Certificate] LocalCallback(
                [object]$senderObject, 
                [string]$targetHost,
                [System.Security.Cryptography.X509Certificates.X509CertificateCollection]$certCol, 
                [System.Security.Cryptography.X509Certificates.X509Certificate]$remoteCert, 
                [string[]]$issuers
            ) {
                write-host "validation callback:sender:$($senderObject | out-string)" -ForegroundColor Cyan
                write-verbose "validation callback:sender:$($senderObject | convertto-json)"
        
                write-host "validation callback:targethost:$($targetHost | out-string)" -ForegroundColor Cyan
                write-verbose "validation callback:targethost:$($targetHost | convertto-json)"

                write-host "validation callback:certCol:$($certCol | Format-List * |out-string)" -ForegroundColor Cyan
                write-verbose  "validation callback:certCol:$($certCol | convertto-json)"
        
                write-host "validation callback:remotecert:$($remoteCert | Format-List * |out-string)" -ForegroundColor Cyan
                write-verbose  "validation callback:remotecert:$($remoteCert | convertto-json)"
        
                write-host "validation callback:issuers:$($issuers | out-string)" -ForegroundColor Cyan
                write-verbose  "validation callback:issuers:$($issuers | convertto-json)"
                return $remoteCert
            }
        }

        [SecurityCallback]$global:securityCallback = [SecurityCallback]::new()
        [net.servicePointManager]::ServerCertificateValidationCallback = [System.Net.Security.RemoteCertificateValidationCallback]($global:securityCallback.ValidationCallback)
    }
    else {
        add-type @"
        using System;
        using System.Net;
        using System.Security.Cryptography.X509Certificates;

        public class IDontCarePolicy : ICertificatePolicy {
                public IDontCarePolicy() {}
                public bool CheckValidationResult(ServicePoint sPoint, X509Certificate cert, WebRequest wRequest, int certProb) {
                Console.WriteLine(cert);
                Console.WriteLine(cert.Issuer);
                Console.WriteLine(cert.Subject);
                Console.WriteLine(cert.GetCertHashString());
                return true;
            }
        }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy 
    }
}

main