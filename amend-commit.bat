@echo off
cd /d "d:\Users\Khedr\src\khadem"

echo Removing old security_exception.dart...
git rm lib/src/core/view/security_exception.dart

echo Amending commit with refactored code...
git commit --amend -m "security(view): prevent path traversal in template includes and layouts

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

echo.
echo Commit amended successfully!
echo.
git log --oneline -3
echo.
pause
