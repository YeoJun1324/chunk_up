#!/bin/bash

# Script to update import paths after chunk_up project reorganization
# This script updates all Dart imports to reflect the new file structure

echo "Starting import path updates for chunk_up project..."

# Define the import path mappings
declare -A import_mappings=(
    # Auth service
    ["core/services/auth_service"]="data/services/auth/auth_service"
    
    # Navigation service
    ["core/services/navigation_service"]="infrastructure/navigation/navigation_service"
    
    # Logging service
    ["core/services/logging_service"]="infrastructure/logging/logging_service"
    
    # Subscription service
    ["core/services/subscription_service"]="data/services/subscription/subscription_service"
    
    # Character services
    ["core/services/enhanced_character_service"]="domain/services/character/enhanced_character_service"
    ["core/services/character_service"]="domain/services/character/character_service"
    
    # API services
    ["core/services/api/unified_api_service"]="data/services/api/unified_api_service"
    ["core/services/api/openai_api_service"]="data/services/api/openai_api_service"
    ["core/services/api/groq_api_service"]="data/services/api/groq_api_service"
    ["core/services/api/anthropic_api_service"]="data/services/api/anthropic_api_service"
    ["core/services/api/google_api_service"]="data/services/api/google_api_service"
    ["core/services/api/cerebras_api_service"]="data/services/api/cerebras_api_service"
    ["core/services/api/gemini_api_service"]="data/services/api/gemini_api_service"
    ["core/services/api/api_factory"]="data/services/api/api_factory"
    
    # Storage services
    ["core/services/storage/storage_service"]="data/services/storage/storage_service"
    ["core/services/storage/hive_storage_service"]="data/services/storage/hive_storage_service"
    
    # Message services
    ["core/services/message_service"]="domain/services/message/message_service"
    
    # Other core services that might have moved
    ["core/services/"]="data/services/"
)

# Find all Dart files in the project (excluding build directories and packages)
find . -name "*.dart" -type f \
    -not -path "./build/*" \
    -not -path "./.dart_tool/*" \
    -not -path "./packages/*" \
    -not -path "./.pub-cache/*" | while read -r file; do
    
    echo "Processing: $file"
    
    # Create a temporary file for the updates
    temp_file=$(mktemp)
    cp "$file" "$temp_file"
    
    # Apply each import mapping
    for old_path in "${!import_mappings[@]}"; do
        new_path="${import_mappings[$old_path]}"
        
        # Update import statements
        # Handle various import formats:
        # import 'package:chunk_up/core/services/...'
        # import "package:chunk_up/core/services/..."
        # export 'package:chunk_up/core/services/...'
        # export "package:chunk_up/core/services/..."
        
        sed -i "s|import 'package:chunk_up/${old_path}|import 'package:chunk_up/${new_path}|g" "$temp_file"
        sed -i "s|import \"package:chunk_up/${old_path}|import \"package:chunk_up/${new_path}|g" "$temp_file"
        sed -i "s|export 'package:chunk_up/${old_path}|export 'package:chunk_up/${new_path}|g" "$temp_file"
        sed -i "s|export \"package:chunk_up/${old_path}|export \"package:chunk_up/${new_path}|g" "$temp_file"
        
        # Also handle relative imports if they exist
        # import '../core/services/...'
        # import '../../core/services/...'
        sed -i "s|import '\.\./core/services/${old_path#core/services/}|import '../${new_path}|g" "$temp_file"
        sed -i "s|import '\.\./\.\./core/services/${old_path#core/services/}|import '../../${new_path}|g" "$temp_file"
        sed -i "s|import \"\.\./core/services/${old_path#core/services/}|import \"../${new_path}|g" "$temp_file"
        sed -i "s|import \"\.\./\.\./core/services/${old_path#core/services/}|import \"../../${new_path}|g" "$temp_file"
    done
    
    # Check if the file was actually modified
    if ! cmp -s "$file" "$temp_file"; then
        # File was modified, copy it back
        cp "$temp_file" "$file"
        echo "  ✓ Updated imports in $file"
    else
        echo "  - No changes needed in $file"
    fi
    
    # Clean up temp file
    rm "$temp_file"
done

echo "Import path updates completed!"

# Optional: Run dart analyze to check for any import issues
echo ""
echo "Running dart analyze to check for import issues..."
dart analyze

echo ""
echo "Script completed. Please review the changes and run 'flutter pub get' if needed."