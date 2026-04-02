@echo off
echo ========================================
echo Batch 4 Complete - Merging to Dev
echo ========================================
echo.

cd /d "d:\Users\Khedr\src\khadem"

echo Switching to dev branch...
git checkout dev
if errorlevel 1 (
    echo ERROR: Failed to checkout dev
    pause
    exit /b 1
)
echo.

echo Commits to merge:
git log dev..security/template-path-traversal --oneline
echo.

echo Merging security/template-path-traversal into dev...
git merge security/template-path-traversal --no-ff -m "Merge branch 'security/template-path-traversal' into dev"
if errorlevel 1 (
    echo ERROR: Merge failed
    pause
    exit /b 1
)
echo SUCCESS: Merged!
echo.

echo Deleting security/template-path-traversal branch...
git branch -d security/template-path-traversal
echo.

echo ========================================
echo SUCCESS! Ready for Batch 5
echo ========================================
echo.
echo Recent commits:
git log --oneline -6
echo.
pause
