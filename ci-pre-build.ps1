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

    Write-Host "Removing extra files from OSVR Tracker Viewer"
    Move-OSVR-Tracker-View
    Write-Host "Removing extra files from RenderManager"
    Move-RenderManager

    Write-Host "ci-build complete!"
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
        'README.md',
        'README-components-and-licenses.txt'

    $trackViewDir = "OSVR-Tracker-Viewer"
    $OSVRPaths = $OSVRFiles| % {Join-Path $trackViewDir "$_"}
    Remove-Item $OSVRPaths

    Remove-Item -Recurse -Path $trackViewDir -Include *.7z
}

function Move-RenderManager(){

    # Extra files to remove OSVR Tracker Viewer
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
            'DirectModeDebugging.exe',
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

# call the entry point
Main