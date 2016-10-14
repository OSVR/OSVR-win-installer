echo on
REM copy core distribution from source
REM copy over service and helper files
REM osvr_services.exe
REM osvr_print_treeRZ.exe
REM osvr_reset_yaw_RZ.exe
copy %1\osvr_services.exe %1\OSVR-Core-32\bin
REM copy %1\osvr_print_treeRZ.exe %1\OSVR-Core\bin
REM copy %1\osvr_reset_yaw_RZ.exe %1\OSVR-Core\bin
REM copy over tracker viewer
REM copy over configurator and user setting plugins
REM put server config file in bin diretory
REM copy %1\OSVR-Config\com_osvr_user_settings\osvr_server_config.json %1\OSVR-Core\bin
REM put plugin in bin\osvr-plugins-0 director
REM copy %1\OSVR-Config\com_osvr_user_settings\osvr-plugins-0\com_osvr_user_settings.dll %1\OSVR-Core\bin\osvr-plugins-0
REM copy over render manager
"C:\Program Files (x86)\NSIS\makensis" /DdistroDirectory=..\%1 /DpVersion=%2 /DunicodeEnable /O..\%1\makensis.log setupservice.nsi
del "..\%1\OSVR Runtime Setup.%1.%2.exe"
rename "..\%1\OSVR Runtime Setup.%2.exe" "OSVR Runtime Setup.%1.%2.exe"
