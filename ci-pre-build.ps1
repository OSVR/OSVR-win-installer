# Build step script for use in CI to create a redistribution bundle

# Copyright 2016 Sensics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$buildType = $env:TYPE

# "Entry Point" function
function Main() {

    if($buildType.compareTo("DEV") -eq 0){

        Write-Host "Renaming RenderManager folders"
        Rename-Dir "RenderManager\BIT=32,label=windows" "x86"
        Rename-Dir "RenderManager\BIT=64,label=windows" "x64"

        Write-Host "Renaming OSVR-Core folders"
        Rename-Dir "OSVR-Core\BIT=32" "x86"
        Rename-Dir "OSVR-Core\BIT=64" "x64"

        Write-Host "Moving 32 bit RenderManager contents up one dir"
        MoveUpOneDir("RenderManager\x86\install")
        Write-Host "Moving 64 bit RenderManager contents up one dir"
        MoveUpOneDir("RenderManager\x64\install")

        Write-Host "Moving 32 bit OSVR-Core contents up one dir"
        MoveUpOneDir("OSVR-Core\x86\install")
        Write-Host "Moving 64 bit OSVR-Core contents up one dir"
        MoveUpOneDir("OSVR-Core\x64\install")

        Write-Host "Removing extra files from RenderManager-SDK"
        Move-RenderManager-SDK "RenderManager\x86"
        Move-RenderManager-SDK "RenderManager\x64"
    }

    Write-Host "Moving OSVR-Central contents up one dir"
    MoveUpOneDir("OSVR-Central\bin")
    Write-Host "Removing extra files from OSVR-Central"
    Move-OSVR-Central "OSVR-Central"

    Write-Host "Moving RenderManager-Release contents up one dir"
    MoveUpOneDir("RenderManager-Release\install")
    Write-Host "Removing extra files from RenderManager-Release"
    Move-RenderManager "RenderManager-Release"

    Write-Host "Moving OSVR-Core-Release contents up one dir"
    MoveUpOneDir("OSVR-Core-Release\install")
    Write-Host "Removing extra files from OSVR-Core-Release"
    Move-OSVR-Core "OSVR-Core-Release"

    Write-Host "Moving OSVR-Config contents up one dir"
    MoveUpOneDir("OSVR-Config\artifacts")

    Write-Host "Removing extra files from OSVR Tracker Viewer"
    Move-OSVR-Tracker-View "OSVR-Tracker-Viewer"

    Write-Host "ci-build complete!"
}

function MoveUpOneDir([string]$dirPath){
    $files = Get-Childitem -path . -filter $dirPath
        foreach ($file in $files) {
            $subFiles = Get-Childitem -path $file.FullName
            foreach ($subFile in $subFiles) {
                $tempName = $file.Parent.FullName + "\" + $subFile.Name + '-foo'
                $newName = $file.Parent.FullName + "\" + $subFile.Name
                #output for testing
                #write-host "Old Location: " $subFile.FullName
                #write-host "New Location:" $newName

                Write-Host "Moving: " + $subFile
                Move-Item -path $subFile.FullName -dest $tempName
                Move-Item -path $tempName -dest $newName
            }
        }
    Write-Host "Removing empty dir" : $file.FullName
    Remove-Item -path $file.FullName
}

function Move-OSVR-Core([string]$OSVRDir) {

    # Extra dirs and files to remove OSVR Core Release
    $OSVRDirs = 'include',
                'lib',
                'share'
    $OSVRFiles = 'add_sdk_to_registry.ps1',
                 'add_sdk_to_registry.cmd'


    Write-Host "Removing extra files from OSVR-Core-Release"
    $OSVRPaths = $OSVRFiles| % {Join-Path $OSVRDir "$_"}
    Remove-Item $OSVRPaths

    Write-Host "Removing extra dirs from OSVR-Core-Release"
    $OSVRPaths = $OSVRDirs| % {Join-Path $OSVRDir "$_"}
    Remove-Item -Path $OSVRPaths -Recurse -Force
}

