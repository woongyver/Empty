<#
.SYNOPSIS
    Claude Code의 외부 편집기(Ctrl+G)용 EDITOR/VISUAL 환경변수를 설정한다.

.DESCRIPTION
    설치된 편집기를 자동으로 찾아 사용자 범위(User) 환경변수 EDITOR, VISUAL에 등록한다.
    편집기가 닫힐 때까지 대기하도록 편집기별 옵션(--wait 등)을 함께 지정한다.
    관리자 권한은 필요 없다.

.PARAMETER Editor
    사용할 편집기. Auto(기본값), VSCode, Cursor, NotepadPP, Notepad 중 하나.
    Auto는 VSCode > Cursor > NotepadPP > Notepad 순으로 먼저 찾은 편집기를 사용한다.

.PARAMETER Remove
    등록된 EDITOR, VISUAL 환경변수를 삭제한다.

.EXAMPLE
    .\Set-ClaudeEditor.ps1
    .\Set-ClaudeEditor.ps1 -Editor NotepadPP
    .\Set-ClaudeEditor.ps1 -Remove
#>
[CmdletBinding()]
param(
    [ValidateSet('Auto', 'VSCode', 'Cursor', 'NotepadPP', 'Notepad')]
    [string]$Editor = 'Auto',

    [switch]$Remove
)

$ErrorActionPreference = 'Stop'
$VarNames = @('EDITOR', 'VISUAL')

# 사용자 범위와 현재 세션에 동시에 반영한다.
function Set-EditorVariable([string]$Value) {
    foreach ($name in $VarNames) {
        [Environment]::SetEnvironmentVariable($name, $Value, 'User')
        Set-Item -Path "Env:$name" -Value $Value -ErrorAction SilentlyContinue
    }
}

function Remove-EditorVariable {
    foreach ($name in $VarNames) {
        [Environment]::SetEnvironmentVariable($name, $null, 'User')
        Remove-Item -Path "Env:$name" -ErrorAction SilentlyContinue
    }
}

# 경로에 공백이 있으면 따옴표로 감싼다.
function Format-Exe([string]$Path) {
    if ($Path -match '\s') { return "`"$Path`"" }
    return $Path
}

# 편집기별 실행 명령을 찾는다. 찾지 못하면 $null을 반환한다.
function Find-EditorCommand([string]$Name) {
    switch ($Name) {
        'VSCode' {
            # PATH에 code가 있으면 그대로 사용한다.
            if (Get-Command code -ErrorAction SilentlyContinue) { return 'code --wait' }
            $candidates = @(
                "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
                "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
            )
            foreach ($p in $candidates) {
                if (Test-Path $p) { return "$(Format-Exe $p) --wait" }
            }
        }
        'Cursor' {
            if (Get-Command cursor -ErrorAction SilentlyContinue) { return 'cursor --wait' }
            $p = "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin\cursor.cmd"
            if (Test-Path $p) { return "$(Format-Exe $p) --wait" }
        }
        'NotepadPP' {
            # -multiInst: 기존 창에 넘기지 않고 새 프로세스로 열어 닫힐 때까지 대기하게 한다.
            # -nosession: 이전 세션 파일을 함께 열지 않는다.
            $candidates = @(
                "$env:ProgramFiles\Notepad++\notepad++.exe",
                "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
            )
            foreach ($p in $candidates) {
                if ($p -and (Test-Path $p)) { return "$(Format-Exe $p) -multiInst -nosession -notabbar" }
            }
        }
        'Notepad' {
            return 'notepad'
        }
    }
    return $null
}

if ($Remove) {
    Remove-EditorVariable
    Write-Host 'EDITOR, VISUAL 환경변수를 삭제했다.' -ForegroundColor Yellow
    return
}

$order = if ($Editor -eq 'Auto') { @('VSCode', 'Cursor', 'NotepadPP', 'Notepad') } else { @($Editor) }

$selected = $null
$command = $null
foreach ($name in $order) {
    $command = Find-EditorCommand $name
    if ($command) { $selected = $name; break }
}

if (-not $command) {
    Write-Host "편집기 '$Editor'를 찾지 못했다. 설치 여부 또는 PATH를 확인해야 한다." -ForegroundColor Red
    exit 1
}

# 기존 값을 보여 준 뒤 덮어쓴다.
$previous = [Environment]::GetEnvironmentVariable('EDITOR', 'User')
if ($previous) { Write-Host "기존 EDITOR: $previous" -ForegroundColor DarkGray }

Set-EditorVariable $command

Write-Host ''
Write-Host "편집기: $selected" -ForegroundColor Green
Write-Host "EDITOR = $command" -ForegroundColor Green
Write-Host "VISUAL = $command" -ForegroundColor Green
Write-Host ''
Write-Host '적용 방법:'
Write-Host '  1. 열려 있는 터미널(Windows Terminal 등)을 모두 닫고 새로 연다.'
Write-Host '  2. claude 실행 후 입력창에서 Ctrl+G를 누른다.'
Write-Host '  3. 편집기에서 내용을 작성하고 저장한 뒤 창(탭)을 닫으면 입력창에 반영된다.'
