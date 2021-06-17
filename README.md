# Website from scratch

Create and deploy a Django website with a pretty domain name and https.
* Django (Python framework)
* Nginx (a reverse proxy server)
* Gunicorn (Python server)
* SQLite
* AWS EC2 (virtual private machine)
* Google Domains (where you will buy your domain name)

## Before we begin

* Unfortunately you can't just copy paste everything. I tried to make it that way as much as possible
  * You will see the fake ip address of 101.42.69.777, you have to replace it with the ip address of the EC2 instance you create
  * You will see www.example.com, you have to replace it with the domain name that you purchase on Google Domains
  * You will see "AWS_EC2_key.pem" which is the name of my AWS key. If you named your key something different then go with that
* My personal computer is on Windows 10 Pro. I installed "Windows Subsystem for Linux" and I use that for all bash commands
  
```
# Directory structure (on your local machine where you will develop cool things)
# You can change the name of the folder "whateveryouwant" but I wouldn't rename/move anything else
# For example, do not change the name of "myproject" to "bobsmithsite" or "twitterclone"
# Of course you can and should create brand new folders/apps using "django-admin startapp twitterclone"

whateveryouwant/            # This is the only folder you can name whatever you want and is on your local machine but not on the EC2
    myproject/              # The is the root folder of this repository. This folder is on the EC2 and should keep the name myproject
        myapp/              # Folder for your Django app, this is the Django folder itself
            mysite/         # Houses the hello world template
        venv/               # Folder for the virtual environment
        config_files/       # Folder for Apache config files
        .git/               # Folder for Git
        .gitignore          # File that tells Git what to ignore
        requirements.txt    # Python dependencies, for example Django REST framework
        README.md           # The file that generates these instructions
```

## Major steps

* Create an AWS EC2 instance

* Gather Django files

* Set up virtual environment and install dependencies

* Set up web server

* Add a domain name

* Make it https

* Develop website

Got it? Let's begin!

# Create an AWS EC2 instance
* Create a new account on AWS (Amazon Web Services) 

* Click "Launch a virtual machine (With EC2)", you may have to search for this service if it's not on the home page

* Configure it as follows:
  * Select "Ubuntu Server 20.04 LTS (HVM), SSD Volume Type", you may have to search for it
  * Select "t2.medium"
  * Click "Next: Configure Instance Details" and don't make any changes
  * Click "Next: Add Storage" and don't make any changes
  * Click "Next: Add Tags" and don't make any changes
  * Click "Next: Configure Security Group"
  * Click "Add Rule" and from the drop down menu select HTTP
  * Click "Add Rule" and from the drop down menu select HTTPS
  * Click "Review and Launch"
  * Click "Launch"

* SSH into your AWS EC2 instance and let's install some stuff
```
# Get into your EC2
ssh -i ~/.ssh/AWS_EC2_key.pem ubuntu@101.42.69.777         # Replace with your key name and your EC2 ip address

# Let's install some important stuff
sudo apt-get update && sudo apt-get upgrade -y             # The -y flag makes it so you hit yes for questions like "After this operation, 43.0 kB of additional disk space..."
sudo apt install python3 -y                                # Install python3
sudo apt install python3-pip -y                            # Install pip3
sudo apt install python3-venv -y                           # So we can create a virtual environment
sudo apt install nginx -y                                  # Install nginx

# Same commands, all on one line
sudo apt-get update && sudo apt-get upgrade -y && sudo apt install python3 -y && sudo apt install python3-pip -y && sudo apt install python3-venv -y && sudo apt install nginx -y
```

# Gather Django files

* First let's get your Github SSH key to the EC2. From your local computer

```scp -i ~/.ssh/AWS_EC2_key.pem ~/.ssh/id_rsa ubuntu@101.42.69.777:/home/ubuntu/.ssh/```

* From the EC2, run the following commands
```
cd ~                                                       # Should take you to /home/ubuntu
git clone git@github.com:hongjinn/myproject-django-gunicorn-nginx.git

# It's important that you rename the folder to myproject as the config files assume that!
mv myproject-django-gunicorn-nginx myproject
```

* Now we have the template for your new site. But we have to do a few adjustments 
  * Edit the "settings.py" file with ```nano ~/myproject/myapp/myapp/settings.py```
  * Make the line with "ALLOWED_HOSTS" look like this...
  * ```ALLOWED_HOSTS = ['localhost','101.42.69.777','www.example.com]```
  * Put in your EC2 ip and the name of the site you plan to buy on Google Domains

* Next we also need to delete the Git folder so you can create a new repository ```cd ~/myproject && rm -rf .git```

# Set up virtual environment and install dependencies

* Now lets create a virtual environment folder on your EC2. We also need to install stuff like Django and Gunicorn
```
# From your EC2
python3 -m venv /home/ubuntu/myproject/venv                   # Create your virtual environment
source /home/ubuntu/myproject/venv/bin/activate               # Activate your virtual environment
pip3 install -r /home/ubuntu/myproject/requirements.txt       # This installs all your dependencies
python3 /home/ubuntu/myproject/myapp/manage.py collectstatic  # Collect static files, this creates a folder for Nginx to use and serve

# Same commands, all one one line
python3 -m venv /home/ubuntu/myproject/venv && source /home/ubuntu/myproject/venv/bin/activate && pip3 install -r /home/ubuntu/myproject/requirements.txt && python3 /home/ubuntu/myproject/myapp/manage.py collectstatic
```

# Set up web server

* Edit the nginx configuration file ```nano /home/ubuntu/myproject/config_files/myproject_nginx```
  * Replace this line with your EC2 ip address and the domain name you're going to buy
  * ```server_name 101.42.69.777 example.com www.example.com;```

