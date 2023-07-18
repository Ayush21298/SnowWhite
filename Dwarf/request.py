import requests

# API endpoint URL
api_url = 'http://192.168.58.2:32221//update_variables'

# Parameters for the POST request
params = {
    'src_ip': '192.168.58.3',
    'dst_ip': '',
    'src_port': '',
    'dst_port': '',
    'proto': '1',
    'iface': 'eth0',
    'dst_iface': 'tun0'
}

# Send POST request to the API
response = requests.post(api_url, params=params)

# Check the response
if response.status_code == 200:
    print('Variables updated successfully!')
else:
    print('Error occurred:', response.text)
