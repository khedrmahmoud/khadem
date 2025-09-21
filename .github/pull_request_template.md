# Pull Request

## 📋 Description

<!-- Provide a clear and concise description of what this PR does -->
<!-- Example: "Adds JWT authentication middleware to secure API endpoints" -->

## 🔗 Related Issue

<!-- Link to the issue this PR addresses -->
<!-- Use "Fixes #123" or "Closes #123" to automatically close the issue -->
Fixes #(issue number)

## 🚀 Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 🔧 Code refactoring (no functional changes)
- [ ] ⚡ Performance improvement
- [ ] 🧪 Test addition or improvement
- [ ] 🏗️ Build/CI changes
- [ ] 🔒 Security enhancement
- [ ] 📦 Dependency update

## 🧪 Testing

<!-- Describe the tests you ran to verify your changes -->

- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] All new and existing unit tests pass locally with my changes
- [ ] I have tested this change manually
- [ ] I have tested this change with different Dart SDK versions (if applicable)

### Test Coverage
<!-- Describe what you tested -->
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing
- [ ] Performance testing (if applicable)
- [ ] Cross-platform testing (Windows/macOS/Linux)

### Test Commands Used
<!-- Include the commands you used to run tests -->
```bash
# Example:
dart test
dart test --coverage=coverage
dart analyze
```

## 📝 Checklist

<!-- Mark completed items with an "x" -->

### Code Quality
- [ ] My code follows the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- [ ] I have run `dart format .` on my code
- [ ] I have run `dart analyze` and fixed all issues
- [ ] My code has proper documentation/comments
- [ ] I have removed any debug code or console logs
- [ ] Code follows Khadem framework conventions

### Framework-Specific
- [ ] No breaking changes to public APIs (if applicable)
- [ ] Service providers are properly registered (if added)
- [ ] Middleware follows the correct interface (if added)
- [ ] Database migrations include proper rollback (if applicable)
- [ ] CLI commands follow established patterns (if added)

### Documentation
- [ ] I have updated the documentation if needed
- [ ] I have updated examples if my changes affect usage
- [ ] I have updated the CHANGELOG.md with the change
- [ ] README.md updated if new features added
- [ ] API documentation updated for public APIs

### Testing
- [ ] I have added tests for my changes
- [ ] All existing tests still pass
- [ ] My changes don't break existing functionality
- [ ] Edge cases are covered in tests

## 🔄 Breaking Changes

<!-- If this PR introduces breaking changes, describe them here -->

**Does this PR introduce breaking changes?**
- [ ] Yes
- [ ] No

<!-- If yes, describe the breaking changes and provide migration guide -->

### Migration Guide
<!-- For breaking changes, provide step-by-step migration instructions -->
<!-- Example:
1. Update your service provider registration in `config/app.dart`
2. Change method calls from `oldMethod()` to `newMethod()`
3. Update your middleware configuration
-->

## 🔒 Security Considerations

<!-- If this PR involves security-related changes -->
- [ ] Security impact assessed
- [ ] No sensitive data exposure
- [ ] Input validation added/updated
- [ ] Authentication/authorization properly handled

## ⚡ Performance Impact

<!-- Describe any performance implications -->
- [ ] Performance impact assessed
- [ ] Memory usage optimized
- [ ] No significant performance regression
- [ ] Benchmarks added/updated (if applicable)

## 📊 API Changes

<!-- If this PR changes any APIs -->
- [ ] Public API changes documented
- [ ] Backward compatibility maintained (if applicable)
- [ ] API versioning considered

### API Changes Summary
<!-- List any API changes -->
<!-- Example:
- Added: `UserService.authenticate(String token)`
- Changed: `Middleware.handle()` now returns `Future<Response>`
- Removed: `DatabaseConnection.close()` (use `dispose()` instead)
-->

## 🗄️ Database Changes

<!-- If this PR includes database changes -->
- [ ] Database migrations included
- [ ] Rollback migration provided
- [ ] Schema changes documented
- [ ] Data migration tested

## 💻 Code Examples

<!-- If applicable, add code examples demonstrating the changes -->
<!-- For new features, API usage examples, or breaking changes -->

### Usage Examples
<!-- Provide code examples showing how to use the new functionality -->
```dart
// Example usage of the new feature
// Replace with actual code examples
```

### API Documentation
<!-- If this PR adds or changes APIs, provide documentation -->
```dart
// API examples
// class NewService {
//   Future<Response> newMethod(String param) async {
//     // implementation
//   }
// }
```

## 🤔 Additional Context

<!-- Add any additional context, concerns, or questions here -->
<!-- Include links to relevant discussions, designs, or external resources -->

## 📋 Reviewer Notes

<!-- Any specific areas you'd like reviewers to focus on -->
<!-- Example: "Please pay special attention to the error handling in the auth middleware" -->

---

## ✅ Pre-Merge Checklist

<!-- For maintainers/reviewers -->
- [ ] Code review completed
- [ ] Tests pass in CI
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Breaking changes communicated (if any)
- [ ] Security review completed (if applicable)

---

**By submitting this pull request, I confirm that my contribution is made under the terms of the Apache License 2.0.**