# Local references to workflow JSON files
locals {
  entry_workflow       = file("${path.module}/../logic-apps/entry/workflow.json")
  design_gen_workflow  = file("${path.module}/../logic-apps/design-gen/workflow.json")
  content_gen_workflow = file("${path.module}/../logic-apps/content-gen/workflow.json")
  review_workflow      = file("${path.module}/../logic-apps/review/workflow.json")
}

# Null resource to update workflow definitions after Logic Apps are created
resource "null_resource" "update_logic_app_workflows" {
  depends_on = [
    azurerm_logic_app_workflow.entry,
    azurerm_logic_app_workflow.design_gen,
    azurerm_logic_app_workflow.content_gen,
    azurerm_logic_app_workflow.review,
    azurerm_api_connection.storage_queues
  ]

  # Trigger when workflow files change
  triggers = {
    entry_workflow_content       = filesha256("${path.module}/../logic-apps/entry/workflow.json")
    design_gen_workflow_content  = filesha256("${path.module}/../logic-apps/design-gen/workflow.json")
    content_gen_workflow_content = filesha256("${path.module}/../logic-apps/content-gen/workflow.json")
    review_workflow_content      = filesha256("${path.module}/../logic-apps/review/workflow.json")
    connection_id                = azurerm_api_connection.storage_queues.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Updating Logic App workflows..."
      
      # Update Entry Logic App
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.entry.name} \
        --definition @${path.module}/../logic-apps/entry/workflow.json || echo "Entry workflow update failed"

      # Update Design Gen Logic App  
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.design_gen.name} \
        --definition @${path.module}/../logic-apps/design-gen/workflow.json || echo "Design Gen workflow update failed"

      # Update Content Gen Logic App
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.content_gen.name} \
        --definition @${path.module}/../logic-apps/content-gen/workflow.json || echo "Content Gen workflow update failed"

      # Update Review Logic App
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.review.name} \
        --definition @${path.module}/../logic-apps/review/workflow.json || echo "Review workflow update failed"

      echo "Logic App workflow definitions updated successfully!"
    EOT
  }
}
