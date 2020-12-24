# Configuration file for Gunicorn

# Specify executable for Gunicorn
command = "/home/ubuntu/venv/bin/gunicorn"

# Path for my project
pythonpath = "/home/ubuntu/myproject/myapp/"

# Where Gunicorn will talk to Nginx
bind = "127.0.0.1:8000"

# They recommend (2 x $num_cores) + 1
workers = 3
