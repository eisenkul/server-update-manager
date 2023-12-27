<#

Ersin Isenkul
ersinisenkul@gmail.com

Version 1.0, Dec 25th, 2023

.Synopsis
   This PowerShell script is designed to manage server updates and services on a list of servers.
.DESCRIPTION
   The script provides a menu-driven interface for administrators to perform various tasks, including checking for updates,
   installing updates, viewing update status, managing services and restarting server on specific servers or all servers in the list.
   Servers in the list can be viewed, deleted or new servers can be added to the list.
.EXAMPLE
   Example of how to use this script:    
   1. Run the script.
   2. Enter the server list at the first run.
   2. Choose an action from the menu.    
   3. Provide admin credentials when prompted.    
   4. Perform the selected action on the specified servers.
.INPUTS
   You must enter the server list at the first use. (Server01;Server02;Server03...)
   You can input servers to this server list if you want.
   The script prompts the user for admin credentials when necessary.
.OUTPUTS
    The script provides status messages and information about updates and services on the specified servers.
.NOTES
    This script relies on PowerShell remoting to perform actions on remote servers. 
    Ensure that remoting is enabled and that the executing user has the necessary permissions.
.COMPONENT
    Server Management
.ROLE
    Administrator
.FUNCTIONALITY
    - Checking for available updates on servers.
    - Installing updates on servers.
    - Viewing update status on servers.
    - Retrieving and restarting services with stopped status and automatic start type on servers.
    - Restarting servers from the list.
    - Providing an interactive menu for users to choose and perform actions on servers.
#>

$ErrorActionPreference = "SilentlyContinue"

function New-ServerList{
    
    Clear-Host
    $Global:filePath = ".\serverlist.txt"

    if ((Get-Content -Path $Global:filePath -Raw) -eq $null) {
    Write-Host "serverlist.txt is empty or doesn't exist. Running the script to generate it."

    $prompt = @(
        'List the server you want information for.',
        'When specifying multiple servers, separate them with a semicolon, like:',
        "'Server01;Server02;Server03'"
    ) -join ' '

    $ServerList = Read-Host $prompt

    if (-not $ServerList.Trim()) {
        Write-Host "No servers provided. Exiting." -ForegroundColor Red
        Exit
    }

    $splitServers = $ServerList -split ';'
    $normalizedServers = $splitServers | ForEach-Object { $_.Trim() }

    $normalizedServers | Out-File -FilePath $Global:filePath

    Write-Host "Server list saved to $Global:filePath" -ForegroundColor Green
    }
}

function Get-ServerList{

    $Global:filePath = ".\serverlist.txt"

    if ((Get-Content -Path $Global:filePath -Raw) -eq $null) {
    Write-Host "serverlist.txt is empty or doesn't exist. You need to create new list."

    $prompt = @(
        'List the server you want information for.',
        'When specifying multiple servers, separate them with a semicolon, like:',
        "'Server01, Server02, Server03'"
    ) -join ' ' 

    $ServerList = Read-Host $prompt 

    if (-not $ServerList.Trim()) {
        Write-Host "No servers provided. Exiting." -ForegroundColor Red
        Exit
    }

    $splitServers = $ServerList -split ';'
    $normalizedServers = $splitServers | ForEach-Object { $_.Trim() }

    $normalizedServers  | Out-File -FilePath $Global:filePath

    Write-Host "Server list saved to $Global:filePath" -ForegroundColor Green
}

    $Servers = Get-Content -Path $Global:filePath
    Write-Host "Server List:" -ForegroundColor Cyan
    Write-Host ($Servers -join "`n") -ForegroundColor Cyan


}

function Add-ServertoList {

    $Global:filePath = ".\serverlist.txt"

    if (Test-Path -Path $Global:filePath) {
        $Global:filePath = ".\serverlist.txt"
    
        $prompt = @(
            'Add the server to list',
            'When specifying multiple servers, separate them with a semicolon, like:',
            "Server01; Server02; Server03"
            ) -join ' '

        $NewServerList = Read-Host $prompt 

    $NewsplitServers = $NewServerList -split ';'
    $NewnormalizedServers = $NewsplitServers | ForEach-Object { $_.Trim() }

    $NewnormalizedServers | %{Add-Content -Path $Global:filePath -Value $_ }


    Write-Host "Added new server to the list. Server list saved to $Global:filePath" -ForegroundColor Green

    $Servers = Get-Content -Path $Global:filePath
    Write-Host "Server List:" -ForegroundColor Cyan
    Write-Host ($Servers -join "`n") -ForegroundColor Cyan

    } else {
        New-ServerList
    }
}

