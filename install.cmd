lazbuild .\lib\MiniCommons.lpk
lazbuild .\xml\source\MiniXML.lpk
lazbuild .\socket\source\MiniSockets.lpk
lazbuild .\connection\src\MiniConnections.lpk
lazbuild .\comm\source\MiniComm.lpk
lazbuild .\lazarus\lib\MiniLib.lpk
lazbuild --add-package .\lazarus\components\native\NativeLib.lpk --add-package .\pos\source\poslib.lpk
rem lazbuild --build-all --add-package .\pos\source\poslib.lpk
lazbuild --build-ide= 
pause