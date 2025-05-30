# Shadow Pivot AI Agent API Documentation

## Overview

The Shadow Pivot AI Agent is a multi-stage AI processing pipeline that takes user prompts and generates comprehensive responses through design, content creation, and review phases.

## Architecture Flow

```
HTTP Request → Entry Logic App → Design Queue → Design Logic App → Content Queue → Content Logic App → Review Queue → Review Logic App → Final Storage
```

## API Endpoints

### Entry Point

**POST** `https://<entry-logic-app-url>/triggers/manual/paths/invoke`

#### Request Body

```json
{
  "prompt": "Create a marketing campaign for a new eco-friendly water bottle",
  "userId": "user-123",
  "sessionId": "session-456",
  "priority": "high"
}
```

#### Response

```json
{
  "status": "accepted",
  "message": "AI agent task queued for processing",
  "taskId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "user-123",
  "sessionId": "session-456",
  "timestamp": "2025-05-29T22:00:00.000Z",
  "estimatedProcessingTime": "2-5 minutes"
}
```

## Testing Examples

### Basic Test

```bash
curl -X POST \
  "https://your-entry-logic-app.azurewebsites.net/api/triggers/manual/paths/invoke" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Design a modern logo for a tech startup",
    "userId": "test-user-001",
    "sessionId": "test-session-001"
  }'
```

### Marketing Campaign Test

```bash
curl -X POST \
  "https://your-entry-logic-app.azurewebsites.net/api/triggers/manual/paths/invoke" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a comprehensive marketing strategy for launching a new mobile app that helps people track their carbon footprint",
    "userId": "marketer-123",
    "sessionId": "campaign-session-001",
    "priority": "high"
  }'
```

### Content Creation Test

```bash
curl -X POST \
  "https://your-entry-logic-app.azurewebsites.net/api/triggers/manual/paths/invoke" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Write a technical blog post about the benefits of serverless architecture for startups",
    "userId": "content-writer-456",
    "sessionId": "blog-session-001"
  }'
```

## Queue Message Format

### Design Queue Message

```json
{
  "taskId": "550e8400-e29b-41d4-a716-446655440000",
  "prompt": "Original user prompt",
  "userId": "user-123",
  "sessionId": "session-456",
  "priority": "medium",
  "status": "queued",
  "stage": "entry",
  "timestamp": "2025-05-29T22:00:00.000Z",
  "nextStage": "design-generation"
}
```

### Content Queue Message

```json
{
  "taskId": "550e8400-e29b-41d4-a716-446655440000",
  "prompt": "Original user prompt",
  "userId": "user-123",
  "sessionId": "session-456",
  "designOutput": "Generated design specifications...",
  "stage": "content-generation",
  "timestamp": "2025-05-29T22:00:00.000Z"
}
```

### Review Queue Message

```json
{
  "taskId": "550e8400-e29b-41d4-a716-446655440000",
  "prompt": "Original user prompt",
  "userId": "user-123",
  "sessionId": "session-456",
  "designOutput": "Generated design specifications...",
  "contentOutput": "Generated content...",
  "stage": "review",
  "timestamp": "2025-05-29T22:00:00.000Z"
}
```

## Monitoring

### Queue Monitoring

Monitor queue lengths and processing times:

```bash
# Check queue message counts
az storage queue list --account-name shdwagentstorage
az storage message peek --queue-name design-gen-q --account-name shdwagentstorage
```

### Logic App Monitoring

View execution history in Azure Portal:
- Navigate to Logic Apps
- Select each workflow
- View "Runs history"
- Check for failed executions

## Error Handling

The system includes error handling at each stage:

1. **Entry Logic App**: Returns 500 status for processing failures
2. **Queue Processing**: Failed messages remain in queue for retry
3. **AI Generation**: HTTP timeouts and API errors are logged
4. **Final Storage**: Failed storage attempts are retried

## Security Considerations

1. **API Keys**: Store OpenAI API keys in Azure Key Vault
2. **Authentication**: Implement API key or OAuth for entry endpoint
3. **Network Security**: Use private endpoints for storage accounts
4. **Data Privacy**: Implement data retention policies for queues and storage

## Performance Optimization

1. **Parallel Processing**: Multiple Logic Apps can process queues simultaneously
2. **Queue Scaling**: Adjust polling frequency based on load
3. **AI Model Selection**: Use appropriate models for each stage (GPT-3.5 vs GPT-4)
4. **Caching**: Implement caching for repeated similar requests
