
    ##Parametros de Conexión

    $connectionName = "AzureRunAsConnection"



    ##Parametros para dar formato del output (Año-Mes-Dia-Minuto)

    $StartTime = Get-Date

    $FileName = ($StartTime).ToString("yyyy-MM-dd-HH-mm") + ".csv"



    #Parametros para conexión y exportación a StorageAccount

    $StorageAccountName = "activitylogs3"

    $StorageContainerName = "joboutput"

    $localFolder = "c:\LogAudit\KV\$FileName" 



    

##Función de conexión al Tenant mediante Hybrid Worker

function LogIn-API{ 

try{

    

    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         



    "Haciendo Log In en Azure"

    Add-AzureRmAccount `

        -ServicePrincipal `

        -TenantId $servicePrincipalConnection.TenantId `

        -ApplicationId $servicePrincipalConnection.ApplicationId `

        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

}

catch {

    if (!$servicePrincipalConnection)

    {

        $ErrorMessage = "Conexión $connectionName no existe."

        throw $ErrorMessage

    } else{

        Write-Error -Message $_.Exception

        throw $_.Exception

    }

}

                }





##Función Main del script que se encarga de revisar si los Logs están o no activados y los exporta al HybridWorker

function KV-LogAudit {$KVLogs = @($KVs= Get-AzureRmKeyVault | Select-Object VaultName,ResourceGroupName,ResourceID



foreach ($KV in $KVs){



    $Name=$KV.vaultname

    $ID=$KV.resourceid

    $RG=$KV.ResourceGroupName



    $enabled = Get-AzureRmDiagnosticSetting -ResourceId $ID -WarningAction SilentlyContinue | Select-Object StorageAccountID -ExpandProperty Logs | Select-Object Enabled

    $on = $enabled.Enabled

    $storageacc = $enabled.storageccountid 

                

               

    If($on -eq "True")

        {



            if($storageacc -ne "$null")

                                {

                                $retention = Get-AzureRmDiagnosticSetting -ResourceId $ID -WarningAction SilentlyContinue | Select-Object StorageAccountID,WorkspaceId -ExpandProperty Logs | Select-Object StorageAccountID,WorkspaceId -ExpandProperty RetentionPolicy | Select-Object Enabled,Days,StorageAccountID,WorkspaceId

                                $days=$retention.days

                                Get-AzureRmDiagnosticSetting -ResourceId $ID -WarningAction SilentlyContinue | Select-Object StorageAccountId,EventHubName,WorkspaceId -ExpandProperty Logs | Select-Object  @{Label="KV Name";Expression={($Name)}},@{Label="Resource Group";Expression={($RG)}},@{Label="Monitorizado";Expression={("Sí")}},@{Label="Logs Faltantes";Expression={("Ninguno")}},StorageAccountId,EventHubName,WorkspaceId,@{Label="Retention Policy";Expression={("Activada")}},@{Label="Tiempo de retención: AuditEvent";Expression={("$days")}}

                                }

            else

                                {

                                Get-AzureRmDiagnosticSetting -ResourceId $ID -WarningAction SilentlyContinue | Select-Object StorageAccountId,EventHubName,WorkspaceId -ExpandProperty Logs | Select-Object  @{Label="KV Name";Expression={($Name)}},@{Label="Resource Group";Expression={($RG)}},@{Label="Monitorizado";Expression={("Sí")}},@{Label="Logs Faltantes";Expression={("Ninguno")}},StorageAccountId,EventHubName,WorkspaceId,@{Label="Retention Policy";Expression={("$null")}},@{Label="Tiempo de retención: AuditEvent";Expression={("$null")}}

                                }

        }

    Else

        {

        Get-AzureRmKeyVault -VaultName $Name | Select-Object VaultName,ResourceGroupName,ResourceID | Select-Object @{Label="KV Name";Expression={($Name)}},@{Label="Resource Group";Expression={($RG)}},@{Label="Monitorizado";Expression={("No")}},@{Label="Monitorización Faltante";Expression={("StorageAccount,OMS")}},@{Label="Logs Faltantes";Expression={("AuditEvent")}},StorageAccountId,EventHubName,WorkspaceId,@{Label="Retention Policy";Expression={("$null")}},@{Label="Tiempo de retención: AuditEvent";Expression={("$null")}}

        }

                     } ) | Export-Csv -Encoding UTF8 -NoTypeInformation -Path "C:/LogAudit/KV/$FileName"}





##Conexión y Exportación de Logs al Storage mediante la API creada

function KV-ExportStorage{



    $blobProperties = @{"ContentType" = "text/plain"}



    $storageAccountKey = (Get-AzureRMStorageAccountKey -ResourceGroupName Storage -AccountName  $StorageAccountName).Value[0]



  

    $azureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName  -StorageAccountKey $storageAccountKey



         

                Set-AzureStorageBlobContent -File $localFolder                                                                  `

									        -Container $StorageContainerName                                              `

									        -Properties $blobProperties                                                   `

									        -Context $azureStorageContext                                                       `

									        -Blob "KV/$FileName"                                                                          `

                                            -Force                                                                              `

    									    -Verbose   

                   }      

                   

          

          LogIn-API

          KV-LogAudit

          KV-ExportStorage   
