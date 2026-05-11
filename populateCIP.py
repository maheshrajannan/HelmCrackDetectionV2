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
