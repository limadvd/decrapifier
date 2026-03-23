Write-Output "Iniciando desinstalacao de Bloatware"
& ([scriptblock]::Create((irm "https://debloat.raphi.re/"))) -Silent -RunDefaults -RemoveW11Outlook -RemoveGamingApps -DisableDVR -DisableTelemetry -DisableBing -DisableSuggestions -DisableLockscreenTips -TaskbarAlignLeft -ShowSearchIconTb -HideTaskView -HideChat -DisableWidgets -DisableCopilot -DisableRecall -HideHome -HideGallery
 
Start-Sleep -Seconds 5 "Wait done"
 
Write-Output "Iniciando segundo run pro Task Bar"
& ([scriptblock]::Create((irm "https://debloat.raphi.re/"))) -Silent -RemoveW11Outlook -RemoveGamingApps -DisableDVR -DisableTelemetry -DisableBing -DisableSuggestions -DisableLockscreenTips -TaskbarAlignLeft -ShowSearchIconTb -HideTaskView -HideChat -DisableWidgets -DisableCopilot -DisableRecall -HideHome -HideGallery

 
# REMOVE O ONE DRIVE DE TODOS OS USUÁRIOS (Peguei do Git)
Write-Output "Iniciando desinstalacao de OneDrive"
 
Function Get-LogDir{
  Try
  {
    $TS = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    If ($TS.Value("LogPath") -ne "")
    {
      $LogDir = $TS.Value("LogPath")
    }
    Else
    {
      $LogDir = $TS.Value("_SMSTSLogPath")
    }
  }
  Catch
  {
    $LogDir = $env:TEMP
  }
 
  Return $LogDir
}
 
Function Remove-OneDrive{
 
reg load "hku\Default" "C:\Users\Default\NTUSER.DAT"
 
New-PSDrive -name Default -Psprovider Registry -root HKEY_USERS\Default >> $null
$Regkey  = "Default:\Software\Microsoft\Windows\CurrentVersion\Run"
 
Remove-ItemProperty -Path $Regkey -Name OneDriveSetup
Write-Information "OneDriveSetup.exe removed"
Remove-PSDrive -Name Default >> $null
 
reg unload "hku\Default"
 
}
 
$OSBuildNumber = Get-WmiObject -Class "Win32_OperatingSystem" | Select-Object -ExpandProperty BuildNumber
if ($OSBuildNumber -le "17134") {
            Remove-Item -Path "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Onedrive.lnk" -Force
}
 
$LogDir = Get-LogDir
Start-Transcript "$LogDir\OSD-Remove-OneDrive.log"
Write-Information "$(Get-Date -UFormat %R)"
Remove-OneDrive
Write-Information "$(Get-Date -UFormat %R)"
Stop-Transcript
 
# Remove o atalho do Microsoft EDGE de todos as Áreas de Trabalho
$publicDesktopPath = "C:\Users\Public\Desktop"
$edgeShortcutName = "Microsoft Edge.lnk"
$edgeShortcutPath = Join-Path -Path $publicDesktopPath -ChildPath $edgeShortcutName
if (Test-Path -Path $edgeShortcutPath) {
    Remove-Item -Path $edgeShortcutPath -Force
    Write-Host "Icone do Edge removido do Desktop."
} else {
    Write-Host "Icone do Edge não encontrado para remover."
}
# CONFIGURA BARRA DE TAREFAS PARA TODOS OS USUÁRIOS
Write Output "Iniciando padronização de Barra de tarefas..."
If(Test-Path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml") {
Remove-Item "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
}
 
$blankjson = @'
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
    <CustomTaskbarLayoutCollection PinListPlacement="Replace">
        <defaultlayout:TaskbarLayout>
            <taskbar:TaskbarPinList>
                <taskbar:DesktopApp DesktopApplicationID="Microsoft.Windows.Explorer"/>
                <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"/>
            </taskbar:TaskbarPinList>
        </defaultlayout:TaskbarLayout>
    </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate> 
'@
 
$blankjson | Out-File "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Encoding utf8 -Force
 
 
# AJUSTES ADICIONAIS
# Desabilita algumas Tarefas no Gerenciador de Tarefas que são desnecessárias.
Write-Host "Desabilitando tarefas desnecessárias..."
 
$toDisableTasks = @(
    "XblGameSaveTaskLogon",
    "XblGameSaveTask",
    "Consolidator",
    "UsbCeip",
    "DmClient",
    "DmClientOnScenarioDownload"
)
 
foreach ($task in $toDisableTasks) {
    if ($null -ne $task){
        Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
    }
}
 
# Desabilita o serviço de diagnostico e rastreamento do Windows
Write-Output "Desabilitando serviço de diagnostico do Windows"
Stop-Service "DiagTrack"
Set-Service "DiagTrack" -StartupType Disabled
 
