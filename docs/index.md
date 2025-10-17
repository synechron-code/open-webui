# Nexus Chat v3 Documentation

Welcome to the Nexus Chat v3 technical documentation. This platform is a customized deployment of Open WebUI, delivering an enterprise-grade, self-hosted AI chat solution with advanced features for knowledge management, RAG (Retrieval-Augmented Generation), and multi-model support.

## What is Nexus Chat v3?

Nexus Chat v3 is an extensible, feature-rich, and user-friendly self-hosted AI platform designed to operate entirely offline. Built on the foundation of [Open WebUI](https://github.com/open-webui/open-webui), it supports various LLM runners like **Ollama** and **OpenAI-compatible APIs**, with a built-in inference engine for RAG, making it a powerful AI deployment solution for enterprise environments.

### Key Features

- **🤖 Multi-Model Support**: Seamlessly integrate with Ollama, OpenAI, Azure OpenAI, Anthropic, Google Gemini, and other LLM providers
- **📚 RAG Integration**: Built-in Retrieval-Augmented Generation with support for multiple vector databases (ChromaDB, Qdrant, Milvus, pgvector)
- **🔒 Enterprise Security**: SCIM 2.0 provisioning, LDAP integration, OAuth2, JWT authentication, and granular RBAC
- **🎨 Custom Branding**: Full Synechron branding integration with customizable logos, backgrounds, and themes
- **🔍 Web Search**: Integrated web search capabilities using SerpAPI and other providers
- **🛠️ Extensible Tools**: Python function calling, custom pipelines, and MCP (Model Context Protocol) support
- **📱 Responsive Design**: Progressive Web App (PWA) with seamless desktop and mobile experience
- **🌐 Offline Capable**: Designed to operate entirely offline with local LLM runners
- **🎤 Multimodal**: Voice/video calls, image generation, document processing (PDF, DOCX, PPTX, Excel)
- **📊 Collaborative**: Real-time collaboration with channels, shared workspaces, and collaborative notes

## Architecture Overview

### Technology Stack

**Frontend**:
- **SvelteKit** - Modern web framework with TypeScript
- **TipTap** - Rich text editing for notes and chat
- **Socket.IO** - Real-time communication
- **Yjs** - CRDT-based collaborative editing
- **Pyodide** - Python in browser for function execution

**Backend**:
- **FastAPI** - High-performance Python web framework
- **SQLAlchemy** - ORM with Alembic migrations
- **Redis** - Session management and caching
- **LangChain** - LLM orchestration framework
- **Sentence Transformers** - Embedding models
- **Multiple Vector DBs** - ChromaDB, Qdrant, Milvus, pgvector, Pinecone, Elasticsearch

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (SvelteKit)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Chat   │  │Workspace │  │Channels  │  │  Admin   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   API Gateway     │
                    │   (FastAPI)       │
                    └─────────┬─────────┘
                              │
    ┌─────────────────────────┼─────────────────────────┐
    │                         │                         │
┌───▼────┐            ┌───────▼────────┐       ┌───────▼──────┐
│  Auth  │            │  RAG Pipeline  │       │  Model Proxy │
│ (JWT,  │            │  (Retrieval,   │       │  (Ollama,    │
│ OAuth, │            │   Embedding,   │       │   OpenAI)    │
│ LDAP)  │            │   Reranking)   │       │              │
└────────┘            └────────────────┘       └──────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Vector Database  │
                    │  (ChromaDB, etc.) │
                    └───────────────────┘
```

## Quick Start

### Development

```bash
# Frontend
npm install
npm run dev              # Start dev server on port 3000

# Backend
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
./dev.sh                 # Start backend on port 8080
```

### Docker Deployment

```bash
# Quick start with Docker Compose
make install             # docker-compose up -d
make start               # Start existing containers
make stop                # Stop containers
```

### Environment Configuration

Key environment variables (see `.env.example`):

- `OLLAMA_BASE_URL` - Ollama API endpoint
- `OPENAI_API_KEY` - OpenAI API key (if using OpenAI)
- `WEBUI_SECRET_KEY` - Application secret key
- `DATABASE_URL` - Database connection string
- `REDIS_URL` - Redis connection for sessions

## Documentation Sections

### Nexus Chat v3 Specific

These documents cover Nexus Chat v3 customizations, merge processes, and deployment:

- **[Merge Guide & Overview](NEXUS-CHAT-v3.md)** - Comprehensive guide for merging upstream Open WebUI releases into Nexus Chat v3
- **[Customizations Reference](nexus-chat-v3-customizations-reference.md)** - Detailed reference of all Nexus Chat v3 customizations compared to upstream
- **[v0.6.34 Merge Reports](merge-v0.6.34-phase1-report.md)** - Phase-by-phase reports from the v0.6.34 merge process
  - [Phase 1 Report](merge-v0.6.34-phase1-report.md) - Initial conflict resolution
  - [Phase 2 Report](merge-v0.6.34-phase2-report.md) - Component-level merging
  - [Phase 3 Report](merge-v0.6.34-phase3-report.md) - Integration and testing
  - [Phase 4 Completion Report](merge-v0.6.34-phase4-completion-report.md) - Final verification
- **[Full Diff vs Upstream](nexus-chat-v3-vs-upstream-v0.6.34.diff)** - Complete diff showing all changes from upstream v0.6.34

### Open WebUI Upstream Documentation

Reference documentation from the upstream Open WebUI project:

- **[Apache Configuration](apache.md)** - Running Open WebUI behind Apache reverse proxy
- **[Contributing Guide](CONTRIBUTING.md)** - Guidelines for contributing to the project
- **[Security](SECURITY.md)** - Security policies, vulnerability reporting, and best practices
- **[Workflow](README.md)** - Development workflow and project processes

## Key Customizations

Nexus Chat v3 includes several important customizations:

### 🎨 Branding & Theming
- Custom Synechron and Nexus Chat logos and backgrounds
- Configurable branding via admin interface
- Dark mode support with branded assets
- Custom color schemes and styling

### 🔍 Enhanced Search
- SerpAPI integration for web search
- Customized retrieval utilities
- Enhanced document processing

### ⚙️ Configuration Management
- Extended configuration API
- Persistent configuration storage
- Branding configuration endpoints

### 🏗️ Infrastructure
- GitLab CI/CD pipeline
- Backstage service catalog integration
- MkDocs documentation site
- Automated merge helper scripts

### 🧩 Component Enhancements
- Enhanced function and toolkit editors
- Improved notes functionality
- UI/UX improvements throughout

## Dependencies

Nexus Chat v3 depends on several other Nexus ecosystem components:

- **nexuschat-terraform** - Infrastructure as Code for deployment
- **nexuschat-gitops** - GitOps configuration and deployments
- **azure-shared-services** - Shared Azure infrastructure
- **synechron-openai-support** - Azure OpenAI integration layer
- **nexus-shared-services** - Common services and utilities

## Development Resources

### Important Files

- `CLAUDE.md` - Guidance for AI-assisted development with Claude Code
- `catalog-info.yaml` - Backstage service catalog metadata
- `.gitlab-ci.yml` - CI/CD pipeline configuration
- `mkdocs.yml` - Documentation site configuration
- `nexus-chat-v3-customized-files.txt` - List of all customized files

### Testing

```bash
# Frontend tests
npm run test:frontend    # Vitest unit tests
npm run cy:open          # Cypress e2e tests

# Backend tests
cd backend
pytest                   # Run all tests
pytest -v                # Verbose output
```

### Linting & Formatting

```bash
# Frontend
npm run lint             # All linters
npm run format           # Prettier formatting

# Backend
npm run lint:backend     # Pylint
npm run format:backend   # Black formatting
```

## Support & Maintenance

### System Information

- **Type**: AI System
- **Lifecycle**: Production
- **Owner**: AI Team
- **System**: nexuschatv3

### Getting Help

For issues, questions, or contributions:

1. Review the [Merge Guide](NEXUS-CHAT-v3.md) for upstream update processes
2. Check the [Customizations Reference](nexus-chat-v3-customizations-reference.md) for implementation details
3. Review merge reports for lessons learned from previous updates
4. Consult the upstream [Security](SECURITY.md) documentation for security concerns

## Version Information

- **Current Version**: v0.6.34 (based on Open WebUI v0.6.34)
- **Upstream**: [Open WebUI](https://github.com/open-webui/open-webui)
- **Latest Merge**: v0.6.34 (2025-10-17)

---

**Note**: This documentation is for Nexus Chat v3, a customized deployment. For upstream Open WebUI documentation, visit [docs.openwebui.com](https://docs.openwebui.com/).
