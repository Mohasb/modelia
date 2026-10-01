@echo off
rem Compila la demo web sin backend (modo demo) para publicarla en GitHub Pages:
rem https://mohasb.github.io/modeliaWeb/  (repositorio modeliaWeb, rama gh-pages)
rem Resultado en build\web, con los modelos 3D optimizados en build\web\demo-models.
call flutter build web --release --dart-define=DEMO=true --base-href /modeliaWeb/ || exit /b 1
if not exist build\web\demo-models mkdir build\web\demo-models
copy /Y demo\models\*.glb build\web\demo-models\ >nul
echo Demo lista en build\web
