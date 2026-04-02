@echo off
echo Refactoring template directives...
cd /d "d:\Users\Khedr\src\khadem"

echo Replacing include_directive.dart...
move /y "lib\src\core\view\directives\include_directive_new.dart" "lib\src\core\view\directives\include_directive.dart"

echo Replacing layout_directive.dart...
move /y "lib\src\core\view\directives\layout_directive_new.dart" "lib\src\core\view\directives\layout_directive.dart"

echo Removing old security_exception.dart from view folder...
del "lib\src\core\view\security_exception.dart"

echo Done!
echo.
echo Files modified:
echo - lib\src\core\view\directives\include_directive.dart (cleaned up)
echo - lib\src\core\view\directives\layout_directive.dart (cleaned up)
echo.
echo Files created:
echo - lib\src\support\exceptions\security_exception.dart (proper location)
echo - lib\src\support\utils\path_validator.dart (shared utility)
echo.
echo Files removed:
echo - lib\src\core\view\security_exception.dart (moved to proper location)
echo.
pause