* Now move the file to the right folder with ```sudo cp /home/ubuntu/myproject/config_files/myproject_nginx /etc/nginx/sites-available/```

* Now we'll create a symlink to this file from another folder. Run the following commands: ```cd /etc/nginx/sites-enabled && sudo ln -s /etc/nginx/sites-available/myproject_nginx```

* You can see the symlink by doing this command from the sites-enabled folder ```ls -l```

* Now run Nginx server with ```sudo systemctl restart nginx```

* Now run the Gunicorn server with ```gunicorn -c /home/ubuntu/myproject/config_files/gunicorn_config.py myapp.wsgi```
  * To run the process in the background, do Ctrl+z then input the command ```bg```
  * To stop Gunicorn do ```fg``` then Ctrl+c

* Now open your web browser and navigate to your EC2 ip address ```http://101.42.69.777```

* You can check Nginx error logs with ```cat /var/log/nginx/error.log```

# Add a domain name

* Buy a domain name on Google Domains, for example www.example.com
  * In mid 2020 it was $12 a year
  
* Once you've purchased it... go to https://domains.google.com/m/registrar 
  * Click on My domains
  * Find your domain and click on it
  * In the left hand pane, click on "DNS"

* Scroll down to the bottom where it says "Custom resource records"
  * You want to add two rows that ultimately look like below
  * Do this by filling out the fields and hitting "Add"
```
@       A       1h     101.42.69.777
www     CNAME   1h     example.com.
```

* Wait a few hours for this to catch on. Note: if you had previously paired this domain name with another ip address you might have to flush the dns cache on your browser. Otherwise when you navigate to example.com you won't see your new page 
  * You can go to https://dnschecker.org/ and plug in your website name "www.example.com" to check if the association has been made yet between your EC2 ip and your site name

# Make it https

* Resources: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-20-04

* SSH into your server ```ssh -i ~/.ssh/AWS_EC2_key.pem ubuntu@101.42.69.777```

```
sudo apt install certbot python3-certbot-nginx -y               # Fortunately making it https has been automated for Nginx, let's use Certbot
sudo certbot --nginx -d example.com -d www.example.com          # -d=domain

# Fill in your email address
# Agree to the terms of service
# Share your email if you want to (not necessary)
# Choose option 2 to redirect http traffic to https
```

* Congratulations you are done. Open your browser and go to your site, https://wwww.example.com

* (Optional) Setting up HSTS
  * You can check if HSTS is enabled with the command ```curl -s -D- https://www.example.com | grep -i Strict```
  * If it's not enabled then there will be no output
  * From your EC2 ```sudo vim /etc/nginx/sites-available/myproject_nginx```
  * Then after the line ```listen 443 ssl; # managed by Certbot``` add the following line
  * ```add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";```

* Let’s Encrypt’s certificates are only valid for ninety days, but the good news is the renewal is automated
  * To check if the renewal is automated ```sudo systemctl status certbot.timer```
  * You can do a dry run ```sudo certbot renew --dry-run``` and if you get no errors you're good to go
  * If the automated renewal process ever fails, Let’s Encrypt will send a message to the email you specified!

# Commands to restart Nginx and Gunicorn

* ```sudo systemctl restart nginx```

* Check if Gunicorn is running ```ps -aux | grep gunicorn```

* Kill Gunicorn processes ```pkill gunicorn```

# Additional deployment steps

* You need to change your Django SECRET_KEY which you can find in myproject/myapp/myapp/settings.py
  * While you're in settings.py you're supposed to set DEBUG = False for security purposes. If you set it to True then you get tons of useful information when your site has a problem. But this could give too much information to those with malicious intentions
```
# From your EC2, start Python
python3

# Import the random Django key creator
from django.core.management.utils import get_random_secret_key

# Copy the output of this new secret key 
get_random_secret_key()

# Edit the line SECRET_KEY in this file with the one you just created
nano /home/ubuntu/myproject/myapp/myapp/settings.py
# In addition, for deployment you should set DEBUG = False in settings.py
```

* This is a helpful command for checking if you're deployment ready ```python /home/ubuntu/myproject/myapp/manage.py check --deploy```

## Other development notes
* It's not very unique but I like using the Starter Template found here: https://getbootstrap.com/docs/4.3/getting-started/introduction/

* It's good practice to use template extensions: https://docs.djangoproject.com/en/3.0/ref/templates/language/

# PostgreSQL on the EC2 itself

```
sudo apt-get install postgresql
sudo apt-get install python-psycopg2                     # This will be used with Django
sudo apt-get install libpq-dev

sudo passwd postgres                                     # Set a password for the server "postgres" that's on your EC2
sudo service postgresql start

su - postgres
createuser --interactive --pwprompt
# User is "ubuntu"

createdb mydb

# Let's check this worked
psql
\du          # Display users
\dt          # Display tables
>\q          # Exit psql, the PostgreSQL interactive terminal program
>exit        # Exit postgres server
```

* Activate your venv and do ```pip install psycopg2```

* Now update settings.py file
```
DATABASES = { 'default': {
  'ENGINE': 'django.db.backends.postgresql_psycopg2',
  'NAME': 'mydb',
  'USER': 'ubuntu',
  'PASSWORD': '<password>',
  'HOST': 'localhost',
  'PORT': '5432',
  }
}
```

* Now do your migrations ```python manage.py makemigrations``` and ```python manage.py migrate```

* Restart server with ```sudo service apache2 restart```

* You can now see your data in Postgresql with
```
psql mydb
select * from <your_model>;
\dt
```
