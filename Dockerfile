FROM ubuntu:18.04

MAINTAINER Dockerfiles

# Install required packages and remove the apt packages cache when done.

RUN apt-get update && \
    apt-get install -y && \
    apt-get install python3.7 -y && \
    apt-get install python3-pip -y && \
    apt-get install virtualenv -y && \
    apt-get install apache2 -y && \
    apt-get install libapache2-mod-wsgi-py3 -y && \
    apt-get install git -y && \
    apt-get install nano -y

RUN pip3 install --upgrade virtualenv 

COPY . /home/ubuntu/myproject/

RUN virtualenv -p python3 /home/ubuntu/myproject/venv

RUN pip3 install -r /home/ubuntu/myproject/requirements.txt

RUN python3 /home/ubuntu/myproject/myapp/manage.py collectstatic

RUN scp /home/ubuntu/myproject/django_project.conf /etc/apache2/sites-available/

RUN a2ensite django_project

RUN a2dissite 000-default.conf

RUN chown :www-data /home/ubuntu/myproject/myapp/db.sqlite3

RUN chmod 664 /home/ubuntu/myproject/myapp/db.sqlite3

RUN chown :www-data /home/ubuntu/myproject/myapp/

RUN chown -R :www-data /home/ubuntu/myproject/myapp/media/

RUN chmod -R 775 /home/ubuntu/myproject/myapp/media

EXPOSE 80
EXPOSE 8000

CMD ["service","apache2","restart"]


# Other Notes
# 1.
# Regarding this error: "delaying package configuration, since apt-utils is not installed"
# According to this answer you can ignore it
# https://stackoverflow.com/questions/51023312/docker-having-issues-installing-apt-utils


# docker run --hostname=django-server -t -dp 8000:8000 --name i1 myprojectlauncher