# Roblox Cheat Auto-Installer - Complete Version
Write-Host "🎯 Starting Complete Installation..." -ForegroundColor Green

# Create project structure
$projectRoot = "RobloxExternalCheat"
New-Item -ItemType Directory -Path $projectRoot -Force
Set-Location $projectRoot

Write-Host "📁 Creating folder structure..." -ForegroundColor Yellow
$folders = @(
    "src", "src/Memory", "src/Features", "src/Features/Aimbot", "src/Features/ESP", 
    "src/Features/Misc", "src/GUI", "src/SDK", "libs", "libs/imgui", "libs/minhook",
    "resources", "resources/fonts", "resources/icons", "resources/configs",
    "scripts", "docs", "tests", "third_party", "build", "bin"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force
}

# Download and extract ImGui
Write-Host "📥 Downloading ImGui..." -ForegroundColor Cyan
$imguiUrl = "https://github.com/ocornut/imgui/archive/refs/heads/docking.zip"
$imguiZip = "imgui.zip"
Invoke-WebRequest -Uri $imguiUrl -OutFile $imguiZip
Expand-Archive -Path $imguiZip -DestinationPath "libs/imgui-temp" -Force
Move-Item -Path "libs/imgui-temp/imgui-docking/*" -Destination "libs/imgui/" -Force
Remove-Item "libs/imgui-temp" -Recurse -Force
Remove-Item $imguiZip -Force

# Download and extract MinHook
Write-Host "📥 Downloading MinHook..." -ForegroundColor Cyan
$minhookUrl = "https://github.com/TsudaKageyu/minhook/archive/refs/heads/master.zip"
$minhookZip = "minhook.zip"
Invoke-WebRequest -Uri $minhookUrl -OutFile $minhookZip
Expand-Archive -Path $minhookZip -DestinationPath "libs/minhook-temp" -Force
Move-Item -Path "libs/minhook-temp/minhook-master/include" -Destination "libs/minhook/" -Force
Move-Item -Path "libs/minhook-temp/minhook-master/src" -Destination "libs/minhook/" -Force
Remove-Item "libs/minhook-temp" -Recurse -Force
Remove-Item $minhookZip -Force

# Create main CMakeLists.txt
Write-Host "⚙️ Creating CMake files..." -ForegroundColor Cyan
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

# Create src/CMakeLists.txt
$srcCmake = @'
file(GLOB_RECURSE SOURCES "*.cpp" "*.h")
file(GLOB_RECURSE IMGUI_SOURCES "../libs/imgui/*.cpp" "../libs/imgui/backends/imgui_impl_dx11.cpp" "../libs/imgui/backends/imgui_impl_win32.cpp")

add_executable(${PROJECT_NAME} ${SOURCES} ${IMGUI_SOURCES})

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../libs/imgui
    ${CMAKE_CURRENT_SOURCE_DIR}/../libs/minhook/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../libs/imgui/backends
)

target_link_libraries(${PROJECT_NAME} imgui minhook dxgi d3d11 d3dcompiler)
'@
Set-Content -Path "src/CMakeLists.txt" -Value $srcCmake

# Create basic main.cpp
$mainCode = @'
#include <Windows.h>
#include <d3d11.h>
#include <imgui.h>
#include <imgui_impl_dx11.h>
#include <imgui_impl_win32.h>

class CheatApp {
public:
    bool Initialize() {
        return true;
    }
    
    void Run() {
        while (true) {
            // Main loop will be here
            Sleep(100);
        }
    }
};

int main() {
    CheatApp app;
    if (app.Initialize()) {
        app.Run();
    }
    return 0;
}
'@
Set-Content -Path "src/main.cpp" -Value $mainCode

# Create build script
$buildBat = @'
@echo off
echo Building Roblox External Cheat...
mkdir build 2>nul
cd build
cmake -G "Visual Studio 17 2022" -A x64 ..
cmake --build . --config Release
if exist Release\*.exe (
    copy Release\*.exe ..\bin\
    echo ✅ Build successful! Check bin\ folder.
) else (
    echo ❌ Build failed!
)
pause
'@
Set-Content -Path "build.bat" -Value $buildBat -Encoding ASCII

Write-Host "`n🎉 Project structure created successfully!" -ForegroundColor Green
Write-Host "📁 Location: $(Get-Location)" -ForegroundColor Cyan

# Check for required tools
Write-Host "`n🔍 Checking installed tools..." -ForegroundColor Yellow

$tools = @("cmake", "msbuild")
$missingTools = @()

foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "✅ $tool is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ $tool is missing" -ForegroundColor Red
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host "`n📥 Installing missing tools..." -ForegroundColor Yellow
    
    # Install Chocolatey if needed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    # Install missing tools
    if ($missingTools -contains "cmake") {
        choco install cmake -y
    }
    
    if ($missingTools -contains "msbuild") {
        choco install visualstudio2022buildtools -y --params="--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    }
    
    refreshenv
}

Write-Host "`n🚀 Ready to build! Run .\build.bat to compile your cheat." -ForegroundColor Green
