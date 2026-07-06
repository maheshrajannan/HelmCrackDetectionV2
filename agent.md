I said already current workflows and all the things working properly in master branch and DO-SSL branch also, so please don't change this branch strategy and all just make sure the 
below things are pre conditioned and working properly so don't change in below things

- Master branch has all the workflows in working conditions.
- Master branch has GCP code and whatever code changes come for GCP then we should make branch from based master and make changes.
-  DO-SSL branch is for DigitalOcean, so whatever changes will come in DO code then we should create sub branch based on DO-SSL.
- DO-SSL branch does not contains workflow of DO deployment  and cluster creation that all workflows only in the master and in that workflow I've logic for DO that DO code will run only in DO-SSL branch.(You can refer Mahesh-deploy-DOK.yaml)

