:: PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
:: will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
:: changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
:: benefit from the improvement.

:: INPUTS (required environment variables)
:: CONDA_BLD_PATH: path for the conda-build workspace
:: CI: azure, or unset

setlocal enableextensions enabledelayedexpansion

call :start_group "Installing conda"

PIXI_VERSION="0.30.0"
PIXI_URL="https://github.com/prefix-dev/pixi/releases/download/v%PIXI_VERSION%/pixi-x86_64-pc-windows-msvc.exe"
set "PIXI_TMPDIR=%TMP%\pixi-%RANDOM%"
set "PIXI_TMP=%PIXI_TMPDIR%\pixi.exe"
set "MINIFORGE_ROOT=%CD%\.pixi\envs\default"

echo Downloading pixi %PIXI_VERSION%
if not exist "%PIXI_TMPDIR%" mkdir "%PIXI_TMPDIR%"
certutil -urlcache -split -f "%PIXI_URL%" "%PIXI_TMP%"
if errorlevel 1 exit 1

echo Importing environment
call "%PIXI_TMP%" init --import .ci_support\requirements.yaml --platform win-64
if errorlevel 1 exit 1
echo Creating environment
call "%PIXI_TMP%" install
if errorlevel 1 exit 1

call :end_group

call :start_group "Configuring conda"

if "%CONDA_BLD_PATH%" == "" (
    set "CONDA_BLD_PATH=C:\bld"
)

:: Activate the base conda environment
echo Activating "%MINIFORGE_ROOT%"
call "%MINIFORGE_ROOT%\Scripts\activate" "%MINIFORGE_ROOT%"

:: Set basic configuration
echo Setting up configuration
conda.exe config --set always_yes yes
if errorlevel 1 exit 1
conda.exe config --set channel_priority strict
if errorlevel 1 exit 1
conda.exe config --set solver libmamba
if errorlevel 1 exit 1

setup_conda_rc .\ ".\recipes" .\.ci_support\%CONFIG%.yaml
if errorlevel 1 exit 1

echo Run conda_forge_build_setup
call run_conda_forge_build_setup
if errorlevel 1 exit 1

echo Force fetch origin/main
git fetch --force origin main:main
if errorlevel 1 exit 1
echo Removing recipes also present in main
cd recipes
for /f "tokens=*" %%a in ('git ls-tree --name-only main -- .') do rmdir /s /q %%a && echo Removing recipe: %%a
cd ..

:: make sure there is a package directory so that artifact publishing works
if not exist "%CONDA_BLD_PATH%\win-64\" mkdir "%CONDA_BLD_PATH%\win-64\"
if not exist "%CONDA_BLD_PATH%\noarch\" mkdir "%CONDA_BLD_PATH%\noarch\"

echo Index %CONDA_BLD_PATH%
conda.exe index "%CONDA_BLD_PATH%"
if errorlevel 1 exit 1

call :end_group

echo Building all recipes
python .ci_support\build_all.py --arch 64
if errorlevel 1 exit 1

call :start_group "Inspecting artifacts"

:: inspect_artifacts was only added in conda-forge-ci-setup 4.6.0; --all-packages in 4.9.3
WHERE inspect_artifacts >nul 2>nul && inspect_artifacts --all-packages || echo "inspect_artifacts needs conda-forge-ci-setup >=4.9.3"

call :end_group

exit

:: Logging subroutines

:start_group
if /i "%CI%" == "github_actions" (
    echo ::group::%~1
    exit /b
)
if /i "%CI%" == "azure" (
    echo ##[group]%~1
    exit /b
)
echo %~1
exit /b

:end_group
if /i "%CI%" == "github_actions" (
    echo ::endgroup::
    exit /b
)
if /i "%CI%" == "azure" (
    echo ##[endgroup]
    exit /b
)
exit /b
