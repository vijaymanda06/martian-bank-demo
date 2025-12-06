# Implementation Plan

- [x] 1. Set up test infrastructure
  - Install test dependencies for Python and Node.js services
  - Configure test runners (pytest, jest)
  - _Requirements: 1_

- [ ]* 1.1 Add smoke tests for transactions service
  - Create `tests/transactions/test_smoke.py`
  - Test module imports and basic instantiation
  - _Requirements: 1_

- [ ]* 1.2 Add smoke tests for loan service
  - Create `tests/loan/test_smoke.py`
  - Test module imports and basic instantiation
  - _Requirements: 1_

- [ ]* 1.3 Add smoke tests for customer-auth service
  - Create `customer-auth/__tests__/smoke.test.js`
  - Test health endpoint returns 200
  - Use jest and supertest
  - _Requirements: 1_

- [ ]* 1.4 Add smoke tests for atm-locator service
  - Create `atm-locator/__tests__/smoke.test.js`
  - Test health endpoint returns 200
  - Use jest and supertest
  - _Requirements: 1_

- [x] 2. Create GitHub Actions test workflow
  - Create `.github/workflows/test.yml`
  - Configure to run on pull requests
  - Execute pytest for Python services
  - Execute jest for Node.js services
  - Report test results
  - _Requirements: 2_

- [x] 3. Set up ArgoCD in EKS cluster
  - Create `argocd/install.yaml` with ArgoCD installation manifest
  - Document installation steps
  - _Requirements: 3_

- [x] 3.1 Create ArgoCD Application manifest
  - Create `argocd/application.yaml`
  - Configure to watch `martianbank/` Helm chart
  - Set automated sync policy
  - _Requirements: 3_

- [x] 4. Update CI pipeline for GitOps workflow
  - Modify `.github/workflows/deploy.yml`
  - Update deploy job to commit image tags to values.yaml
  - Remove direct `helm upgrade` command
  - Add git commit and push steps
  - _Requirements: 4_

- [x] 5. Update README documentation
  - Rewrite architecture section
  - Add Docker Compose local development instructions
  - Add testing instructions
  - Add ArgoCD deployment instructions
  - Remove outdated manual deployment references
  - _Requirements: 5_

- [ ] 6. Checkpoint - Verify everything works
  - Ensure all tests pass
  - Ask the user if questions arise