# DEFINE TODAS AS POLÍTICAS
Invoke-Command -ScriptBlock {
    powershell -ExecutionPolicy Bypass -Command {
 
function Install-PSModule {
  param(
    [Parameter(Position = 0, Mandatory = $true)]
    [String[]]$Modules
  )
 
  Write-Output "`nVerificando modulos de Powershell..."
  try {
    # Configura o PowerShell para TLS 1.2 (https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/)
    if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
 
    # Instala o NuGet
    if (!(Get-PackageProvider -ListAvailable -Name 'NuGet' -ErrorAction Ignore)) {
      Write-Output 'Instalando NuGet...'
      Install-PackageProvider -Name 'NuGet' -MinimumVersion 2.8.5.201 -Force
    }
 
    # Estabelece o PSGallery como confiável
    Register-PSRepository -Default -InstallationPolicy 'Trusted' -ErrorAction Ignore
    if (!(Get-PSRepository -Name 'PSGallery' -ErrorAction Ignore).InstallationPolicy -eq 'Trusted') {
      Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' | Out-Null
    }
   
    # Instala e importa os módulos necessários
    ForEach ($Module in $Modules) {
      if (!(Get-Module -ListAvailable -Name $Module -ErrorAction Ignore)) {
        Write-Output "`nInstalando $Module..."
        Install-Module -Name $Module -Force
        Import-Module $Module
      }
    }
 
    Write-Output 'Modulos instalado.'
  }
  catch { 
    Write-Warning 'Incapaz de instalar modulos.'
    Write-Warning $_
    exit 1
  }
}
 
$Modules = @('PolicyFileEditor')
$ComputerPolicyFile = ($env:SystemRoot + '\System32\GroupPolicy\Machine\registry.pol')
$UserPolicyFile = ($env:SystemRoot + '\System32\GroupPolicy\User\registry.pol')
Set-Location -Path $env:SystemRoot
 
# Define políticas do OOBE, OneDrive e EDGE.
If (!(Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "OOBE" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE" -Name "DisablePrivacyExperience" -Value 1 -PropertyType DWORD -Force | Out-Null
}
If (!(Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUpdate)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "EdgeUpdate" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "CreateDesktopShortcutDefault" -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "RemoveDesktopShortcut" -Value 1 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "RemoveDesktopShortcutDefault" -Value 1 -PropertyType DWORD -Force | Out-Null
}
If (!(Test-Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer)) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "DisableEdgeDesktopShortcutCreation" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "DisableEdgeDesktopShortcutCreation" -Value 1 -PropertyType DWORD -Force | Out-Null
}
 
If (!(Test-Path HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\OneDrive)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "OneDrive" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -PropertyType DWORD -Force | Out-Null
}
 
# Define as políticas
$ComputerPolicies = @(
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\Communications'; ValueName = 'ConfigureChatAutoInstall'; Data = '0'; Type = 'Dword' } # Disable Teams (personal) auto install (W11)
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; ValueName = 'Enabled'; Data = '0'; Type = 'Dword' } # Disable Windows Feedback Exp. program
  [PSCustomObject]@{Key = 'Software\Microsoft\Siuf\Rules'; ValueName = 'PeriodInNanoSeconds'; Data = '0'; Type = 'Dword' } # Stops Windows Feedback Exp. program from sending anonymous data
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Windows Chat'; ValueName = 'ChatIcon'; Data = '2'; Type = 'Dword' } # Hide Chat icon by default (W11)
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Windows Search'; ValueName = 'AllowCortana'; Data = '0'; Type = 'Dword' } # Disable Cortana
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Windows Feeds'; ValueName = 'EnableFeeds'; Data = '0'; Type = 'Dword' } # Disable news/interests on taskbar
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Windows Search'; ValueName = 'DisableWebSearch'; Data = '1'; Type = 'Dword' } # Disable Web search in Start (This removes Edge trying to creep in as recommendation in Search Box)
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Windows Search'; ValueName = 'AllowCloudSearch'; Data = '0'; Type = 'Dword' } # Disable Cloud search in Start (This removes the annoying Azure notification to verify account in Search Box)
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Windows Search'; ValueName = 'EnableDynamicContentInWSB'; Data = '0'; Type = 'Dword' } # Disable Dynamic Content in Search Box (This removes the Weather prediction or cake recipees, whatever, from the Search Box)
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\CloudContent'; ValueName = 'DisableCloudOptimizedContent'; Data = '1'; Type = 'Dword' } # Disable cloud consumer content
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\CloudContent'; ValueName = 'DisableConsumerAccountStateContent'; Data = '1'; Type = 'Dword' } # Disable cloud consumer content
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\CloudContent'; ValueName = 'DisableWindowsConsumerFeatures'; Data = '1'; Type = 'Dword' } # Disable Consumer Experiences
  [PSCustomObject]@{Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName = 'EnableFirstLogonAnimation'; Data = '0'; Type = 'Dword' } # Disable First Login Animation
  [PSCustomObject]@{Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE'; ValueName = 'DisablePrivacyExperience'; Data = '1'; Type = 'Dword' } # Disable Privacy Exp. on OOBE
  [PSCustomObject]@{Key = 'SOFTWARE\Policies\Microsoft\Windows\OOBE'; ValueName = 'DisablePrivacyExperience'; Data = '1'; Type = 'Dword' } # Disable Privacy Exp. on OOBE
  [PSCustomObject]@{Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE'; ValueName = 'PrivacySettingsSkipped'; Data = '1'; Type = 'Dword' } # Skips Privacy Settings in OOBE
  [PSCustomObject]@{Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE'; ValueName = 'PrivacyConsentStatus'; Data = '0'; Type = 'Dword' } # Skips Privacy Consent Settings in OOBE
  [PSCustomObject]@{Key = 'SOFTWARE\Policies\Microsoft\Windows\DataCollection'; ValueName = 'AllowTelemetry'; Data = '0'; Type = 'Dword' } # Disable Telemetry
  [PSCustomObject]@{Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; ValueName = 'AllowTelemetry'; Data = '0'; Type = 'Dword' } # Disable Telemetry
  [PSCustomObject]@{Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'; ValueName = 'TailoredExperiencesWithDiagnosticDataEnabled'; Data = '0'; Type = 'Dword' } # Disable Diagnostics
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Edge'; ValueName = 'HideFirstRunExperience'; Data = '1'; Type = 'Dword' } # Disable EDGE First Run Experience, and also First Logon popup
  )
 
$UserPolicies = @(
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; ValueName = 'TaskbarMn'; Data = '0'; Type = 'Dword' } # Disable Chat Icon (Nobody cares about this)
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; ValueName = 'HideSCAMeetNow'; Data = '1'; Type = 'Dword' } # Disable Meet Now icon (W10)
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\Search'; ValueName = 'SearchboxTaskbarMode'; Data = '1'; Type = 'Dword' } # Set Search in taskbar to show icon only 
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'DisableWindowsSpotlightFeatures'; Data = '1'; Type = 'Dword' } # Disable Windows Spotlight (Spotlight is only useful with Azure)
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'ContentDeliveryAllowed'; Data = '0'; Type = 'Dword' } # Disable Content Delivery
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'OemPreInstalledAppsEnabled'; Data = '0'; Type = 'Dword' } # Disable OEM Apps
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'PreInstalledAppsEnabled'; Data = '0'; Type = 'Dword' } # Disable Pre-Installed Apps
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'SilentInstalledAppsEnabled'; Data = '0'; Type = 'Dword' } # Disable Silent Installed Apps
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'SystemPaneSuggestionsEnabled'; Data = '0'; Type = 'Dword' } # Disable Pane Suggestion Apps
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'SubscribedContent-310093Enabled'; Data = '0'; Type = 'Dword' } # This possibly disables Windows "Finish setting up Windows" screens after updating, which freezes kiosk VCs
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; ValueName = 'SubscribedContent-338389Enabled'; Data = '0'; Type = 'Dword' } # Disable Pane Suggestion Apps
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\Holographic'; ValueName = 'FirstRunSucceeded'; Data = '0'; Type = 'Dword' } # Disable Holographic
  [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'; ValueName = 'ScoobeSystemSettingEnabled'; Data = '0'; Type = 'Dword' } # Disables that Get More Out of Windows irritating popup
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Explorer'; ValueName = 'DisableSearchBoxSuggestions'; Data = '1'; Type = 'Dword' } # Disables suggested content from Expanded Search Bar
  [PSCustomObject]@{Key = 'Software\Microsoft\InputPersonalization'; ValueName = 'RestrictImplicitTextCollection'; Data = '1'; Type = 'Dword' } # Disables implicit text collection
  [PSCustomObject]@{Key = 'Software\Microsoft\InputPersonalization'; ValueName = 'RestrictImplicitInkCollection'; Data = '1'; Type = 'Dword' } # Disables ink text collection info
  [PSCustomObject]@{Key = 'Software\Microsoft\Personalization\Settings'; ValueName = 'AcceptedPrivacyPolicy'; Data = '0'; Type = 'Dword' } # Whether it was accepted or not (Possibly removes prompt from Welcome Screen)
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\OneDrive'; ValueName = 'AutoStartEnabled'; Data = '0'; Type = 'Dword' } # Prevent OneDrive from booting
  )
 
# Aplica políticas em todos os contextos
Install-PSModule $Modules
try {
  Write-Output 'Definindo politica...'
  $ComputerPolicies | Set-PolicyFileEntry -Path $ComputerPolicyFile -ErrorAction Stop
  $UserPolicies | Set-PolicyFileEntry -Path $UserPolicyFile -ErrorAction Stop
  gpupdate /force /wait:0 | Out-Null
  Write-Output 'Group policies set.'
}
catch {
  Write-Warning 'Erro em aplicar politicas.'
  Write-Output $_
}
    }
}