function Remove-ServerList {

    $Global:filePath = ".\serverlist.txt"

    if (Test-Path -Path $Global:filePath) {
        Remove-Item -Path $Global:filePath -Force
        Write-Host "Server list removed successfully." -ForegroundColor Green
    } else {
        Write-Host "Server list does not exist." -ForegroundColor Yellow
    }
}

function Get-AdminCredentials {
    
    Write-Host "Enter Admin Username: " -ForegroundColor Cyan
    $AdminUsername = Read-Host 
    
    Write-Host "Enter Admin Password: " -ForegroundColor Cyan
    $AdminPassword = Read-Host -AsSecureString

    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AdminUsername, $AdminPassword

    return $Credential 
        
}


function Install-ServerUpdates {

    param (
        [string]$ServerName,
        [System.Management.Automation.PSCredential]$Credential
    )
 
    $Updates = Get-WmiObject -Namespace "root\ccm\clientSDK" -ComputerName $ServerName -Credential $Credential -Class CCM_SoftwareUpdate | Where-Object {
        $_.EvaluationState -like "*$AppEvalState*" -and $_.Name -like "*$SupName*"
    }

    $ErrorReason = $Error[0].CategoryInfo.Reason

    if ($Updates -ne $null) {

        $UpdateResults = Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList @($Updates) -Namespace root\ccm\clientsdk -ComputerName $ServerName -Credential $Credential
 
        if ($UpdateResults.ReturnValue -eq 0) {

            Write-Host "Installing updates on $ServerName." -ForegroundColor Green

        } else {

            Write-Host "Failed to install updates on $ServerName. Return Code: $($UpdateResults.ReturnValue)" -ForegroundColor Red

        }
    } elseif (($ErrorReason -eq "UnauthorizedAccessException") -or ($ErrorReason -eq "COMException")) {

        Write-Host "$ServerName : You do not have permission to access the server." -ForegroundColor Red
        $Error.Clear()

      }
       else {
        Write-Host "No updates found on $ServerName." -ForegroundColor DarkGray
    }
}

function Get-ServerUpdateStatus {
    
    param (
        [string]$ServerName,
        [System.Management.Automation.PSCredential]$Credential
    )

    $Updates = Get-WmiObject -Namespace "root\ccm\clientSDK" -ComputerName $ServerName -Credential $Credential -Class CCM_SoftwareUpdate | Where-Object {
        $_.EvaluationState -like "*$AppEvalState*" -and $_.Name -like "*$SupName*"
    }
    
    $ErrorReason = $Error[0].CategoryInfo.Reason

    if ($Updates -ne $null) {
        Write-Host "Update Status for $ServerName :" -ForegroundColor Cyan
        $Updates | ForEach-Object {
            $updateStatus = @{
                0  = "Available"
                5  = "Downloading"
                6  = "Waiting to Install"
                7  = "Installing"
                8  = "Requires Restart"
                11 = "Pending Verification"
                13 = "Install Failed"
            }

            $status = $updateStatus[[int]$_.EvaluationState]
            Write-Host "$($_.Name): " -ForegroundColor Yellow -NoNewline
            Write-Host $status -ForegroundColor White

        }
        
    } elseif (($ErrorReason -eq "UnauthorizedAccessException") -or ($ErrorReason -eq "COMException")) {

        Write-Host "$ServerName : You do not have permission to access the server." -ForegroundColor Red
        $Error.Clear()
      }
       else {
        Write-Host "No updates found on $ServerName." -ForegroundColor DarkGray
    }
}

function Get-ServicesSpecificServer {

    param (
        [System.Management.Automation.PSCredential]$Credential
    )
 
    $ServiceServerListMenu = {
        $script:i = 1
        Write-Host "Server List" -ForegroundColor Cyan
        foreach ($Server in $Servers) {
            Write-Host "$script:i - $Server" -ForegroundColor Cyan
            $script:i++
        }

        Write-Host "Select a number to view services for a specific server: " -NoNewline

    }
    Invoke-Command -ScriptBlock $ServiceServerListMenu
    $ChoiceServiceServerList = Read-Host
    $ChoiceServiceServerList = [int]$ChoiceServiceServerList
 
    if ($ChoiceServiceServerList -ge 1 -and $ChoiceServiceServerList -le $Servers.Count) {
        
        $SelectedServer = $Servers.Split()[$ChoiceServiceServerList-1]

        $services = Invoke-Command -ComputerName $SelectedServer -Credential $Credential -ScriptBlock {
            Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }
        }

        $ErrorReason = $Error[0].CategoryInfo.Reason
 
        if ($services.Count -gt 0) {
            Write-Host "Services on $SelectedServer with Stopped status and Automatic start type:" -ForegroundColor Cyan
            $services | Format-Table -AutoSize -Property Status, Name, DisplayName

        } elseif (($ErrorReason -eq "PSRemotingTransportException") -or ($ErrorReason -eq "COMException")) {
        
        Write-Host "$SelectedServer : You do not have permission to access the server." -ForegroundColor Red
        $Error.Clear()

      }
       else {
            Write-Host "No services with stopped status and Automatic start type found on $SelectedServer." -ForegroundColor DarkGray
        }
    } 
     
}
 
