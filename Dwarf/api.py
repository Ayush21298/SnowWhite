from flask import Flask, request, render_template, redirect, url_for

app = Flask(__name__)

@app.route('/')
def index():
    # Read the contents of the variables.txt file
    with open('variables.txt', 'r') as file:
        content = file.read()

    # Extract the current values of the variables
    import re
    src_ip = re.search(r'src_ip="([^"]*)"', content).group(1)
    dst_ip = re.search(r'dst_ip="([^"]*)"', content).group(1)
    src_port = re.search(r'src_port="([^"]*)"', content).group(1)
    dst_port = re.search(r'dst_port="([^"]*)"', content).group(1)
    proto = re.search(r'proto="([^"]*)"', content).group(1)
    iface = re.search(r'iface="([^"]*)"', content).group(1)
    dst_iface = re.search(r'dst_iface="([^"]*)"', content).group(1)

    # Render the HTML template and pass the variables
    return render_template('index.html', src_ip=src_ip, dst_ip=dst_ip,
                           src_port=src_port, dst_port=dst_port, proto=proto,
                           iface=iface, dst_iface=dst_iface)


@app.route('/get_variables', methods=['GET'])
def get_variables():
    # Read the contents of the variables.txt file
    with open('variables.txt', 'r') as file:
        content = file.read()

    return content

@app.route('/update_variables', methods=['POST'])
def update_variables():
    src_ip = request.form.get('src_ip')
    dst_ip = request.form.get('dst_ip')
    src_port = request.form.get('src_port')
    dst_port = request.form.get('dst_port')
    proto = request.form.get('proto')
    iface = request.form.get('iface')
    dst_iface = request.form.get('dst_iface')

    # Update the variables in the text file
    with open('variables.txt', 'w') as file:
        file.write(f'src_ip="{src_ip}"\n')
        file.write(f'dst_ip="{dst_ip}"\n')
        file.write(f'src_port="{src_port}"\n')
        file.write(f'dst_port="{dst_port}"\n')
        file.write(f'proto="{proto}"\n')
        file.write(f'iface="{iface}"\n')
        file.write(f'dst_iface="{dst_iface}"\n')

    # Redirect back to the index page with updated variables
    return redirect(url_for('index', status='Variables updated successfully!', 
                            src_ip=src_ip, dst_ip=dst_ip, src_port=src_port, 
                            dst_port=dst_port, proto=proto, iface=iface, 
                            dst_iface=dst_iface))

if __name__ == '__main__':
    app.run(host="::",port=8082)