function Move-OSVR-Tracker-View([string]$trackViewDir) {

    # Extra files to remove OSVR Tracker Viewer
    $OSVRFiles = 'osvr-ver.txt',
        'osvrClientKit.dll',
        'osvrClient.dll',
        'osvrCommon.dll',
        'osvrUtil.dll',
        'msvcp120.dll',
        'msvcr120.dll',
        'LICENSE',
        'CONTRIBUTING.md',
        'NOTICE',
        'README.md'

    # Rename license file
    $LicenseReadme = 'README-components-and-licenses.txt'
    $NewLicenseReadme = 'Tracker-Viewer-components-and-licenses.txt'

    $OSVRPaths = $OSVRFiles| % {Join-Path $trackViewDir "$_"}
    Remove-Item $OSVRPaths

    $LicensePath = $LicenseReadme| % {Join-Path $trackViewDir "$_"}
    Rename-Item -Path $LicensePath -NewName $NewLicenseReadme

    Remove-Item -Recurse -Path $trackViewDir -Include *.7z
}

function Move-RenderManager([string]$RMDir){

    # Extra files to remove OSVR RenderManager
    $ExtraFiles = 'osvrClientKit.dll',
        'osvrClient.dll',
        'osvrUtil.dll',
        'osvrCommon.dll',
        'AdjustableRenderingDelayD3D.exe',
        'AdjustableRenderingDelayOpenGL.exe',
        'LatencyTestD3DExample.exe',
        'RenderManagerD3DExample3D.exe',
        'RenderManagerD3DHeadSpaceExample.exe',
        'RenderManagerD3DPresentMakeDeviceExample3D.exe',
        'RenderManagerD3DPresentSideBySideExample.exe',
        'RenderManagerD3DTest2D.exe',
        'RenderManagerOpenGLCoreExample.exe',
        'RenderManagerOpenGLExample.exe',
        'RenderManagerOpenGLHeadSpaceExample.exe',
        'RenderManagerOpenGLPresentExample.exe',
        'RenderManagerOpenGLPresentSideBySideExample.exe',
        'SpinCubeD3D.exe',
        'SpinCubeOpenGL.exe'

    $ExtraDirs = 'include',
                 'lib'

    $binDir = "bin"
    $RMPath = Join-Path $RMDir $binDir
    $RMPaths = $ExtraFiles| % {Join-Path $RMPath "$_"}
    Remove-Item $RMPaths
    Remove-Item (Join-Path $RMDir 'osvr-ver.txt')

    Write-Host "Removing extra dirs from RenderManager-Release"
    $RMPaths = $ExtraDirs| % {Join-Path $RMDir "$_"}
    Remove-Item -Path $RMPaths -Recurse -Force

}

function Move-RenderManager-SDK([string]$RMDir){

    # Extra files to remove OSVR RenderManager
    $OSVRFiles = 'osvrClientKit.dll',
        'osvrClient.dll',
        'osvrUtil.dll',
        'osvrCommon.dll',
        'osvrClientKitd.dll',
        'osvrClientd.dll',
        'osvrUtild.dll',
        'osvrCommond.dll'

    $binDir = "bin"
    $RMPath = Join-Path $RMDir $binDir
    $RMPaths = $OSVRFiles| % {Join-Path $RMPath "$_"}
    Remove-Item $RMPaths
    Remove-Item (Join-Path $RMDir 'osvr-ver.txt')
}

function Move-OSVR-Central([string]$centralDir){
    # Extra files to remove OSVR-Central
    $OSVRFiles = 'osvrClient.dll',
        'osvrClientKit.dll',
        'osvrCommon.dll',
        'osvrPluginHost.dll',
        'osvrUtil.dll'

    $OSVRPaths = $OSVRFiles| % {Join-Path $centralDir "$_"}
    Remove-Item $OSVRPaths
}

function Rename-Dir([string]$oldName, [string]$newName){
    Rename-Item -path $oldName -newName $newName
}

# call the entry point
Main