import tkinter as tk
from tkinter import messagebox
import os

# Path to the autostart file
AUTOSTART_FILE = "/home/examuser/.config/openbox/autostart"

# Function to extract the value inside quotes (removing special characters)
def extract_value(line, param):
    start = line.find(param) + len(param) + 1  # +1 to handle the space after the parameter
    value = line[start:].strip().split()[0]  # Get the value, ignore anything after the first space
    if value.startswith('"') and value.endswith('"'):
        value = value[1:-1]  # Remove surrounding quotes if they exist
    return value

# Function to load values from the autostart file (if exists)
def load_autostart_file():
    try:
        with open(AUTOSTART_FILE, 'r') as f:
            lines = f.readlines()
            config_data = {
                'server': '',
                'ebiuser': '',
                'ebipass': '',
                'domain': '',
                'app': ''
            }
            # Parse the autostart file content
            for line in lines:
                if '--serverURL' in line:
                    config_data['server'] = extract_value(line, '--serverURL')
                if '--userName' in line:
                    config_data['ebiuser'] = extract_value(line, '--userName')
                if '--password' in line:
                    config_data['ebipass'] = extract_value(line, '--password')
                if '--domainName' in line:
                    config_data['domain'] = extract_value(line, '--domainName')
                if '--applicationName' in line:
                    config_data['app'] = extract_value(line, '--applicationName')
            return config_data
    except FileNotFoundError:
        # Return empty values if the autostart file doesn't exist
        return {'server': '', 'ebiuser': '', 'ebipass': '', 'domain': '', 'app': ''}
    except Exception as e:
        messagebox.showerror("Error", f"Error loading autostart file: {e}")
        return None

# Function to save values to the autostart file
def save_autostart_file(server, ebiuser, ebipass, domain, app):
    try:
        # Ensure the Openbox directory exists
        os.makedirs(os.path.dirname(AUTOSTART_FILE), exist_ok=True)

        # Write the new content to the autostart file
        with open(AUTOSTART_FILE, 'w') as f:
            f.write(f"# Disable DPMS and prevent screen blanking\n")
            f.write(f"xset -dpms s off s noblank s noexpose &\n\n")
            f.write(f"# Set background color\n")
            f.write(f"xsetroot -solid '#7393B3' &\n\n")
            f.write(f"# Loop to keep vmware-view running minimized\n")
            f.write(f"while true; do\n")
            f.write(f'    vmware-view --serverURL "{server}" --useExisting --userName "{ebiuser}" '
                    f'--password "{ebipass}" --domainName "{domain}" --nonInteractive --applicationName "{app}" &\n')
            f.write(f"    sleep 5  # Wait for the application to start\n")
            f.write(f"    wmctrl -r 'VMware Horizon Client' -b add,hidden\n")
            f.write(f"    wait $!\n")
            f.write(f"done &\n")
        messagebox.showinfo("Success", "Autostart file saved successfully!")
    except Exception as e:
        messagebox.showerror("Error", f"Failed to save autostart file: {e}")

# Tkinter window setup
root = tk.Tk()
root.title("Linux Horizon Client Configurator By AYNFT")

# Load the current values from the autostart file if it exists
config = load_autostart_file()

# Tkinter Labels and Entry fields for each parameter
tk.Label(root, text="Server URL:").grid(row=0, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Username:").grid(row=1, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Password:").grid(row=2, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Domain Name:").grid(row=3, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Application Name:").grid(row=4, column=0, padx=10, pady=5, sticky='e')

# Text fields for input
server_entry = tk.Entry(root, width=50)
ebiuser_entry = tk.Entry(root, width=50)
ebipass_entry = tk.Entry(root, show="*", width=50)  # Hide password
domain_entry = tk.Entry(root, width=50)
app_entry = tk.Entry(root, width=50)

# Pre-fill the entry fields with the current config values
if config:
    server_entry.insert(0, config.get('server', ''))
    ebiuser_entry.insert(0, config.get('ebiuser', ''))
    ebipass_entry.insert(0, config.get('ebipass', ''))
    domain_entry.insert(0, config.get('domain', ''))
    app_entry.insert(0, config.get('app', ''))

# Layout the entry fields
server_entry.grid(row=0, column=1, padx=10, pady=5)
ebiuser_entry.grid(row=1, column=1, padx=10, pady=5)
ebipass_entry.grid(row=2, column=1, padx=10, pady=5)
domain_entry.grid(row=3, column=1, padx=10, pady=5)
app_entry.grid(row=4, column=1, padx=10, pady=5)

# Save button function to write to autostart file
def on_save():
    server = server_entry.get()
    ebiuser = ebiuser_entry.get()
    ebipass = ebipass_entry.get()
    domain = domain_entry.get()
    app = app_entry.get()

    # Save the updated configuration to the autostart file
    save_autostart_file(server, ebiuser, ebipass, domain, app)

# Save Button
save_button = tk.Button(root, text="Save", command=on_save)
save_button.grid(row=5, column=1, pady=20)

root.mainloop()
