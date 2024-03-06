import os
import subprocess
import json
import socket


# Get the list of open ports
def get_open_ports ():
	result = subprocess.run(['netstat', '-tuln'], capture_output = True, text = True)
	print(result)
	open_ports = []
	for line in result.stdout.split('\n'):
		elements = line.split()  # Split the line into several elements
		if len(elements) >= 6:  # Check if line contains at least 6 elements
			if elements[0].startswith('tcp') or elements[0].startswith('udp'):
				ip_and_port = elements[3]
				# print(ip_and_port)
				if ':' in ip_and_port:
					port = ip_and_port.split(':')[-1]
					if not port.isnumeric():  # Verify the port is a number
						continue  # Not a number, move on to the next line
					# print(elements)
					protocol = 'tcp' if elements[0].startswith('tcp') else 'udp'
					port = int(port)
					service = get_service_name(port)  # Fetch the service name using function
					
					open_ports.append({
						"protocol": protocol,
						"port"    : port,
						"service" : service,
						})
	return open_ports

# Function to fetch service name
def get_service_name (port):
	try:
		service = socket.getservbyport(port)
	except Exception:
		service = 'unknown'
	return service


# Verify the existence and the format of the file
def verify_file_format_and_existence (filepath):
	if not os.path.isfile(filepath):  # Verify existence
		raise FileNotFoundError(f"The file {filepath} couldn't be found.")
	if not filepath.endswith('.json'): # Verify Type .json
		raise ValueError(f"The file {filepath} is not in a valid json format.")
	return True

# Load the list of reference ports from a JSON file
def load_baseline_ports (filepath):
	if verify_file_format_and_existence(filepath):
		with open('port_baseline.json', 'r') as file:
			baseline_ports = json.load(file)
	return baseline_ports


# Generate the JSON file indicating whether each port is in the baseline
def generate_port_json (open_ports, baseline_ports):
	baseline_ports_list = []
	for port_dict in baseline_ports:
		baseline_ports_list.append(port_dict["port"])
	
	for port_dict in open_ports:
		port_dict.update({"in_baseline": port_dict["port"] in baseline_ports_list})
	
	
	# baseline_ports_list = [port_dict["port"] for port_dict in baseline_ports]
	# [port_dict.update({"in_baseline": port_dict["port"] in baseline_ports_list}) for port_dict in open_ports]
	
	# for port_dict in open_ports:
	# 	print(f"Type of opened port {port_dict['port']}: {type(port_dict['port'])}")
	#
	# for port_dict in baseline_ports:
	# 	print(f"Type of baseline port {port_dict['port']}: {type(port_dict['port'])}")
	#
	with open('open_ports_baseline.json', 'w') as file:
		json.dump(open_ports, file, indent = 4)


# Function to read and print content of file
def print_json_file (file_name):
	with open(file_name, 'r') as file:
		data = json.load(file)
	print(json.dumps(data, indent = 4))

if __name__ == "__main__":
	open_ports = get_open_ports()
	filepath = 'port_baseline.json'
	baseline_ports = load_baseline_ports(filepath)
	generate_port_json(open_ports, baseline_ports)
	file_name = 'open_ports_baseline.json'
	print_json_file(file_name)
