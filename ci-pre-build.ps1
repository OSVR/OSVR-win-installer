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

    Write-Host "Renaming RenderManager folders"
    Rename-Dir "RenderManager\BIT=32,label=windows" "x86"
    Rename-Dir "RenderManager\BIT=64,label=windows" "x64"

    Write-Host "Renaming OSVR-Core folders"
    Rename-Dir "OSVR-Core\BIT=32" "x86"
    Rename-Dir "OSVR-Core\BIT=64" "x64"

    Write-Host "Renaming OSVR-Central folders"
    Rename-Dir "OSVR-Central\BIT=32,VS=12,host=windows" "x86" 
    Rename-Dir "OSVR-Central\BIT=64,VS=12,host=windows" "x64" 

    Write-Host "Renaming OSVR-Tracker-Viewer folders"
    Rename-Dir "OSVR-Tracker-Viewer\BIT=32,label=windows" "x86" 
    Rename-Dir "OSVR-Tracker-Viewer\BIT=64,label=windows" "x64" 

    Write-Host "Moving 32 bit RenderManager contents up one dir"
    MoveUpOneDir("RenderManager\x86\install")
    Write-Host "Moving 64 bit RenderManager contents up one dir"
    MoveUpOneDir("RenderManager\x64\install")

    Write-Host "Moving 32 bit OSVR-Central contents up one dir"
    MoveUpOneDir("OSVR-Central\x86\bin")
    Write-Host "Moving 64 bit OSVR-Central contents up one dir"
    MoveUpOneDir("OSVR-Central\x64\bin")

    Write-Host "Moving 32 bit OSVR-Core contents up one dir"
    MoveUpOneDir("OSVR-Core\x86\install")
    Write-Host "Moving 64 bit OSVR-Core contents up one dir"
    MoveUpOneDir("OSVR-Core\x64\install")

    Write-Host "Moving OSVR-Config contents up one dir"
    MoveUpOneDir("OSVR-Config\artifacts")

    Write-Host "Removing extra files from OSVR-Central"
    Move-OSVR-Central

    Write-Host "Removing extra files from OSVR Tracker Viewer"
    Move-OSVR-Tracker-View

    Write-Host "Removing extra files from RenderManager"
    Move-RenderManager

    Write-Host "ci-build complete!"
}

function MoveUpOneDir([string]$dirPath){
    $files = get-childitem -path . -filter $dirPath
        foreach ($file in $files) {
            $subFiles = get-childitem -path $file.FullName
            foreach ($subFile in $subFiles) {
                $tempName = $file.Parent.FullName + "\" + $subFile.Name + '-foo'
                $newName = $file.Parent.FullName + "\" + $subFile.Name
                #output for testing
                #write-host "Old Location: " $subFile.FullName
                #write-host "New Location:" $newName

                write-host "Moving: " + $subFile
                move-item -path $subFile.FullName -dest $tempName
                move-item -path $tempName -dest $newName
            }
        }
    write-host "Removing empty dir" : $file.FullName
    remove-item -path $file.FullName
}

function Move-OSVR-Core() {
    # Extra files to remove OSVR Core
    $OSVRFiles = 'NOTICE'

    $serverDir = "OSVR-Server"
    $OSVRPaths = $OSVRFiles| % {Join-Path $serverDir "$_"}
    Remove-Item $OSVRPaths
}

function Move-OSVR-Tracker-View() {
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

    $trackViewDir = "OSVR-Tracker-Viewer"

    $OSVRPaths = $OSVRFiles| % {Join-Path $trackViewDir "$_"}
    Remove-Item $OSVRPaths

    $LicensePath = $LicenseReadme| % {Join-Path $trackViewDir "$_"}
    Rename-Item -Path $LicensePath -NewName $NewLicenseReadme

    Remove-Item -Recurse -Path $trackViewDir -Include *.7z
}

function Move-RenderManager(){

    # Extra files to remove OSVR RenderManager
    $OSVRFiles = 'osvrClientKit.dll',
        'osvrClient.dll',
        'osvrUtil.dll',
        'osvrCommon.dll'

    $RMDir = "RenderManager"
    $binDir = "bin"
    $RMPath = Join-Path $RMDir $binDir
    $RMPaths = $OSVRFiles| % {Join-Path $RMPath "$_"}
    Remove-Item $RMPaths


    if($buildType.compareTo("CLIENT") -eq 0)
    {
        Write-Host "Removing additional files from RenderManager for client build"
        #Extra files to remove for client build
        $RMFiles = 'AdjustableRenderingDelayD3D.exe',
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
        $RMPaths = $RMFiles| % {Join-Path $RMPath "$_"}
        Remove-Item $RMPaths
    }
}

function Move-OSVR-Central(){
    # Extra files to remove OSVR-Central
    $OSVRFiles = 'osvrClient.dll',
        'osvrClientKit.dll',
        'osvrCommon.dll',
        'osvrPluginHost.dll',
        'osvrUtil.dll'

    $centralDir = "OSVR-Central"

    $OSVRPaths = $OSVRFiles| % {Join-Path $centralDir "$_"}
    Remove-Item $OSVRPaths
}

function Rename-Dir([string]$oldName, [string]$newName){
    Rename-Item -path $oldName -newName $newName
}

# call the entry point
Main