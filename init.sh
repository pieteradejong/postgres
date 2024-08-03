#!/bin/bash

# Create a Python virtual environment
echo "Creating new virtual environment..."
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements without using cache
echo "Installing requirements..."
pip install --no-cache-dir -r requirements.txt

# Deactivate the virtual environment
deactivate

echo -e "\033[0;32mSetup complete. Remember to activate the virtual environment with: source venv/bin/activate\033[0m"