function Get-ServicesAllServers {
    

    param (
        [string]$ServerName,
        [System.Management.Automation.PSCredential]$Credential
    )
 
    $services = Invoke-Command -ComputerName $ServerName -Credential $Credential -ScriptBlock {
        Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }
    }
 
    $ErrorReason = $Error[0].CategoryInfo.Reason

    if ($services.Count -gt 0) {
        Write-Host "Services on $ServerName with Stopped status and Automatic start type:" -ForegroundColor Cyan
        $services | Format-Table -AutoSize -Property Status, Name, DisplayName

    } elseif (($ErrorReason -eq "PSRemotingTransportException") -or ($ErrorReason -eq "COMException")) {

        Write-Host "$ServerName : You do not have permission to access the server." -ForegroundColor Red
        $Error.Clear()

      }
       else {
        Write-Host "No services with stopped status and Automatic start type found on $ServerName." -ForegroundColor DarkGray
    }

}

function Restart-ServicesSpecificServer {

    param (
        [System.Management.Automation.PSCredential]$Credential
    )
 
    $ServiceServerListMenu = {
        $script:i = 1
        Write-Host "Server List" -ForegroundColor Cyan
        foreach ($Server in $Servers) {
            Write-Host "$script:i - $Server" -ForegroundColor Cyan
            $script:i++
        }

        Write-Host "Select a number to restart stopped services with Automatic start type : " -NoNewline

    }
    Invoke-Command -ScriptBlock $ServiceServerListMenu
    $ChoiceServiceServerList = Read-Host
    $ChoiceServiceServerList = [int]$ChoiceServiceServerList
 
    if ($ChoiceServiceServerList -ge 1 -and $ChoiceServiceServerList -le $Servers.Count) {
        $SelectedServer = $Servers.Split()[$ChoiceServiceServerList-1]
        $services = Invoke-Command -ComputerName $SelectedServer -Credential $Credential -ScriptBlock {
            Get-Service | Where-Object {($_.StartType -eq 'Automatic') -and ($_.Status -ne 'Running')}}

        $ErrorReason = $Error[0].CategoryInfo.Reason
 
        if ($services.Count -gt 0) {
            Write-Host "Stopped services with Automatic start type are restarting on $SelectedServer" -ForegroundColor Yellow
            $services = Invoke-Command -ComputerName $SelectedServer -Credential $Credential -ScriptBlock {
            Get-Service | Where-Object {($_.StartType -eq 'Automatic') -and ($_.Status -ne 'Running')} | Restart-Service -Force }

        } elseif (($ErrorReason -eq "PSRemotingTransportException") -or ($ErrorReason -eq "COMException")) {
        
        Write-Host "$SelectedServer : You do not have permission to access the server." -ForegroundColor Red
        $Error.Clear()

      }
       else {
            Write-Host "No services with stopped status and Automatic start type found on $SelectedServer." -ForegroundColor DarkGray
        }
    }
} 

function Restart-ServicesAllServer {

    param (
        [string]$ServerName,
        [System.Management.Automation.PSCredential]$Credential
    )

    $services = Invoke-Command -ComputerName $ServerName -Credential $Credential -ScriptBlock {
        Get-Service | Where-Object {($_.StartType -eq 'Automatic') -and ($_.Status -ne 'Running')} }
    
    $ErrorReason = $Error[0].CategoryInfo.Reason

        if ($services.Count -gt 0) {
            Write-Host "Stopped services with Automatic start type are restarting on $ServerName" -ForegroundColor Yellow
            $services = Invoke-Command -ComputerName $ServerName -Credential $Credential -ScriptBlock {
            Get-Service | Where-Object {($_.StartType -eq 'Automatic') -and ($_.Status -ne 'Running')} | Restart-Service -Force }

        } elseif (($ErrorReason -eq "PSRemotingTransportException") -or ($ErrorReason -eq "COMException")) {
        
        Write-Host "$ServerName : You do not have permission to access the server." -ForegroundColor Red
        $Error.Clear()

      }
       else {
            Write-Host "No services with stopped status and Automatic start type found on $ServerName" -ForegroundColor DarkGray
        }
    
}

