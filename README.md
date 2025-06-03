# Document Management System (DMS)

A full-stack document management solution with a Python Flask backend and Flutter web frontend for administrative operations.

## Architecture

### Backend (Python Flask)
- **Framework**: Flask with JWT authentication
- **Database**: MySQL with connection pooling
- **Storage**: Local filesystem with UUID-based naming
- **Security**: bcrypt password hashing, JWT tokens

### Frontend (Flutter Web)
- **Framework**: Flutter 3.5.3+ with Material Design
- **Architecture**: Generic component system for CRUD operations
- **Authentication**: JWT-based with SharedPreferences storage
- **UI**: Responsive admin dashboard with pagination and search

## Features

### Document Operations
- Upload files with metadata validation (16MB limit)
- Organize files in date-based directory structure (YYYY/MM/DD)
- List, view, and delete documents
- File type and size validation

### Admin Dashboard
- User management and authentication
- Document lifecycle administration
- System configuration management
- Access logging and audit trails
- Document master data configuration

### Security
- JWT token authentication
- Password encryption with bcrypt
- Input validation and sanitization
- Secure file handling with UUID naming

## Quick Start

### Backend Setup
```bash
cd dms_backend
pip install -r requirements.txt
python main.py
```

### Frontend Setup
```bash
cd dms_frontend
flutter pub get
flutter run -d web
```

## API Endpoints

**Authentication**
- `POST /auth/login` - User login

**Documents**
- `POST /api/document/upload` - Upload files
- `POST /api/document/list` - List documents
- `DELETE /api/document/delete` - Remove documents

**Admin**
- User, document, config, and log management endpoints

## Tech Stack

**Backend**: Flask, MySQL, JWT, bcrypt, python-dotenv
**Frontend**: Flutter, Dart, HTTP, SharedPreferences, Material Design

Built for scalable document management with comprehensive administrative controls.