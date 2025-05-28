# Document Management System API

A Flask-based backend service for document management operations, providing secure upload, listing, and deletion capabilities.

## Features

- 📁 Document upload with validation (size and type)
- 📋 Document listing with filtering options
- 🗑️ Secure document deletion
- 🔐 JWT authentication
- 📊 API access logging
- 👤 Admin functionalities

## Tech Stack

- **Framework**: Flask
- **Database**: MySQL
- **Authentication**: JWT via Flask-JWT-Extended
- **Storage**: File system-based document storage

## Installation

1. Clone the repository
2. Install dependencies: `pip install -r requirements.txt`
3. Configure database in `.env` file
4. Run migrations: `flask db upgrade`

## Usage

1. Start the server: `flask run`
2. Access API at `http://localhost:5000`
3. Use JWT token in Authorization header for protected routes

## API Endpoints

- `POST /api/auth/login` - Get authentication token
- `GET /api/documents` - List all documents
- `POST /api/documents` - Upload new document
- `DELETE /api/documents/<id>` - Delete document
