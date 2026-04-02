@echo off
cd /d "d:\Users\Khedr\src\khadem"

echo Removing old security_exception.dart and amending commit...
git rm lib/src/core/view/security_exception.dart
git commit --amend --no-edit

echo.
echo Commit amended successfully!
echo.
echo Updated commit:
git show --stat HEAD
echo.
pause
