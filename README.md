# Website from scratch

Create and deploy a Django website with a pretty domain name and https.

* Django (Python framework)
* Apache2 (web server)
* mod_wsgi (let's Apache interface with Python)
* SQLite (database)
* AWS EC2 (virtual private machine)
* Google Domains (where you will buy your domain name)

## Strategy of this guide

You could develop a fully functional site on your computer and then get it on the web. But let's get on the web first with a simple "hello world" page. Once that's done you can create whatever you want. Why? To remove the anxiety of deployment. No point in creating a beautiful website that only works on your local machine.

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
        venv/               # Folder for the virtual environment that is needed for Apache/mod_wsgi
        config_files/       # Folder for Apache config files
        .git/               # Folder for Git
        .gitignore          # File that tells Git what to ignore
        requirements.txt    # Python dependencies, for example Django REST framework
        README.md           # The file that generates these instructions
        Dockerfile          # Incomplete... more to come
```

## Major steps

* Create an AWS EC2 instance

* Gather Django files

* Set up web server

* Add a domain name

* Make it https

* Develop website

Got it? Let's begin!

# Create an AWS EC2 instance
* Create a new account on AWS (Amazon Web Services) 

* Click "Launch a virtual machine (With EC2)", you may have to search for this service if it's not on the home page

* Configure it as follows:
  * Select "Ubuntu Server 18.04 LTS (HVM), SSD Volume Type", you may have to search for it
  * Select "t2.micro" because it's free
  * Click "Next: Configure Instance Details" and don't make any changes
  * Click "Next: Add Storage" and don't make any changes
  * Click "Next: Add Tags" and don't make any changes
  * Click "Next: Configure Security Group"
  * Click "Add Rule" and from the drop down menu select HTTP
  * Click "Add Rule" and from the drop down menu select HTTPS
  * Click "Review and Launch"
  * Click "Launch"

* Create a new key pair (if you already have an existing key pair skip to the next step)
  * Add a key pair name, for example: AWS_EC2_key
  * Click "Download Key Pair"
  * Click "Launch Instances"
  * Now let's set up our SSH keys. From the bash terminal...
```
# Go to where you key pair was downloaded, for example
cd '/mnt/c/Users/Hongjinn Park/Downloads'

# Create a new folder to house your ssh keys if it doesn't already exist
mkdir ~/.ssh

cp AWS_EC2_key.pem ~/.ssh/AWS_EC2_key.pem                  # Copy the ssh key into the folder ~/.ssh
sudo chmod 400 ~/.ssh/AWS_EC2_key.pem                      # Change security to make AWS happy (400 is read only)

# Same commands, all on one line
cd '/mnt/c/Users/Hongjinn Park/Downloads' && cp AWS_EC2_key.pem ~/.ssh/AWS_EC2_key.pem && sudo chmod 400 ~/.ssh/AWS_EC2_key.pem
```

* If you have an existing key pair
  * Select the right key pair, mine is "AWS_EC2_key"
  * Check the "I acknowledge" box
  * Click "Launch Instances"

* Click "View Instances"
  * In the "Name" column enter whatever you want, for instance "example.com" and note that you can change this field later
  * At the bottom in the "Description" tab, find your IPv4 Public IP. You will use this multiple times throughout this guide. Let's say mine is 101.69.42.777

* SSH into your AWS EC2 instance and let's install some stuff
```
# Get into your EC2
ssh -i ~/.ssh/AWS_EC2_key.pem ubuntu@101.42.69.777         # Replace with your key name and your EC2 ip address

# Let's install some important stuff
sudo apt-get update && sudo apt-get upgrade -y             # The -y flag makes it so you hit yes for questions like "After this operation, 43.0 kB of additional disk space..."
sudo apt install python3.7 -y                              # Install python3.7
sudo apt install python3-pip -y                            # Install pip3
sudo apt install virtualenv -y                             # Install virtual environment
sudo apt-get install apache2 -y                            # Install our web server
sudo apt-get install libapache2-mod-wsgi-py3 -y            # Install mod_wsgi which is how Apache talks to Django
sudo hostnamectl set-hostname django-server                # Set the host name to "django server"

# Same commands, all on one line
sudo apt-get update && sudo apt-get upgrade -y && sudo apt install python3.7 -y && sudo apt install python3-pip -y && sudo apt install virtualenv -y && sudo apt-get install apache2 -y && sudo apt-get install libapache2-mod-wsgi-py3 -y && sudo hostnamectl set-hostname django-server
```

* Now we have to add a new line to the file /etc/hosts
  * Edit the file by doing ```sudo nano /etc/hosts```
  * Note that after doing edits with nano you can save your changes and exit by doing Ctrl+X and typing "y"
  * Make the file look like this (below). Use your EC2 ip address. Do not change the name from "django-server"
```
127.0.0.1 localhost
101.42.69.777 django-server

# The following lines are desirable for...
```

# Gather Django files

* We need two terminals open, one for your local machine and another for the EC2

* Let's say you want your local development folder to be on your Desktop. The process will be this: develop on your local computer (ie add a "Contact Me" page) then push changes to your EC2 to see live on the web
  * Go to your Desktop and create a new folder, you can call this anything you want. For instance "exampledotcom" by doing ```mkdir '/mnt/c/Users/Hongjinn Park/Desktop/exampledotcom'```
  * Navigate into the new folder you just created with ```cd !$```
  * Get the files needed for your hello world template site by doing ```git clone git@github.com:hongjinn/myproject.git```

* Now we have the template for your new site. But we have to do a few adjustments 
  * Edit the "settings.py" file with ```nano myproject/myapp/myapp/settings.py```
  * Make the line with "ALLOWED_HOSTS" look like this...
  * ```ALLOWED_HOSTS = ['localhost','101.42.69.777','www.example.com]```
  * Put in your EC2 ip and the name of the site you plan to buy on Google Domains

* Next we also need to delete the Git folder and create a brand new one. You don't want to change this repository which holds a generic template. You are creating a new repository for your personal project
```
rm -rf .git                     # Delete the folder .git which is in the exampledotcom/myproject folder
git init                        # Do this command while in the exampledotcom/myproject folder
git add -A                      # Adds all files to be committed
git commit -m "first commit"    # Commit with the message "first commit"

# Now go on GitHub and create a new repository. Call it exampledotcom
git remote add origin git@github.com:hongjinn/exampledotcom.git           # Connect your development folder to GitHub
git push -u origin master                                                 # Push your changes to GitHub
```

* Now we have to copy our Django site to AWS EC2
  * We just want to copy the "myproject" folder to EC2
  * If you are not already there, do ```cd '/mnt/c/Users/Hongjinn Park/Desktop/exampledotcom'```
  * Now do ```scp -i ~/.ssh/AWS_EC2_key.pem -r myproject ubuntu@101.42.69.777:/home/ubuntu/```
  * Now our AWS EC2 should have all the project files

# Set up web server

* Now lets create a virtual environment folder on your EC2. This is critical as mod_wsgi will point to it
```
# From your EC2
pip3 install --upgrade virtualenv                             # Upgrade your virtual environment
virtualenv -p python3 /home/ubuntu/myproject/venv             # Create your virtual environment
source /home/ubuntu/myproject/venv/bin/activate               # Activate your virtual environment
pip3 install -r /home/ubuntu/myproject/requirements.txt       # This installs all your dependencies
python3 /home/ubuntu/myproject/myapp/manage.py collectstatic  # Collect static files

# Same commands, all one one line
pip3 install --upgrade virtualenv && virtualenv -p python3 /home/ubuntu/myproject/venv && source /home/ubuntu/myproject/venv/bin/activate && pip3 install -r /home/ubuntu/myproject/requirements.txt && python3 /home/ubuntu/myproject/myapp/manage.py collectstatic
```

* Now let's get Apache and wsgi configured
```
# Copy Apache config file
sudo scp /home/ubuntu/myproject/config_files/django_project.conf /etc/apache2/sites-available/
sudo a2ensite django_project                                  # Enables the config file we just copied
sudo a2dissite 000-default.conf                               # Disables the default config file

# Give Apache access to the correct files
sudo chown :www-data /home/ubuntu/myproject/myapp/db.sqlite3  # Give ownership to Apache2 who is www-data
sudo chmod 664 /home/ubuntu/myproject/myapp/db.sqlite3        # Change permissions on DB
sudo chown :www-data /home/ubuntu/myproject/myapp/            # Give it ownership to the whole folder
sudo chown -R :www-data /home/ubuntu/myproject/myapp/media/   # Media folder is what users upload, for example a profile pic
sudo chmod -R 775 /home/ubuntu/myproject/myapp/media          # Change permission level

# Now start the Apache server
sudo service apache2 restart                                  # After this we're live

# Same commands, all on one line
sudo scp /home/ubuntu/myproject/config_files/django_project.conf /etc/apache2/sites-available/ && sudo a2ensite django_project && sudo a2dissite 000-default.conf && sudo chown :www-data /home/ubuntu/myproject/myapp/db.sqlite3 && sudo chmod 664 /home/ubuntu/myproject/myapp/db.sqlite3 && sudo chown :www-data /home/ubuntu/myproject/myapp/ && sudo chown -R :www-data /home/ubuntu/myproject/myapp/media/ && sudo chmod -R 775 /home/ubuntu/myproject/myapp/media && sudo service apache2 restart
```

* Now go to 101.42.69.777 in your browser and you should see the site!

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
@       A       1h     52.53.181.54
www     CNAME   1h     example.com.
```

* Wait a few hours for this to catch on. Note: if you had previously paired this domain name with another ip address you might have to flush the dns cache on your browser. Otherwise when you navigate to example.com you won't see your new page 

# Make it https

* Resources: https://certbot.eff.org/lets-encrypt/ubuntubionic-apache

* SSH into your server ```ssh -i ~/.ssh/AWS_EC2_key.pem ubuntu@101.42.69.777```

```
# From your EC2, copy paste this all as one command
sudo apt-get update -y && sudo apt-get install software-properties-common -y && \
sudo add-apt-repository universe -y && sudo add-apt-repository ppa:certbot/certbot -y && \
sudo apt-get update -y && sudo apt-get install certbot python3-certbot-apache -y
```

* Update the django_project.conf file with this command
```
sudo cp /home/ubuntu/myproject/config_files/django_project_https_redirect.conf /etc/apache2/sites-available/django_project.conf
```

* Modify the config file with the domain name you purchased and your email
  * ```sudo nano /etc/apache2/sites-available/django_project.conf```
  * Update "ServerName" from www.example.com to the website you purchased on Google Domains
  * Update "ServerAdmin webmaster@localhost" to myemail@gmail.com

* Now run certbot with  ```sudo certbot --apache```
  * Fill in your email address
  * Agree to the terms of service
  * Share your email if you want to (not necessary)
  * Activate https for the domain name you bought (should be option 1)
  * Choose option 2 to redirect http traffic to https
  
* Now go back here to the original config file ```sudo nano /etc/apache2/sites-available/django_project.conf```
  * Delete lines on the bottom portion and comment out the lines that start with "Rewrite". Make it look like this
```
    #Include conf-available/serve-cgi-bin.conf
 
Redirect permanent / https://www.example.com

#RewriteEngine on
#RewriteCond %{SERVER_NAME} =www.example.com
#RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>  
```

* Now edit https config file ```sudo nano /etc/apache2/sites-available/django_project-le-ssl.conf```
  * Uncomment the WSGI lines so they are active

* Restart server with ```sudo service apache2 restart```
  * Go to your site. Now you have https!

* Let's automate SSL certificate renewal (for https)
  * ```sudo crontab -e```
  * Choose 1 for nano
  * Add to the bottom of the file...
```
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
30 4 1 * * sudo certbot renew --quiet
```

* Now it will run the renew command every month at 4:30 am on the 1st

* You are on the web as https!

* (Optional) If you want to disable TLSv1.0 and TLSv1.1 then you can do the following commands. This could interfere with your automated SSL certificate renewal
```
sudo nano /etc/letsencrypt/options-ssl-apache.conf         # Modify this file

# Look for this part
SSLProtocol             all -SSLv2 -SSLv3

# And make it
SSLProtocol             -all +TLSv1.2 +TLSv1.3
```

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

# Develop website

So how will you update your live production site? You will have two sets of files. One on your local machine to do development and another on your EC2 for production. The process flow is this: develop on your local machine (ie add a "Contact Me" page) then update the files on your EC2 with a ```git pull```

* Create a virtual environment on your local machine
```
# From your local machine, from the myproject folder, you should see the file requriements.txt
sudo apt install virtualenv -y         # Install virtual environment on your local machine
pip3 install --upgrade virtualenv      # Upgrade your virtual environment
virtualenv -p python3 venv             # Create your virtual environment
source venv/bin/activate               # Activate your virtual environment
pip3 install -r requirements.txt       # This installs all your dependencies
```

* To see your site on your local machine, do ```python manage.py runserver```
  * Go to your browser and type in the url localhost:8000 or http://127.0.0.1:8000

* Create a superuser ```python manage.py createsuperuser```
  * Fill out the details
  * Go to your site and add "/admin" to the url. For example www.example.com/admin or "localhost:8000/admin"
  * Log in with the super user account you created

* Now you can start developing your site

* To update your production server
  * ```git push``` to your EC2
  * Now from your EC2, do ```git pull && sudo service apache2 restart```
  * Your site should now be updated

## Other development notes

* It's not very unique but I like using the Starter Template found here: https://getbootstrap.com/docs/4.3/getting-started/introduction/

* It's good practice to use template extensions: https://docs.djangoproject.com/en/3.0/ref/templates/language/
---

# Troubleshooting

* Production site can't access your database which can happen if your database is a flat file and you make changes on your local computer and do ```git push``` to your remote repository (GitHub) and then ```git pull``` on your EC2 
```
ls -la /home/ubuntu/myproject/myapp   # For db.sqlite3 it is supposed to be "-rw-rw-rw-r-- ubuntu www-data"
sudo chown :www-data db.sqlite3       # "www-data" which is Apache should have group ownership of db.sqlite3
sudo chmod 664 db.sqlite3             # 664 (owner can read/write, apache can read/write, others can read only)
```

* See what ports are being listened to (ie 80,22,443,53) with ```netstat -ant```

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
