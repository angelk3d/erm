# Complete Roblox Cheat Installer - Fixed Version
Write-Host "🎯 Starting Roblox Cheat Installation (Fixed)..." -ForegroundColor Green

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "⚠️  Please run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Function to install Visual Studio Build Tools
function Install-VSBuildTools {
    Write-Host "📦 Installing Visual Studio Build Tools..." -ForegroundColor Cyan
    
    $installerPath = "$env:TEMP\vs_buildtools.exe"
    
    # Download VS Build Tools
    Write-Host "Downloading Visual Studio Build Tools..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_buildtools.exe" -OutFile $installerPath -TimeoutSec 300
    }
    catch {
        Write-Host "Failed to download from primary URL, trying backup..." -ForegroundColor Yellow
        # Alternative download source
        Invoke-WebRequest -Uri "https://download.visualstudio.microsoft.com/download/pr/9b3476ff-6d0a-4ff8-956a-147e52f65faa/17c918c2d7b216c7bcb234de1dbe5bcc/vs_BuildTools.exe" -OutFile $installerPath -TimeoutSec 300
    }
    
    # Install with minimal C++ components
    Write-Host "Installing Visual Studio Build Tools (this will take a while)..." -ForegroundColor Yellow
    $installArgs = @(
        "--quiet", "--wait", "--norestart", "--nocache",
        "--add", "Microsoft.VisualStudio.Workload.VCTools",
        "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "--add", "Microsoft.VisualStudio.Component.Windows10SDK"
    )
    
    Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow
    
    # Cleanup
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
}

# Function to install Chocolatey and other tools
function Install-Tools {
    # Install Chocolatey if not present
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "📦 Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        refreshenv
    }
    
    # Install other tools via Chocolatey
    $tools = @("cmake", "python", "git")
    foreach ($tool in $tools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Host "Installing $tool..." -ForegroundColor Yellow
            choco install $tool -y --no-progress
        }
    }
    
    refreshenv
}

# Main installation process
try {
    # Create project structure
    $projectRoot = "RobloxExternalCheat"
    New-Item -ItemType Directory -Path $projectRoot -Force
    Set-Location $projectRoot

    Write-Host "📁 Creating project structure..." -ForegroundColor Cyan
    $folders = @(
        "src", "src/Memory", "src/Features", "src/Features/Aimbot", "src/Features/ESP", 
        "src/Features/Misc", "src/GUI", "src/SDK", "libs", "libs/imgui", "libs/minhook",
        "resources", "resources/fonts", "resources/icons", "resources/configs",
        "scripts", "docs", "tests", "third_party", "build", "bin"
    )

    foreach ($folder in $folders) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    # Install required tools
    Install-Tools
    
    # Install Visual Studio Build Tools
    Install-VSBuildTools

    # Download dependencies
    Write-Host "📥 Downloading dependencies..." -ForegroundColor Cyan

    # Download ImGui
    if (-not (Test-Path "libs/imgui/imgui.h")) {
        Write-Host "Downloading ImGui..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://github.com/ocornut/imgui/archive/refs/heads/docking.zip" -OutFile "imgui.zip"
        Expand-Archive -Path "imgui.zip" -DestinationPath "libs/imgui-temp" -Force
        Move-Item -Path "libs/imgui-temp/imgui-docking/*" -Destination "libs/imgui/" -Force
        Remove-Item "libs/imgui-temp" -Recurse -Force
        Remove-Item "imgui.zip" -Force
    }

    # Download MinHook
    if (-not (Test-Path "libs/minhook/include/minhook.h")) {
        Write-Host "Downloading MinHook..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://github.com/TsudaKageyu/minhook/archive/refs/heads/master.zip" -OutFile "minhook.zip"
        Expand-Archive -Path "minhook.zip" -DestinationPath "libs/minhook-temp" -Force
        Move-Item -Path "libs/minhook-temp/minhook-master/include" -Destination "libs/minhook/" -Force
        Move-Item -Path "libs/minhook-temp/minhook-master/src" -Destination "libs/minhook/" -Force
        Remove-Item "libs/minhook-temp" -Recurse -Force
        Remove-Item "minhook.zip" -Force
    }

    # Create CMake files and basic project structure
    Write-Host "⚙️ Creating project files..." -ForegroundColor Cyan
    
    # Main CMakeLists.txt
    $cmakeContent = @'
cmake_minimum_required(VERSION 3.20)
project(RobloxExternalCheat)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17")
    add_compile_options(/W4)
endif()

add_subdirectory(libs/imgui)
add_subdirectory(libs/minhook)
add_subdirectory(src)

set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)
'@
    Set-Content -Path "CMakeLists.txt" -Value $cmakeContent

    # Create basic main.cpp
    $mainCode = @'
#include <Windows.h>
#include <iostream>

int main() {
    std::cout << "Roblox External Cheat Project" << std::endl;
    std::cout << "Build successful! Add your cheat code here." << std::endl;
    system("pause");
    return 0;
}
'@
    Set-Content -Path "src/main.cpp" -Value $mainCode

    # Create simple build script
    $buildScript = @'
@echo off
echo Building Roblox External Cheat...
if not exist build mkdir build
cd build
cmake -G "Visual Studio 17 2022" -A x64 ..
if %errorlevel% equ 0 (
    cmake --build . --config Release
    if exist Release\*.exe (
        copy Release\*.exe ..\bin\
        echo ✅ Build successful! Check bin\ folder.
    ) else (
        echo ❌ Build failed - no executable created.
    )
) else (
    echo ❌ CMake configuration failed.
)
pause
'@
    Set-Content -Path "build.bat" -Value $buildScript -Encoding ASCII

    Write-Host "`n🎉 INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "📁 Project location: $(Get-Location)" -ForegroundColor Cyan
    Write-Host "`n🚀 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Open Command Prompt as Administrator" -ForegroundColor White
    Write-Host "2. Navigate to: $(Get-Location)" -ForegroundColor White
    Write-Host "3. Run: build.bat" -ForegroundColor White
    Write-Host "`n⚠️  Note: First build might take several minutes" -ForegroundColor Magenta

}
catch {
    Write-Host "❌ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please try running the script again or install tools manually." -ForegroundColor Yellow
}

# Final refresh
refreshenv
