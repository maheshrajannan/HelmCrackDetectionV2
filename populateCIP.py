# DEPRECATED — do not use in deploys (issue-62).
#
# This script mutated masterChart/charts/pv-chart/values.yaml on disk, which
# dirtied the git tree (the committed `nfsCIP: 34.118.233.237` was its residue)
# and coupled deploys to a writable checkout.
#
# Replaced by inline injection at deploy time:
#   NFS_CIP=$(kubectl get svc nfs-server-svc-cip -o jsonpath='{.spec.clusterIP}')
#   helm upgrade --install master-chart ./masterChart --set pv-chart.nfsCIP="$NFS_CIP"
# or the preferred ansible/deploy-master-chart.yml playbook.
#
# Kept for reference only; no longer called by any workflow or script.

import yaml
import subprocess

# Run the kubectl command to get the clusterIP
cluster_ip_command = "kubectl get svc nfs-server-svc-cip -ojsonpath='{.spec.clusterIP}'"
cluster_ip = subprocess.check_output(cluster_ip_command, shell=True, text=True).strip()

# Load the YAML data from the values.yaml file in the Helm chart directory
values_yaml_path = "masterChart/charts/pv-chart/values.yaml"

with open(values_yaml_path, 'r+') as file:
    data = yaml.safe_load(file)
    
    # Update the nfsCIP IP address
    data['nfsCIP'] = cluster_ip
    
    # Go back to the beginning of the file and truncate it
    file.seek(0)
    file.truncate()
    
    # Write the modified YAML back to the same values.yaml file
    yaml.dump(data, file, default_flow_style=False)

print("Modified values.yaml written back to the Helm chart directory")
