# --- Config Paths ---
$basePath = "C:\kworking\hostnamefix"
$csvPath = Join-Path $basePath "hostname_map.csv"
$aesKeyPath = Join-Path $basePath "AESkey.txt"
$securePwdPath = Join-Path $basePath "credpassword.txt"
$logPath = "C:\Temp\rename_log.txt"

# --- Init Log File ---
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $message"
}

# --- Ensure Log Directory Exists ---
if (-Not (Test-Path -Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
}

# --- Create base directory ---
try {
    New-Item -Path $basePath -ItemType Directory -Force | Out-Null
    Write-Log "Directory created: $basePath"
} catch {
    Write-Log "ERROR: Failed to create directory: $_"
    exit 1
}

# --- Copy required files ---
try {
    $scriptSource = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Copy-Item -Path (Join-Path $scriptSource "AESkey.txt") -Destination $basePath -Force
    Copy-Item -Path (Join-Path $scriptSource "credpassword.txt") -Destination $basePath -Force
    Copy-Item -Path (Join-Path $scriptSource "hostname_map.csv") -Destination $basePath -Force
    Copy-Item -Path (Join-Path $scriptSource "Fixhostnames.ps1") -Destination $basePath -Force
    Write-Log "Copied required files successfully."
} catch {
    Write-Log "ERROR: Failed to copy required files: $_"
    exit 1
}

# --- Load and Decrypt Credentials ---
try {
    $user = "Your admin account with AD privileges"
    $AESKey = Get-Content -Path $aesKeyPath
    $pwdTxt = Get-Content -Path $securePwdPath
    $securePass = $pwdTxt | ConvertTo-SecureString -Key $AESKey
    $creds = New-Object System.Management.Automation.PSCredential ($user, $securePass)
    Write-Log "Credentials loaded and decrypted successfully."
} catch {
    Write-Log "ERROR: Failed to load or decrypt credentials: $_"
    exit 1
}

# --- Read Serial Number and Find Hostname ---
try {
    $serialNumber = (Get-WmiObject Win32_BIOS).SerialNumber.Trim()
    $hostnameMap = Import-Csv -Path $csvPath
    $newName = ($hostnameMap | Where-Object { $_.SerialNumber -eq $serialNumber }).NewHostname
    Write-Log "Serial: $serialNumber | Target Hostname: $newName"
} catch {
    Write-Log "ERROR: Failed to process hostname mapping: $_"
    exit 1
}

# --- Rename Computer if Needed ---
if ($newName -and ($newName -ne $env:COMPUTERNAME)) {
    try {
        Rename-Computer -NewName $newName -DomainCredential $creds -Force -PassThru
        Write-Log "SUCCESS: Hostname changed to $newName"
    } catch {
        Write-Log "ERROR: Rename failed - $_"
        exit 1
    }
} else {
    Write-Log "INFO: No rename required. Current hostname matches or no mapping found."
}

# --- Cleanup Files ---
try {
    Start-Sleep -Seconds 10
    Remove-Item -Path $basePath -Recurse -Force -ErrorAction Stop
    Write-Log "Cleanup successful. Folder deleted."
} catch {
    Write-Log "ERROR: Cleanup failed - $_"
}