function Restart-UpdatedSpecificServer{

    param (
        [System.Management.Automation.PSCredential]$Credential
    )
 
    $ServiceServerListMenu = {
        $script:i = 1
        Write-Host "Server List" -ForegroundColor Cyan
        foreach ($Server in $Servers) {
            Write-Host "$script:i - $Server" -ForegroundColor Cyan
            $script:i++
        }

        Write-Host "Select a number to restart Server : " -NoNewline

    }
    Invoke-Command -ScriptBlock $ServiceServerListMenu
    $ChoiceServiceServerList = Read-Host
    $ChoiceServiceServerList = [int]$ChoiceServiceServerList
 
    if ($ChoiceServiceServerList -ge 1 -and $ChoiceServiceServerList -le $Servers.Count) {
        $SelectedServer = $Servers.Split()[$ChoiceServiceServerList-1]

         $services = Invoke-Command -ComputerName $SelectedServer -Credential $Credential -ScriptBlock {
         Get-Service WinRM}
        
        $ErrorReason = $Error[0].CategoryInfo.Reason
        
        if ($services -ne $null) {
            
            Write-Host "Restarting server $SelectedServer ..." -ForegroundColor Yellow            
            Restart-Computer -ComputerName $SelectedServer -Credential $Credential -Force

        } elseif(($ErrorReason -eq "PSRemotingTransportException") -or ($ErrorReason -eq "COMException") -or($ErrorReason -eq "UnauthorizedAccessException") -or ($ErrorReason -eq "InvalidOperationException")) {
        
          Write-Host "$SelectedServer : You do not have permission to access the server." -ForegroundColor Red
          $Error.Clear()

          }

      }
    }

function Show-ServerUpdateMenu(){
    
    while ($true) {
        
        $Servers = Get-Content -Path $Global:filePath 

        Clear-Host
        Write-Host "		"
        Write-Host "		"
        Write-Host "		"        
        Write-Host "	**********************************************************************" -ForegroundColor White
        Write-Host "	              Server Software Center Update Management  "               -ForegroundColor Cyan
        Write-Host "	**********************************************************************" -ForegroundColor White
        Write-Host "		"
        Write-Host ''
        Write-Host "1. View Updates Status" -ForegroundColor Cyan
        Write-Host "2. Install Server Updates" -ForegroundColor Cyan
        Write-Host "3. View Services for a specific Server" -ForegroundColor Cyan
        Write-Host "4. View Services of all Servers" -ForegroundColor Cyan
        Write-Host "5. Restart Services for a specific Server" -ForegroundColor Cyan
        Write-Host "6. Restart Services for all Servers" -ForegroundColor Cyan
        Write-Host "7. Restart specific Server" -ForegroundColor Cyan
        Write-Host "8. Get Server list" -ForegroundColor Cyan
        Write-Host "9. Add Server to the list" -ForegroundColor Cyan
        Write-Host "10. Remove Server list" -ForegroundColor Cyan
        Write-Host "11. Exit" -ForegroundColor Cyan
        Write-Host ''
        
        $choice = Read-Host "Enter your choice (1-6): "
 
        switch ($choice) {
            1 {
                $Credential = Get-AdminCredentials
                foreach ($Server in $Servers) {
                    Get-ServerUpdateStatus -ServerName $Server -Credential $Credential
                }
                Read-Host "Press Enter to continue..."
            }
            2 {
                $Credential = Get-AdminCredentials
                foreach ($Server in $Servers) {
                    Install-ServerUpdates -ServerName $Server -Credential $Credential
                }
                Read-Host "Press Enter to continue..."
            }
            3 {
                $Credential = Get-AdminCredentials
                Get-ServicesSpecificServer -Credential $Credential
                Read-Host "Press Enter to continue..."
            }
            4 {
                $Credential = Get-AdminCredentials
                foreach ($Server in $Servers) {
                    Get-ServicesAllServers -ServerName $Server -Credential $Credential
                }
                Read-Host "Press Enter to continue..."
            }
            5 {
                $Credential = Get-AdminCredentials
                Restart-ServicesSpecificServer -Credential $Credential
                Read-Host "Press Enter to continue..."
            }
            6 {
                $Credential = Get-AdminCredentials
                foreach ($Server in $Servers) {
                Restart-ServicesAllServer -ServerName $Server -Credential $Credential
                }
                Read-Host "Press Enter to continue..."
            }
            7 {
                $Credential = Get-AdminCredentials
                Restart-UpdatedSpecificServer -Credential $Credential
                Read-Host "Press Enter to continue..."            

            }
            8 {
                Get-ServerList
                Read-Host "Press Enter to continue..."            

            }
            9 {
                Add-ServertoList
                Read-Host "Press Enter to continue..."            

            }
            10 {
                Remove-ServerList "Exiting..."
                Read-Host "Press Enter to continue..."      
            }
            11 {
                Write-Host "Exiting..."
                return
            }
            default {
                Write-Host "Invalid choice. Please select a valid option (1-10)." -ForegroundColor Red
                Read-Host "Press Enter to continue..."
            }
        }      
    }
}       

New-ServerList
Show-ServerUpdateMenu
