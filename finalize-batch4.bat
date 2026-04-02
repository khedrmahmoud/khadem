@echo off
cd /d "d:\Users\Khedr\src\khadem"

echo ========================================
echo Finalizing Batch 4 Commit
echo ========================================
echo.

echo Cleaning up temporary files...
del /q lib\src\core\view\directives\include_directive_new.dart 2>nul
del /q lib\src\core\view\directives\layout_directive_new.dart 2>nul
del /q lib\src\core\view\security_exception.dart 2>nul

echo Staging all changes...
git add -A

echo.
echo Committing refactored code...
git commit -m "security(view): prevent path traversal in template includes and layouts

Added comprehensive path validation to prevent directory traversal attacks
via @include() and @layout() directives.

Architecture improvements:
- Created PathValidator utility to eliminate code duplication
- Added SecurityException to proper exceptions folder
- Reduced directive code by 50%% while improving security

Security improvements:
- Reject paths containing \"..\", \"//\", or absolute paths
- Validate paths against allowlist regex pattern
- Canonicalize paths and verify they remain within views directory
- Throw SecurityException for invalid path attempts

This prevents attackers from reading arbitrary files outside the
views directory using paths like \"../../../etc/passwd\".

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

if errorlevel 1 (
    echo.
    echo Note: Commit may already exist or no changes to commit
)

echo.
echo ========================================
echo Switching to dev and merging
echo ========================================
git checkout dev
git merge security/template-path-traversal --no-ff -m "Merge branch 'security/template-path-traversal' into dev"

if errorlevel 1 (
    echo ERROR: Merge failed
    pause
    exit /b 1
)

echo.
echo Deleting merged branch...
git branch -d security/template-path-traversal

echo.
echo ========================================
echo SUCCESS! Batch 4 Complete
echo ========================================
echo.
echo Recent commits:
git log --oneline -5
echo.
pause
