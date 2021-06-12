:: A one-shot, first-time Windows configuration script that disables some
:: Windows misfeatures and sets paths to my usual preferences. I wish this
:: script could do more, especially to disable Windows' built-in adware and
:: spyware, but following Microsoft's usual mediocrity, Windows remains a
:: toy operating system with most configuration inaccessible to scripts.

:: Annoyances
set key="HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
reg add "%key%" /f /v TaskbarGlomLevel          /t REG_DWORD /d 2
reg add "%key%" /f /v HideFileExt               /t REG_DWORD /d 0
reg add "%key%" /f /v ShowCortanaButton         /t REG_DWORD /d 0
reg add "%key%" /f /v ShowTaskViewButton        /t REG_DWORD /d 0
reg add "%key%" /f /v StoreAppsOnTaskbar        /t REG_DWORD /d 0
reg add "%key%" /f /v MultiTaskingAltTabFilter  /t REG_DWORD /d 3
reg add "%key%" /f /v JointResize               /t REG_DWORD /d 0
reg add "%key%" /f /v SnapFill                  /t REG_DWORD /d 0
reg add "%key%" /f /v SnapAssist                /t REG_DWORD /d 0
set key="HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds"
reg add "%key%" /f /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2
set key="HKCU\Software\Microsoft\Windows\CurrentVersion\Search"
reg add "%key%" /f /v SearchboxTaskbarMode      /t REG_DWORD /d 0
set key="HKCU\Control Panel\Desktop"
reg add "%key%" /f /v CursorBlinkRate           /t REG_SZ    /d -1
set key="HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
reg delete "%key%" /f /v Favorites

:: Paths
setx GOBIN "%USERPROFILE%\bin"
setx GOPATH "%TEMP%\go"
setx PATH "%PATH%;%USERPROFILE%\bin;%USERPROFILE%\go\bin"

:: Reload
taskkill /f /im explorer.exe
start explorer.exe
