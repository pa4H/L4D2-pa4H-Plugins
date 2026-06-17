@echo off
setlocal enabledelayedexpansion

::::::::::::::::::::::
:: VARIABLES
::::::::::::::::::::::
set L4D2_HOME=D:\Steam\steamapps\common\Left 4 Dead 2
set SOX_HOME=C:\sox
set PATH=%PATH%;%SOX_HOME%
set TO_PROCESS=0
set PROCESSED=0

goto apply

::::::::::::::::::::::
:: COUNT FILES
::::::::::::::::::::::
:apply
for %%e in (wav mp3) do (
  for /R "%L4D2_HOME%" %%s in (*.%%e) do (
    set /A TO_PROCESS=!TO_PROCESS! + 1
  )
)

echo Number of audio files to be processed: %TO_PROCESS%.
pause

::::::::::::::::::::::
:: PROCESS FILES
::::::::::::::::::::::
for %%e in (wav mp3) do (
  for /R "%L4D2_HOME%" %%s in (*.%%e) do (
    echo # %%s
    echo.
    
    sox "%%s" "%%s.tmp.%%e" vol -10 db || pause
    move /Y "%%s.tmp.%%e" "%%s" || pause

    set /A PROCESSED=!PROCESSED! + 1
    echo !PROCESSED! of %TO_PROCESS%
  )
)

echo Finished processing %PROCESSED% of %TO_PROCESS% files.
goto end

::::::::::::::::::::::
:: EXIT THIS SCRIPT
::::::::::::::::::::::
:end
pause
exit /B 0