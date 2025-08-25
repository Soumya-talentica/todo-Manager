# Todo Manager

A full-stack todo application with React frontend, Node.js backend, and PostgreSQL database.

## 🚀 Features

- Create, read, update, and delete todos
- Mark todos as completed
- Responsive React frontend
- RESTful Node.js API
- PostgreSQL database with Sequelize ORM
- Docker containerization
- Automated CI/CD pipeline

## 🏗️ Architecture

```
├── frontend/          # React application
├── backend/           # Node.js Express API
├── db/               # Database initialization scripts
├── .github/workflows/ # CI/CD workflows
└── docker-compose.yml # Multi-container setup
```

## 🛠️ Prerequisites

- Node.js 20.x
- Docker & Docker Compose
- Git

## 📦 Installation

### 1. Clone the repository
```bash
git clone <your-repo-url>
cd todo-Manager
```

### 2. Install dependencies
```bash
# Frontend dependencies
cd frontend
npm install

# Backend dependencies
cd ../backend
npm install
```

### 3. Environment setup
Create `.env` files in both frontend and backend directories if needed.

## 🚀 Development

### Start development servers
```bash
# Terminal 1: Start backend
cd backend
npm run dev

# Terminal 2: Start frontend
cd frontend
npm start

# Terminal 3: Start database
docker-compose up db
```

### Run tests
```bash
# Frontend tests
cd frontend
npm test

# Backend tests
cd backend
npm test
```

### Run linting
```bash
# Frontend lint
cd frontend
npm run lint

# Backend lint
cd backend
npm run lint
```

## 🐳 Docker Deployment

### Build and run with Docker Compose
```bash
docker-compose up --build
```

### Access the application
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000
- Database: localhost:5432

## 📈 CI/CD Health Monitor

Backend endpoints:
- `GET /api/metrics/summary`
- `GET /api/metrics/trends?windowDays=7`
- `GET /api/runs/recent?limit=50`
- `POST /webhook/github` (expects `workflow_run` events)
- `POST /api/alerts/test`

Frontend routes:
- `/` — To-Do app
- `/monitor` — CI/CD Health dashboard

Environment:
- `GITHUB_OWNER`, `GITHUB_REPO`, `GITHUB_TOKEN`
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_SECURE`
- `ALERT_FROM`, `ALERT_TO`
- `GITHUB_WEBHOOK_SECRET` (optional)
- `POLL_ENABLED`, `POLL_INTERVAL_MS`, `POLL_PER_PAGE`, `LOOKBACK_DAYS`

Runbook:
- Health: `curl http://localhost:5000/health`
- Summary: `curl http://localhost:5000/api/metrics/summary`
- Test email: `curl -X POST http://localhost:5000/api/alerts/test`
- GitHub webhook:
  - URL: `http://<host>/webhook/github`
  - Content type: `application/json`
  - Secret: `GITHUB_WEBHOOK_SECRET`
  - Events: `workflow runs`

## 🔄 CI/CD Pipeline

### CI Workflow (`.github/workflows/ci.yml`)
- Triggers on push to main branch and pull requests
- Runs linting and tests for both frontend and backend
- Builds Docker images
- Sends notifications to MS Teams

### CD Workflow (`.github/workflows/cd.yml`)
- Triggers on push to main branch
- Builds and pushes Docker images to GitHub Container Registry
- Deploys to target server via SSH
- Verifies deployment health
- Sends notifications to MS Teams

## 🔧 Configuration

### Required GitHub Secrets
- `MS_TEAMS_WEBHOOK`: Webhook URL for MS Teams notifications
- `REGISTRY_USER`: GitHub username for container registry
- `REGISTRY_TOKEN`: GitHub personal access token
- `DEPLOY_KEY`: Base64-encoded SSH private key
- `DEPLOY_HOST`: Target server IP/hostname
- `DEPLOY_USER`: SSH username for deployment

### Environment Variables
- `DB_HOST`: Database host (default: db)
- `DB_USER`: Database username (default: todo)
- `DB_PASSWORD`: Database password (default: todo)
- `DB_NAME`: Database name (default: tododb)
- `DB_PORT`: Database port (default: 5432)
- `PORT`: Backend port (default: 5000)

## 🧪 Testing

### Frontend Tests
- Uses Jest and React Testing Library
- Run with: `npm test`
- Coverage reports available

### Backend Tests
- Uses Jest and Supertest
- Run with: `npm test`
- Includes health endpoint testing

## 📊 Health Checks

- **Backend**: `GET /health` - Returns "OK" if service is running
- **Frontend**: Health check via nginx
- **Database**: PostgreSQL readiness check

## 🚨 Troubleshooting

### Common Issues

1. **CI Pipeline Fails on Lint**
   - Ensure all dependencies are installed: `npm install`
   - Run lint locally: `npm run lint`

2. **Tests Fail**
   - Check test configuration in `jest.config.js`
   - Run tests locally: `npm test`

3. **Docker Build Fails**
   - Ensure Docker is running
   - Check Dockerfile syntax
   - Verify build context

4. **Deployment Issues**
   - Verify SSH keys and permissions
   - Check target server connectivity
   - Ensure Docker is installed on target server

### Health Check Failures
- Verify services are running: `docker-compose ps`
- Check logs: `docker-compose logs [service-name]`
- Ensure health endpoints are accessible

## 📝 API Endpoints

- `GET /health` - Health check
- `GET /api/tasks` - Get all tasks
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
