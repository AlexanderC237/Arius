web: env/bin/gunicorn --chdir $APP_HOME/Arius -c Arius/gunicorn.conf.py Arius.wsgi -b 0.0.0.0:$PORT
worker: env/bin/python Arius/manage.py qcluster
cli: . env/bin/activate && exec env/bin/python -m invoke
