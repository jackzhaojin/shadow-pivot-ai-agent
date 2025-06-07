# GitHub Actions Workflow Testing Guide

This guide covers how to test the `deploy-logicapps.yml` workflow locally without creating duplicate shell scripts.

## Quick Start

```bash
# Basic validation
./quick-test.sh

# Comprehensive local testing
./test-local-workflow.sh

# Advanced testing with reporting
./test-workflow-advanced.sh
```

## Testing Approaches

### 1. Syntax and Structure Validation
```bash
# Validate YAML syntax only
./validate-workflow.sh

# Quick validation tests
./quick-test.sh
```

### 2. Local Workflow Execution
```bash
# Test with act (GitHub Actions runner)
./test-local-workflow.sh

# Manual act commands
act workflow_dispatch -W .github/workflows/deploy-logicapps.yml --dry-run
act workflow_dispatch -W .github/workflows/deploy-logicapps.yml --secret-file .act-secrets
```

### 3. Advanced Testing
```bash
# Full advanced testing suite
./test-workflow-advanced.sh

# Specific test types
./test-workflow-advanced.sh --security-only
./test-workflow-advanced.sh --performance-only
./test-workflow-advanced.sh --dependencies-only
```

## Testing Scenarios

### Environment Testing
- **Dev Environment**: Test with actual Azure dev resources
- **Mock Environment**: Test with fake credentials (default)
- **Production Simulation**: Test with production-like configuration

### Trigger Testing
```bash
# Test workflow_dispatch trigger (manual)
act workflow_dispatch

# Test workflow_run trigger (after infrastructure deployment)
act workflow_run --eventpath test-events/workflow-run-success.json
```

### Secret Management
```bash
# Create secrets file for testing
cat > .act-secrets << EOF
AZURE_CLIENT_ID=your-dev-client-id
AZURE_SUBSCRIPTION_ID=your-dev-subscription-id
AZURE_TENANT_ID=your-dev-tenant-id
EOF

# Test with different secret configurations
act workflow_dispatch --secret-file .act-secrets-dev
act workflow_dispatch --secret-file .act-secrets-staging
```

## Common Testing Commands

### Basic Workflow Validation
```bash
# Check workflow syntax
yq eval '.jobs' .github/workflows/deploy-logicapps.yml

# List all steps
act workflow_dispatch --list

# Dry run (no actual execution)
act workflow_dispatch --dry-run
```

### Platform Testing
```bash
# Test with specific runner image
act -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Test with minimal resources
act -P ubuntu-latest=node:16-alpine

# Test with custom platform
act --platform-file .act-platforms
```

### Debugging
```bash
# Verbose output
act workflow_dispatch --verbose

# Debug mode
act workflow_dispatch --verbose --debug

# Interactive mode (if supported)
act workflow_dispatch --interactive
```

## Testing Checklist

### Pre-Testing
- [ ] Docker is running
- [ ] act is installed and updated
- [ ] All Logic App JSON files exist
- [ ] Secrets configuration is ready

### During Testing
- [ ] YAML syntax validation passes
- [ ] All steps are recognized by act
- [ ] Secret references are properly configured
- [ ] Environment variables are set correctly

### Post-Testing
- [ ] Review test logs for warnings
- [ ] Check generated reports
- [ ] Validate against real Azure resources (dev environment)
- [ ] Update documentation if needed

## Troubleshooting

### Common Issues

1. **Docker not running**
   ```
   Solution: Start Docker Desktop or Docker daemon
   ```

2. **act not found**
   ```
   Solution: Install act via winget, brew, or download binary
   ```

3. **Workflow syntax errors**
   ```
   Solution: Use ./validate-workflow.sh to identify issues
   ```

4. **Missing secrets**
   ```
   Solution: Create .act-secrets file with required values
   ```

5. **Platform compatibility**
   ```
   Solution: Use appropriate runner image or update .actrc
   ```

### Debug Commands
```bash
# Check act configuration
act --help

# List available events
act --list

# Show workflow graph
act workflow_dispatch --graph

# Test with different verbosity
act workflow_dispatch -v
act workflow_dispatch --debug
```

## Integration with CI/CD

### Development Workflow
1. Edit workflow file
2. Run `./quick-test.sh` for quick validation
3. Run `./test-local-workflow.sh` for full local testing
4. Commit and test in GitHub Actions
5. Deploy to dev environment

### Automation
```bash
# Add to pre-commit hook
#!/bin/bash
./quick-test.sh && echo "✅ Workflow tests passed"

# Add to VS Code tasks.json
{
  "label": "Test Workflow",
  "type": "shell",
  "command": "./test-local-workflow.sh",
  "group": "test"
}
```

## Best Practices

1. **Test Early and Often**: Run validation after every workflow change
2. **Use Version Control**: Track changes to testing scripts
3. **Environment Isolation**: Always test with dev/staging resources first
4. **Document Changes**: Update this guide when adding new testing capabilities
5. **Monitor Performance**: Track workflow execution time and resource usage
6. **Security First**: Never commit real secrets, use environment-specific secret files

## Resources

- [act Documentation](https://github.com/nektos/act)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure CLI in GitHub Actions](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Logic Apps Deployment](https://docs.microsoft.com/en-us/azure/logic-apps/)
