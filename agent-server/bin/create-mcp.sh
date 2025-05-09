#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variable setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$PROJECT_ROOT/templates/mcp"
SERVERS_DIR="$PROJECT_ROOT/src/servers/mcp"

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling
handle_error() {
  log_error "$1"
  exit 1
}

# Print header
echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}      MCP Server Creator           ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# Check templates directory
if [ ! -d "$TEMPLATES_DIR" ]; then
  log_error "Templates directory does not exist. Please run setup first."
  exit 1
fi

# Check servers directory
if [ ! -d "$SERVERS_DIR" ]; then
  log_warning "Servers directory does not exist. Creating..."
  mkdir -p "$SERVERS_DIR" || handle_error "Failed to create servers directory"

  log_success "Servers directory created."
fi

# Get server name
echo ""
# Get server name
echo ""
read -p "Enter MCP server name (kebab-case recommended, e.g., my-awesome-mcp): " SERVER_NAME

# Validate server name format
validate_server_name() {
  local name="$1"
  if ! [[ "$name" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
    log_warning "Server name '$name' is not valid kebab-case."
    log_warning "Server name should start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
    return 1
  fi
  return 0
}

# Validate name
if [ -z "$SERVER_NAME" ]; then
  log_warning "No name provided. Using 'default-mcp'."
  SERVER_NAME="default-mcp"
else
  # Validate the format
  if ! validate_server_name "$SERVER_NAME"; then
    log_warning "Continuing with the provided name, but you may encounter issues."
  fi
fi

# Get server description
echo ""
read -p "Enter a description for your MCP server: " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"An MCP server for ${SERVER_NAME}"}

# Check if server already exists
if [ -d "$SERVERS_DIR/$SERVER_NAME" ]; then
  log_warning "Warning: Server '$SERVER_NAME' already exists. Overwrite? (y/N)"
  read -p "" overwrite
  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    log_info "Operation cancelled."
    exit 0
  fi
  # Remove existing directory
  rm -rf "${SERVERS_DIR:?}/${SERVER_NAME:?}"
fi

# Create server directory
mkdir -p "$SERVERS_DIR/$SERVER_NAME/src" || handle_error "Failed to create server directory"

# Variable transformation function
to_pascal_case() {
  echo "$1" | sed -E 's/(^|[-_])([a-z])/\U\2/g'
}

SERVER_NAME_PASCAL=$(to_pascal_case "$SERVER_NAME")
CREATION_DATE=$(date +"%Y-%m-%d")

# Copy template directory structure
log_info "Copying template files..."
cp -r "$TEMPLATES_DIR"/* "$SERVERS_DIR/$SERVER_NAME/" || handle_error "Failed to copy template files"

# Copy hidden directories (like .vscode)
if [ -d "$TEMPLATES_DIR/.vscode" ]; then
  log_info "Copying .vscode directory..."
  cp -r "$TEMPLATES_DIR/.vscode" "$SERVERS_DIR/$SERVER_NAME/" || handle_error "Failed to copy .vscode directory"
fi

# Process all template files
find "$SERVERS_DIR/$SERVER_NAME" -name "*.template" | while IFS= read -r template_file; do
  output_file="${template_file%.template}"

  # Replace variables
  sed -e "s|{{SERVER_NAME}}|$SERVER_NAME|g" \
      -e "s/{{SERVER_NAME_PASCAL}}/$SERVER_NAME_PASCAL/g" \
      -e "s/{{CREATION_DATE}}/$CREATION_DATE/g" \
      -e "s/{{DESCRIPTION}}/$DESCRIPTION/g" \
      "$template_file" > "$output_file" || handle_error "Failed to process template file $template_file"

  # Remove template file
  rm "$template_file" || handle_error "Failed to remove template file $template_file"

  log_info "Created: ${output_file#$SERVERS_DIR/}"
done

echo ""
log_success "✅ MCP server successfully created!"
log_success "📁 Location: $SERVERS_DIR/$SERVER_NAME"
echo ""
log_info "Next steps:"
echo "  1. Edit the generated server files to add your tools and resources."
echo "  2. Build and run your server using the provided Makefile commands."
echo ""
